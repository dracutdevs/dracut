%define dracutlibdir %{_prefix}/lib/dracut
%bcond_without doc

# We ship a .pc file but don't want to have a dep on pkg-config. We
# strip the automatically generated dep here and instead co-own the
# directory.
%global __requires_exclude pkg-config
%define dist_free_release xxx

Name: dracut
Version: xxx
Release: %{dist_free_release}%{?dist}

Summary: Initramfs generator using udev
%if 0%{?fedora} || 0%{?rhel}
Group: System Environment/Base
%endif
%if 0%{?suse_version}
Group: System/Base
%endif

# The entire source code is GPLv2+
# except install/* which is LGPLv2+
License: GPLv2+ and LGPLv2+

URL: https://dracut.wiki.kernel.org/

# Source can be generated by
# http://git.kernel.org/?p=boot/dracut/dracut.git;a=snapshot;h=%%{version};sf=tgz
Source0: http://www.kernel.org/pub/linux/utils/boot/dracut/dracut-%{version}.tar.xz
Source1: https://www.gnu.org/licenses/lgpl-2.1.txt

BuildRequires: bash
BuildRequires: git
BuildRequires: pkgconfig(libkmod) >= 23
BuildRequires: gcc

%if 0%{?fedora} || 0%{?rhel}
BuildRequires: pkgconfig
BuildRequires: systemd
%endif
%if 0%{?fedora}
BuildRequires: bash-completion
%endif

%if %{with doc}
%if 0%{?fedora} || 0%{?rhel}
BuildRequires: docbook-style-xsl docbook-dtds libxslt
%endif

%if 0%{?suse_version}
BuildRequires: docbook-xsl-stylesheets libxslt
%endif

BuildRequires: asciidoc
%endif

%if 0%{?suse_version} > 9999
Obsoletes: mkinitrd < 2.6.1
Provides: mkinitrd = 2.6.1
%endif

Obsoletes: dracut-fips <= 047
Provides:  dracut-fips = %{version}-%{release}
Obsoletes: dracut-fips-aesni <= 047
Provides:  dracut-fips-aesni = %{version}-%{release}

Requires: bash >= 4
Requires: coreutils
Requires: cpio
Requires: filesystem >= 2.1.0
Requires: findutils
Requires: grep
Requires: kmod
Requires: sed
Requires: xz
Requires: gzip

%if 0%{?fedora} || 0%{?rhel}
Recommends: memstrack
Recommends: hardlink
Recommends: pigz
Recommends: kpartx
Requires: util-linux >= 2.21
Requires: systemd >= 219
Requires: systemd-udev >= 219
Requires: procps-ng
%else
Requires: hardlink
Requires: gzip
Requires: kpartx
Requires: udev > 166
Requires: util-linux-ng >= 2.21
%endif

%if 0%{?fedora} || 0%{?rhel} || 0%{?suse_version}
Requires: libkcapi-hmaccalc
%endif

%description
dracut contains tools to create bootable initramfses for the Linux
kernel. Unlike other implementations, dracut hard-codes as little
as possible into the initramfs. dracut contains various modules which
are driven by the event-based udev. Having root on MD, DM, LVM2, LUKS
is supported as well as NFS, iSCSI, NBD, FCoE with the dracut-network
package.

%package network
Summary: dracut modules to build a dracut initramfs with network support
%if 0%{?_module_build}
# In the module-build-service, we have pieces of dracut provided by different
# modules ("base-runtime" provides most functionality, but we need
# dracut-network in "installer". Since these two modules build with separate
# dist-tags, we need to reduce this strict requirement to ignore the dist-tag.
Requires: %{name} >= %{version}-%{dist_free_release}
%else
Requires: %{name} = %{version}-%{release}
%endif
Requires: iputils
Requires: iproute
Requires: (NetworkManager >= 1.20 or dhclient)
Suggests: NetworkManager
Obsoletes: dracut-generic < 008
Provides:  dracut-generic = %{version}-%{release}

%description network
This package requires everything which is needed to build a generic
all purpose initramfs with network support with dracut.

%package caps
Summary: dracut modules to build a dracut initramfs which drops capabilities
Requires: %{name} = %{version}-%{release}
Requires: libcap

%description caps
This package requires everything which is needed to build an
initramfs with dracut, which drops capabilities.

%package live
Summary: dracut modules to build a dracut initramfs with live image capabilities
%if 0%{?_module_build}
# See the network subpackage comment.
Requires: %{name} >= %{version}-%{dist_free_release}
%else
Requires: %{name} = %{version}-%{release}
%endif
Requires: %{name}-network = %{version}-%{release}
Requires: tar gzip coreutils bash device-mapper curl
%if 0%{?fedora}
Requires: fuse ntfs-3g
%endif

%description live
This package requires everything which is needed to build an
initramfs with dracut, with live image capabilities, like Live CDs.

%package config-generic
Summary: dracut configuration to turn off hostonly image generation
Requires: %{name} = %{version}-%{release}
Obsoletes: dracut-nohostonly < 030
Provides:  dracut-nohostonly = %{version}-%{release}

%description config-generic
This package provides the configuration to turn off the host specific initramfs
generation with dracut and generates a generic image by default.

%package config-rescue
Summary: dracut configuration to turn on rescue image generation
Requires: %{name} = %{version}-%{release}
Obsoletes: dracut < 030

%description config-rescue
This package provides the configuration to turn on the rescue initramfs
generation with dracut.

%package tools
Summary: dracut tools to build the local initramfs
Requires: %{name} = %{version}-%{release}

%description tools
This package contains tools to assemble the local initrd and host configuration.

%package squash
Summary: dracut module to build an initramfs with most files in a squashfs image
Requires: %{name} = %{version}-%{release}
Requires: squashfs-tools

%description squash
This package provides a dracut module to build an initramfs, but store most files
in a squashfs image, result in a smaller initramfs size and reduce runtime memory
usage.

%prep
%autosetup -n %{name}-%{version} -S git_am
cp %{SOURCE1} .

%build
%configure  --systemdsystemunitdir=%{_unitdir} \
            --bashcompletiondir=$(pkg-config --variable=completionsdir bash-completion) \
            --libdir=%{_prefix}/lib \
%if %{without doc}
            --disable-documentation \
%endif
            ${NULL}

%make_build

%install
%make_install %{?_smp_mflags} \
     libdir=%{_prefix}/lib

echo "DRACUT_VERSION=%{version}-%{release}" > $RPM_BUILD_ROOT/%{dracutlibdir}/dracut-version.sh

%if 0%{?fedora} == 0 && 0%{?rhel} == 0 && 0%{?suse_version} == 0
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/01fips
%endif

# we do not support dash in the initramfs
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/00dash

# we do not support mksh in the initramfs
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/00mksh

# remove gentoo specific modules
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/50gensplash

%if %{defined _unitdir}
# with systemd IMA and selinux modules do not make sense
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/96securityfs
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/97masterkey
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/98integrity
%endif

%ifnarch s390 s390x
# remove architecture specific modules
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/80cms
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/81cio_ignore
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/91zipl
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/95dasd
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/95dasd_mod
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/95dasd_rules
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/95dcssblk
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/95qeth_rules
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/95zfcp
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/95zfcp_rules
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/95znet
%else
rm -fr -- $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/00warpclock
%endif

mkdir -p $RPM_BUILD_ROOT/boot/dracut
mkdir -p $RPM_BUILD_ROOT/var/lib/dracut/overlay
mkdir -p $RPM_BUILD_ROOT%{_localstatedir}/log
touch $RPM_BUILD_ROOT%{_localstatedir}/log/dracut.log
mkdir -p $RPM_BUILD_ROOT%{_sharedstatedir}/initramfs

%if 0%{?fedora} || 0%{?rhel}
install -m 0644 dracut.conf.d/fedora.conf.example $RPM_BUILD_ROOT%{dracutlibdir}/dracut.conf.d/01-dist.conf
%endif
%if 0%{?suse_version}
install -m 0644 dracut.conf.d/suse.conf.example   $RPM_BUILD_ROOT%{dracutlibdir}/dracut.conf.d/01-dist.conf
%else
rm -f $RPM_BUILD_ROOT%{_mandir}/man?/*suse*
%endif

%if 0%{?fedora} == 0 && 0%{?rhel} == 0 && 0%{?suse_version} <= 9999
rm -f -- $RPM_BUILD_ROOT%{_bindir}/mkinitrd
rm -f -- $RPM_BUILD_ROOT%{_bindir}/lsinitrd
rm -f -- $RPM_BUILD_ROOT%{_mandir}/man8/mkinitrd.8*
rm -f -- $RPM_BUILD_ROOT%{_mandir}/man1/lsinitrd.1*
%endif

echo 'hostonly="no"' > $RPM_BUILD_ROOT%{dracutlibdir}/dracut.conf.d/02-generic-image.conf
echo 'dracut_rescue_image="yes"' > $RPM_BUILD_ROOT%{dracutlibdir}/dracut.conf.d/02-rescue.conf

%files
%if %{with doc}
%doc README.md HACKING.md TODO AUTHORS NEWS dracut.html dracut.png dracut.svg
%endif
%{!?_licensedir:%global license %%doc}
%license COPYING lgpl-2.1.txt
%{_bindir}/dracut
%{_datadir}/bash-completion/completions/dracut
%{_datadir}/bash-completion/completions/lsinitrd
%if 0%{?fedora} || 0%{?rhel} || 0%{?suse_version} > 9999
%{_bindir}/mkinitrd
%{_bindir}/lsinitrd
%endif
%dir %{dracutlibdir}
%dir %{dracutlibdir}/modules.d
%{dracutlibdir}/dracut-functions.sh
%{dracutlibdir}/dracut-init.sh
%{dracutlibdir}/dracut-functions
%{dracutlibdir}/dracut-version.sh
%{dracutlibdir}/dracut-logger.sh
%{dracutlibdir}/dracut-initramfs-restore
%{dracutlibdir}/dracut-install
%{dracutlibdir}/skipcpio
%config(noreplace) %{_sysconfdir}/dracut.conf
%if 0%{?fedora} || 0%{?suse_version} || 0%{?rhel}
%{dracutlibdir}/dracut.conf.d/01-dist.conf
%endif
%dir %{_sysconfdir}/dracut.conf.d
%dir %{dracutlibdir}/dracut.conf.d
%dir %{_datadir}/pkgconfig
%{_datadir}/pkgconfig/dracut.pc

%if %{with doc}
%{_mandir}/man8/dracut.8*
%{_mandir}/man8/*service.8*
%if 0%{?fedora} || 0%{?rhel} || 0%{?suse_version} > 9999
%{_mandir}/man8/mkinitrd.8*
%{_mandir}/man1/lsinitrd.1*
%endif
%if 0%{?suse_version}
%{_mandir}/man8/mkinitrd-suse.8*
%endif
%{_mandir}/man7/dracut.kernel.7*
%{_mandir}/man7/dracut.cmdline.7*
%{_mandir}/man7/dracut.modules.7*
%{_mandir}/man7/dracut.bootup.7*
%{_mandir}/man5/dracut.conf.5*
%endif

%if %{undefined _unitdir}
%endif
%{dracutlibdir}/modules.d/00bash
%{dracutlibdir}/modules.d/00systemd
%ifnarch s390 s390x
%{dracutlibdir}/modules.d/00warpclock
%endif
%if 0%{?fedora} || 0%{?rhel} || 0%{?suse_version}
%{dracutlibdir}/modules.d/01fips
%endif
%{dracutlibdir}/modules.d/01systemd-initrd
%{dracutlibdir}/modules.d/03modsign
%{dracutlibdir}/modules.d/03rescue
%{dracutlibdir}/modules.d/04watchdog
%{dracutlibdir}/modules.d/04watchdog-modules
%{dracutlibdir}/modules.d/05busybox
%{dracutlibdir}/modules.d/06dbus
%{dracutlibdir}/modules.d/06rngd
%{dracutlibdir}/modules.d/10i18n
%{dracutlibdir}/modules.d/30convertfs
%{dracutlibdir}/modules.d/35iwd
%{dracutlibdir}/modules.d/45url-lib
%{dracutlibdir}/modules.d/50drm
%{dracutlibdir}/modules.d/50plymouth
%{dracutlibdir}/modules.d/80lvmmerge
%{dracutlibdir}/modules.d/90btrfs
%{dracutlibdir}/modules.d/90crypt
%{dracutlibdir}/modules.d/90dm
%{dracutlibdir}/modules.d/90dmraid
%{dracutlibdir}/modules.d/90kernel-modules
%{dracutlibdir}/modules.d/90kernel-modules-extra
%{dracutlibdir}/modules.d/90lvm
%{dracutlibdir}/modules.d/90mdraid
%{dracutlibdir}/modules.d/90multipath
%{dracutlibdir}/modules.d/90nvdimm
%{dracutlibdir}/modules.d/90ppcmac
%{dracutlibdir}/modules.d/90qemu
%{dracutlibdir}/modules.d/91crypt-gpg
%{dracutlibdir}/modules.d/91crypt-loop
%{dracutlibdir}/modules.d/95debug
%{dracutlibdir}/modules.d/95fstab-sys
%{dracutlibdir}/modules.d/95lunmask
%{dracutlibdir}/modules.d/95nvmf
%{dracutlibdir}/modules.d/95resume
%{dracutlibdir}/modules.d/95rootfs-block
%{dracutlibdir}/modules.d/95terminfo
%{dracutlibdir}/modules.d/95udev-rules
%{dracutlibdir}/modules.d/95virtfs
%ifarch s390 s390x
%{dracutlibdir}/modules.d/80cms
%{dracutlibdir}/modules.d/81cio_ignore
%{dracutlibdir}/modules.d/91zipl
%{dracutlibdir}/modules.d/95dasd
%{dracutlibdir}/modules.d/95dasd_mod
%{dracutlibdir}/modules.d/95dasd_rules
%{dracutlibdir}/modules.d/95dcssblk
%{dracutlibdir}/modules.d/95qeth_rules
%{dracutlibdir}/modules.d/95zfcp
%{dracutlibdir}/modules.d/95zfcp_rules
%endif
%if %{undefined _unitdir}
%{dracutlibdir}/modules.d/96securityfs
%{dracutlibdir}/modules.d/97masterkey
%{dracutlibdir}/modules.d/98integrity
%endif
%{dracutlibdir}/modules.d/97biosdevname
%{dracutlibdir}/modules.d/98dracut-systemd
%{dracutlibdir}/modules.d/98ecryptfs
%{dracutlibdir}/modules.d/98pollcdrom
%{dracutlibdir}/modules.d/98selinux
%{dracutlibdir}/modules.d/98syslog
%{dracutlibdir}/modules.d/98usrmount
%{dracutlibdir}/modules.d/99base
%{dracutlibdir}/modules.d/99memstrack
%{dracutlibdir}/modules.d/99fs-lib
%{dracutlibdir}/modules.d/99shutdown
%attr(0644,root,root) %ghost %config(missingok,noreplace) %{_localstatedir}/log/dracut.log
%dir %{_sharedstatedir}/initramfs
%if %{defined _unitdir}
%{_unitdir}/dracut-shutdown.service
%{_unitdir}/sysinit.target.wants/dracut-shutdown.service
%{_unitdir}/dracut-cmdline.service
%{_unitdir}/dracut-initqueue.service
%{_unitdir}/dracut-mount.service
%{_unitdir}/dracut-pre-mount.service
%{_unitdir}/dracut-pre-pivot.service
%{_unitdir}/dracut-pre-trigger.service
%{_unitdir}/dracut-pre-udev.service
%{_unitdir}/initrd.target.wants/dracut-cmdline.service
%{_unitdir}/initrd.target.wants/dracut-initqueue.service
%{_unitdir}/initrd.target.wants/dracut-mount.service
%{_unitdir}/initrd.target.wants/dracut-pre-mount.service
%{_unitdir}/initrd.target.wants/dracut-pre-pivot.service
%{_unitdir}/initrd.target.wants/dracut-pre-trigger.service
%{_unitdir}/initrd.target.wants/dracut-pre-udev.service
%endif
%{_prefix}/lib/kernel/install.d/50-dracut.install

%files network
%{dracutlibdir}/modules.d/02systemd-networkd
%{dracutlibdir}/modules.d/35network-manager
%{dracutlibdir}/modules.d/35network-legacy
%{dracutlibdir}/modules.d/35network-wicked
%{dracutlibdir}/modules.d/35iwd
%{dracutlibdir}/modules.d/40network
%{dracutlibdir}/modules.d/45ifcfg
%{dracutlibdir}/modules.d/90kernel-network-modules
%{dracutlibdir}/modules.d/90qemu-net
%{dracutlibdir}/modules.d/95cifs
%{dracutlibdir}/modules.d/95fcoe
%{dracutlibdir}/modules.d/95fcoe-uefi
%{dracutlibdir}/modules.d/95iscsi
%{dracutlibdir}/modules.d/95nbd
%{dracutlibdir}/modules.d/95nfs
%{dracutlibdir}/modules.d/95ssh-client
%ifarch s390 s390x
%{dracutlibdir}/modules.d/95znet
%endif
%{dracutlibdir}/modules.d/99uefi-lib

%files caps
%{dracutlibdir}/modules.d/02caps

%files live
%{dracutlibdir}/modules.d/99img-lib
%{dracutlibdir}/modules.d/90dmsquash-live
%{dracutlibdir}/modules.d/90dmsquash-live-ntfs
%{dracutlibdir}/modules.d/90livenet

%files tools
%if %{with doc}
%doc %{_mandir}/man8/dracut-catimages.8*
%endif

%{_bindir}/dracut-catimages
%dir /boot/dracut
%dir /var/lib/dracut
%dir /var/lib/dracut/overlay

%files squash
%{dracutlibdir}/modules.d/99squash

%files config-generic
%{dracutlibdir}/dracut.conf.d/02-generic-image.conf

%files config-rescue
%{dracutlibdir}/dracut.conf.d/02-rescue.conf
%{_prefix}/lib/kernel/install.d/51-dracut-rescue.install

%changelog
