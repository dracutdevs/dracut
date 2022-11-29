#!/bin/sh

# Licensed under the GPLv2
#
# Copyright (C) 2011 Politecnico di Torino, Italy
#                    TORSEC group -- http://security.polito.it
# Roberto Sassu <roberto.sassu@polito.it>

EVMSECFILE="${SECURITYFSDIR}/evm"
EVMCONFIG="${NEWROOT}/etc/sysconfig/evm"
EVMKEYDESC="evm-key"
EVMKEYTYPE="encrypted"
EVMKEYID=""
EVM_ACTIVATION_BITS=0

# The following variables can be set in /etc/sysconfig/evm:
# EVMKEY: path to the symmetric key; defaults to /etc/keys/evm-trusted.blob
# EVMKEYDESC: Description of the symmetric key; default is 'evm-key'
# EVMKEYTYPE: Type of the symmetric key; default is 'encrypted'
# EVMX509: path to x509 cert; default is /etc/keys/x509_evm.der
# EVM_ACTIVATION_BITS: additional EVM activation bits, such as
#                      EVM_SETUP_COMPLETE; default is 0
# EVMKEYSDIR: Directory with more x509 certs; default is /etc/keys/evm/

load_evm_key() {
    # read the configuration from the config file
    # shellcheck disable=SC1090
    [ -f "${EVMCONFIG}" ] \
        && . "${EVMCONFIG}"

    # override the EVM key path name from the 'evmkey=' parameter in the kernel
    # command line
    if EVMKEYARG=$(getarg evmkey=); then
        EVMKEY=${EVMKEYARG}
    fi

    # set the default value
    [ -z "${EVMKEY}" ] \
        && EVMKEY="/etc/keys/evm-trusted.blob"

    # set the EVM key path name
    EVMKEYPATH="${NEWROOT}${EVMKEY}"

    # check for EVM encrypted key's existence
    if [ ! -f "${EVMKEYPATH}" ]; then
        if [ "${RD_DEBUG}" = "yes" ]; then
            info "integrity: EVM encrypted key file not found: ${EVMKEYPATH}"
        fi
        return 1
    fi

    # read the EVM encrypted key blob
    read -r KEYBLOB < "${EVMKEYPATH}"

    # load the EVM encrypted key
    if ! EVMKEYID=$(keyctl add ${EVMKEYTYPE} ${EVMKEYDESC} "load ${KEYBLOB}" @u); then
        info "integrity: failed to load the EVM encrypted key: ${EVMKEYDESC}"
        return 1
    fi
    return 0
}

load_evm_x509() {
    info "Load EVM IMA X509"

    # override the EVM key path name from the 'evmx509=' parameter in
    # the kernel command line
    if EVMX509ARG=$(getarg evmx509=); then
        EVMX509=${EVMX509ARG}
    fi

    # set the default value
    [ -z "${EVMX509}" ] \
        && EVMX509="/etc/keys/x509_evm.der"

    # set the EVM public key path name
    EVMX509PATH="${NEWROOT}${EVMX509}"

    # check for EVM public key's existence
    if [ ! -f "${EVMX509PATH}" ]; then
        EVMX509PATH=""
    fi

    local evm_pubid line
    if line=$(keyctl describe %keyring:.evm); then
        # the kernel already setup a trusted .evm keyring so use that one
        evm_pubid=${line%%:*}
    else
        # look for an existing regular keyring
        evm_pubid=$(keyctl search @u keyring _evm)
        if [ -z "${evm_pubid}" ]; then
            # create a new regular _evm keyring
            evm_pubid=$(keyctl newring _evm @u)
        fi
    fi

    if [ -z "${EVMKEYSDIR}" ]; then
        EVMKEYSDIR="/etc/keys/evm"
    fi
    # load the default EVM public key onto the EVM keyring along
    # with all the other ones in $EVMKEYSDIR
    local key_imported=1
    for PUBKEY in ${EVMX509PATH} "${NEWROOT}${EVMKEYSDIR}"/*; do
        if [ ! -f "${PUBKEY}" ]; then
            if [ "${RD_DEBUG}" = "yes" ]; then
                info "integrity: EVM x509 cert file not found: ${PUBKEY}"
            fi
            continue
        fi
        if ! evmctl import "${PUBKEY}" "${evm_pubid}"; then
            info "integrity: failed to load the EVM X509 cert ${PUBKEY}"
            return 1
        fi
        key_imported=0
    done

    if [ "${RD_DEBUG}" = "yes" ]; then
        keyctl show @u
    fi

    return ${key_imported}
}

unload_evm_key() {
    # unlink the EVM encrypted key
    keyctl unlink "${EVMKEYID}" @u || {
        info "integrity: failed to unlink the EVM encrypted key: ${EVMKEYDESC}"
        return 1
    }

    return 0
}

enable_evm() {
    # check kernel support for EVM
    if [ ! -e "${EVMSECFILE}" ]; then
        if [ "${RD_DEBUG}" = "yes" ]; then
            info "integrity: EVM kernel support is disabled"
        fi
        return 0
    fi

    local evm_configured=0
    local EVM_INIT_HMAC=1 EVM_INIT_X509=2

    # try to load the EVM encrypted key
    load_evm_key && evm_configured=${EVM_INIT_HMAC}

    # try to load the EVM public key
    load_evm_x509 && evm_configured=$((evm_configured | EVM_INIT_X509))

    # only enable EVM if a key or x509 certificate could be loaded
    if [ $evm_configured -eq 0 ]; then
        return 1
    fi

    # initialize EVM
    info "Enabling EVM"
    echo $((evm_configured | EVM_ACTIVATION_BITS)) > "${EVMSECFILE}"

    if [ "$((evm_configured & EVM_INIT_HMAC))" -ne 0 ]; then
        # unload the EVM encrypted key
        unload_evm_key || return 1
    fi

    return 0
}

enable_evm
