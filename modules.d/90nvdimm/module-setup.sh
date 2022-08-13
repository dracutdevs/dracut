#!/bin/sh

# called by dracut
check() {
    [ -z "$hostonly" ] && return 0
    [ -n "$DRACUT_KERNEL_MODALIASES" ] && [ -f "$DRACUT_KERNEL_MODALIASES" ] \
        && grep -q libnvdimm "$DRACUT_KERNEL_MODALIASES" && return 0
    return 255
}

# called by dracut
depends() {
    return 0
}

# called by dracut
installkernel() {
    # Directories to search for NVDIMM "providers" (firmware drivers)
    # These modules call "nvdimm_bus_register()".
    #instmods() will take care of hostonly
    dracut_instmods -o -s nvdimm_bus_register \
        '=drivers/nvdimm' \
        '=drivers/acpi' \
        '=arch/powerpc'
}

# called by dracut
install() {
    inst_multiple -o ndctl /etc/ndctl/keys/tpm.handle "/etc/ndctl/keys/*.blob"
}
