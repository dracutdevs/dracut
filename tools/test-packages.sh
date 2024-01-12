#!/bin/sh

if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
fi

# common packages
cat << EOF
    asciidoc
    astyle
    bash-completion
    bluez
    busybox
    bzip2
    cifs-utils
    cryptsetup
    dash
    dmraid
    f2fs-tools
    fuse3
    gawk
    gcc
    git
    jq
    kbd
    lvm2
    lzop
    make
    mdadm
    ndctl
    ntfs-3g
    nvme-cli
    parted
    pigz
    rng-tools
    shfmt
    strace
    sudo
    tar
    tcpdump
    vim
    wget
    which
EOF

# common packages (but not openSUSE)
if [ -x /usr/bin/yum ] || [ -x /usr/bin/dpkg ] || [ -x /usr/bin/pacman ]; then
    cat << EOF
    btrfs-progs
    squashfs-tools
    tpm2-tools
EOF
fi

# packages for rpm based distros
if [ -x /usr/bin/rpm ]; then
    cat << EOF
    dhcp-client
    dhcp-server
    e2fsprogs
    iproute
    iputils
    kernel
    nbd
    NetworkManager
    nfs-utils
    ntfsprogs
    rpm-build
    ShellCheck
    xz
EOF
fi

if [ -x /usr/bin/yum ] || [ -x /usr/bin/pacman ]; then
    cat << EOF
    biosdevname
    memstrack
    nfs-utils
    sbsigntools
EOF
fi

if [ -x /usr/bin/yum ]; then
    cat << EOF
    dbus-daemon
    device-mapper-multipath
    fcoe-utils
    iscsi-initiator-utils
    kmod-devel
    libkcapi-hmaccalc
    libselinux-utils
    mksh
    pcsc-lite
    qemu-system-x86-core
    scsi-target-utils
    systemd-boot-unsigned
    systemd-networkd
    systemd-resolved
EOF
fi

if [ "$ID" = "opensuse-tumbleweed" ]; then
    cat << EOF
    btrfsprogs
    dbus-broker
    iscsiuio
    libkmod-devel
    multipath-tools
    open-iscsi
    procps
    qemu-kvm
    squashfs
    systemd-boot
    tgt
    /usr/bin/qemu-system-$(uname -m)
    util-linux-systemd
EOF
fi

if [ -x /usr/bin/pacman ]; then
    cat << EOF
    connman
    cpio
    dhclient
    dhcp
    linux
    multipath-tools
    networkmanager
    open-iscsi
    pcsclite
    qemu
    shellcheck
    tgt
EOF
fi

# packages for deb based distro's
if [ -x /usr/bin/dpkg ]; then
    cat << EOF
    ca-certificates
    console-setup
    cpio
    curl
    debhelper
    debhelper-compat
    docbook
    docbook-xml
    docbook-xsl
    fdisk
    iputils-arping
    iputils-ping
    isc-dhcp-client
    isc-dhcp-server
    iscsiuio
    libdmraid-dev
    libkmod-dev
    linux-image-generic
    multipath-tools
    nbd-client
    nbd-server
    network-manager
    nfs-kernel-server
    open-iscsi
    ovmf
    pkg-config
    procps
    qemu-system-x86
    shellcheck
    systemd-boot-efi
    tgt
    thin-provisioning-tools
EOF
fi
