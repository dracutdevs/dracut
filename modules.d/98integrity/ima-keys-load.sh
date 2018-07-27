#!/bin/sh

SECURITYFSDIR="/sys/kernel/security"
IMASECDIR="${SECURITYFSDIR}/ima"
IMACONFIG="${NEWROOT}/etc/sysconfig/ima"

load_x509_keys()
{
    KEYRING_ID=$1

    # override the default configuration
    if [ -f "${IMACONFIG}" ]; then
        . ${IMACONFIG}
    fi

    if [ -z "${IMAKEYSDIR}" ]; then
        IMAKEYSDIR="/etc/keys/ima"
    fi

    PUBKEY_LIST=`ls ${NEWROOT}${IMAKEYSDIR}/*`
    for PUBKEY in ${PUBKEY_LIST}; do
        # check for public key's existence
        if [ ! -f "${PUBKEY}" ]; then
            if [ "${RD_DEBUG}" = "yes" ]; then
                info "integrity: IMA x509 cert file not found: ${PUBKEY}"
            fi
            continue
        fi

        X509ID=$(evmctl import ${PUBKEY} ${KEYRING_ID})
        if [ $? -ne 0 ]; then
            info "integrity: IMA x509 cert not loaded on keyring: ${PUBKEY}"
        fi 
    done

    if [ "${RD_DEBUG}" = "yes" ]; then
        keyctl show  ${KEYRING_ID}
    fi
    return 0
}

ensure_key_loading() {
    # load to the untrusted _ima keyring if the system tried and failed to load to the trusted .ima keyring
    
    # if a keyring is empty, keyctl will print 'keyring is empty'. The below check only returns true if 
    #       1) the .ima keyring exists (in which case, we have already tried to load to it), and
    #       2) the .ima keyring is empty (loading keys failed)
    # piping of stderr to /dev/null hides the keyctl error "Can't find 'keyring:.ima'" if the keyring doesn't exist
    [[ "$(keyctl list %keyring:.ima 2> /dev/null)" != 'keyring is empty' ]] && return 0

    if [ "${RD_DEBUG}" = "yes" ]; then
        info "integrity: failed to load to .ima keyring. Attempting to load to _ima keyring"
    fi

    local _ima_untrusted_id="$(keyctl search @u keyring _ima)"
    if [ -z "${_ima_id}" ]; then
        _ima_untrusted_id="$(keyctl newring _ima @u)"
    fi

    # retry loading keys onto _ima keyring
    load_x509_keys ${_ima_untrusted_id}

    [[ "$(keyctl list %keyring:_ima 2> /dev/null)" == 'keyring is empty' ]] && info "integrity: failed to load to _ima keyring. No IMA keys loaded"
}


# check kernel support for IMA
if [ ! -e "${IMASECDIR}" ]; then
    if [ "${RD_DEBUG}" = "yes" ]; then
        info "integrity: IMA kernel support is disabled"
    fi
    return 0
fi

# get the IMA keyring id
line=$(keyctl describe %keyring:.ima)
if [ $? -eq 0 ]; then
    _ima_id=${line%%:*}
else
    _ima_id=`keyctl search @u keyring _ima`
    if [ -z "${_ima_id}" ]; then
        _ima_id=`keyctl newring _ima @u`
    fi
fi

# load the IMA public key(s)
load_x509_keys ${_ima_id}
ensure_key_loading
