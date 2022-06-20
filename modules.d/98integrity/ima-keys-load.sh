#!/bin/sh

SECURITYFSDIR="/sys/kernel/security"
IMASECDIR="${SECURITYFSDIR}/ima"
IMACONFIG="${NEWROOT}/etc/sysconfig/ima"

load_x509_keys() {
    KEYRING_ID=$1

    # override the default configuration
    if [ -f "${IMACONFIG}" ]; then
        # shellcheck disable=SC1090
        . "${IMACONFIG}"
    fi

    if [ -z "${IMAKEYSDIR}" ]; then
        IMAKEYSDIR="/etc/keys/ima"
    fi

    for PUBKEY in "${NEWROOT}${IMAKEYSDIR}"/*; do
        # check for public key's existence
        if [ ! -f "${PUBKEY}" ]; then
            if [ "${RD_DEBUG}" = "yes" ]; then
                info "integrity: IMA x509 cert file not found: ${PUBKEY}"
            fi
            continue
        fi

        if ! evmctl import "${PUBKEY}" "${KEYRING_ID}"; then
            info "integrity: IMA x509 cert not loaded on keyring: ${PUBKEY}"
        fi
    done

    if [ "${RD_DEBUG}" = "yes" ]; then
        keyctl show "${KEYRING_ID}"
    fi
    return 0
}

# check kernel support for IMA
if [ ! -e "${IMASECDIR}" ]; then
    if [ "${RD_DEBUG}" = "yes" ]; then
        info "integrity: IMA kernel support is disabled"
    fi
    return 0
fi

# get the IMA keyring id

if line=$(keyctl describe %keyring:.ima); then
    _ima_id=${line%%:*}
else
    _ima_id=$(keyctl search @u keyring _ima)
    if [ -z "${_ima_id}" ]; then
        _ima_id=$(keyctl newring _ima @u)
    fi
fi

# load the IMA public key(s)
load_x509_keys "${_ima_id}"
