#
# spec file for package dracut
#
# Copyright (c) 2017 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


%define dracutlibdir %{_libexecdir}/dracut

Name:           dracut
Version:        047
Release:        0
Summary:        Initramfs generator using udev
License:        GPL-2.0-or-later AND LGPL-2.1-or-later
Group:          System/Base
Url:            https://dracut.wiki.kernel.org/
Source0:        dracut-%{version}.tar.xz

BuildRequires:  asciidoc
BuildRequires:  bash
BuildRequires:  docbook-xsl-stylesheets
BuildRequires:  libxslt
BuildRequires:  suse-module-tools
BuildRequires:  pkgconfig(systemd) >= 219
Requires:       %{_bindir}/get_kernel_version
Requires:       bash
# systemd-sysvinit provides: poweroff, reboot, halt
Requires:       coreutils
Requires(post): coreutils
Requires:       cpio
Requires:       elfutils
Requires:       file
Requires:       filesystem
Requires:       findutils
Requires:       grep
Requires:       hardlink
Requires:       modutils
Requires:       pigz
Requires:       sed
Requires:       systemd >= 219
Requires:       systemd-sysvinit
Requires:       udev > 166
Requires:       util-linux >= 2.21
Requires:       xz
# We use 'btrfs fi usage' that was not present before
Conflicts:      btrfsprogs < 3.18
Recommends:     logrotate
Obsoletes:      mkinitrd < 2.8.2
Provides:       mkinitrd = 2.8.2
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
%{?systemd_requires}

%description
Dracut contains tools to create a bootable initramfs for Linux kernels >= 2.6.
Dracut contains various modules which are driven by the event-based udev
and systemd. Having root on MD, DM, LVM2, LUKS is supported as well as
NFS, iSCSI, NBD, FCoE.

%package fips
Summary:        Dracut modules to build a dracut initramfs with an integrity check
Group:          System/Base
Requires:       %{name} = %{version}-%{release}
Requires:       fipscheck
Requires:       libcryptsetup12-hmac
Requires:       libgcrypt20-hmac
Requires:       libkcapi-tools

%description fips
This package requires everything which is needed to build an
initramfs with dracut, which does an integrity check of the kernel
and its cryptography during startup.

%package ima
Summary:        Dracut modules to build a dracut initramfs with IMA
Group:          System/Base
Requires:       %{name} = %{version}-%{release}
Requires:       evmctl
Requires:       keyutils

%description ima
This package requires everything which is needed to build an
initramfs (using dracut) which tries to load an IMA policy during startup.

%package tools
Summary:        Tools to build a local initramfs
Group:          System/Base
Requires:       %{name}
# split-provides for upgrade from SLES12 SP1 to SLES12 SP2
Provides:       %{name}:%{_bindir}/dracut-catimages

%description tools
This package contains tools to assemble the local initrd and host configuration.

%prep
%setup -q

%build
%configure\
  --systemdsystemunitdir=%{_unitdir}\
  --bashcompletiondir=%{_sysconfdir}/bash_completion.d\
  --libdir=%{_prefix}/lib
make all CFLAGS="%{optflags}" %{?_smp_mflags}

%install
make DESTDIR=%{buildroot} install %{?_smp_mflags}

echo -e "#!/bin/bash\nDRACUT_VERSION=%{version}-%{release}" > %{buildroot}/%{dracutlibdir}/dracut-version.sh

# use systemd-analyze instead, does not need dracut support
rm -fr %{buildroot}/%{dracutlibdir}/modules.d/00bootchart

# not supported
rm -fr %{buildroot}/%{dracutlibdir}/modules.d/00dash
rm -fr %{buildroot}/%{dracutlibdir}/modules.d/05busybox

# Remove RH-specific s390 modules
rm -fr %{buildroot}/%{dracutlibdir}/modules.d/95dasd
rm -fr %{buildroot}/%{dracutlibdir}/modules.d/95zfcp
rm -fr %{buildroot}/%{dracutlibdir}/modules.d/95znet

# remove gentoo specific modules
rm -fr %{buildroot}%{dracutlibdir}/modules.d/50gensplash

mkdir -p %{buildroot}/boot/dracut
mkdir -p %{buildroot}%{_localstatedir}/lib/dracut/overlay
mkdir -p %{buildroot}%{_localstatedir}/log
touch %{buildroot}%{_localstatedir}/log/dracut.log

install -D -m 0644 dracut.conf.d/suse.conf.example %{buildroot}/usr/lib/dracut/dracut.conf.d/01-dist.conf
install -m 0644 suse/99-debug.conf %{buildroot}%{_sysconfdir}/dracut.conf.d/99-debug.conf
install -m 0644 dracut.conf.d/fips.conf.example %{buildroot}%{_sysconfdir}/dracut.conf.d/40-fips.conf
install -m 0644 dracut.conf.d/ima.conf.example %{buildroot}%{_sysconfdir}/dracut.conf.d/40-ima.conf
# bsc#915218
%ifarch s390 s390x
install -m 0644 suse/s390x_persistent_device.conf %{buildroot}%{_sysconfdir}/dracut.conf.d/10-s390x_persistent_device.conf
%endif

%ifarch %ix86 x86_64
echo 'early_microcode="yes"' > %{buildroot}%{_sysconfdir}/dracut.conf.d/02-early-microcode.conf
%endif

rm %{buildroot}%{_bindir}/mkinitrd
# moved to /sbin
mkdir -p %{buildroot}/sbin
install -m 0755 mkinitrd-suse.sh %{buildroot}/sbin/mkinitrd
mv %{buildroot}%{_mandir}/man8/mkinitrd-suse.8 %{buildroot}%{_mandir}/man8/mkinitrd.8
install -m 0755 suse/mkinitrd_setup_dummy %{buildroot}/sbin/mkinitrd_setup

mkdir -p %{buildroot}%{_sysconfdir}/logrotate.d
install -m 0644 dracut.logrotate %{buildroot}%{_sysconfdir}/logrotate.d/dracut

install -D -m 0755 suse/purge-kernels %{buildroot}/sbin/purge-kernels
install -m 644 suse/purge-kernels.service %{buildroot}/%{_unitdir}/purge-kernels.service

install -D -m 0755 suse/dracut-installkernel %{buildroot}/sbin/installkernel

%if 0%{?suse_version}
#rm -f %{buildroot}/%{dracutlibdir}/modules.d/45ifcfg/write-ifcfg.sh
#ln -s %{dracutlibdir}/modules.d/45ifcfg/write-ifcfg-suse.sh %{buildroot}/%{dracutlibdir}/modules.d/45ifcfg/write-ifcfg.sh
%else
mv %{buildroot}/%{dracutlibdir}/modules.d/45ifcfg/write-ifcfg.sh %{buildroot}/%{dracutlibdir}/modules.d/45ifcfg/write-ifcfg-redhat.sh
ln -s %{dracutlibdir}/modules.d/45ifcfg/write-ifcfg-redhat.sh %{buildroot}/%{dracutlibdir}/modules.d/45ifcfg/write-ifcfg.sh
%endif

%pre
%service_add_pre purge-kernels.service

%post
%service_add_post purge-kernels.service
%{?regenerate_initrd_post}

%post fips
%{?regenerate_initrd_post}

%post ima
%{?regenerate_initrd_post}

%preun
%service_del_preun purge-kernels.service

%postun
%service_del_postun purge-kernels.service
%{?regenerate_initrd_post}

%postun fips
%{?regenerate_initrd_post}

%postun ima 
%{?regenerate_initrd_post}

%posttrans
%{?regenerate_initrd_posttrans}

%posttrans fips
%{?regenerate_initrd_posttrans}

%posttrans ima
%{?regenerate_initrd_posttrans}

%files fips
%defattr(-,root,root,0755)
%license COPYING
%config %{_sysconfdir}/dracut.conf.d/40-fips.conf
%{dracutlibdir}/modules.d/01fips
%{dracutlibdir}/modules.d/02fips-aesni

%files ima
%defattr(-,root,root,0755)
%license COPYING
%config %{_sysconfdir}/dracut.conf.d/40-ima.conf
%{dracutlibdir}/modules.d/96securityfs
%{dracutlibdir}/modules.d/97masterkey
%{dracutlibdir}/modules.d/98integrity

%files tools
%defattr(-,root,root,0755)
%{_bindir}/dracut-catimages
%{_mandir}/man8/dracut-catimages.8*
%dir /boot/dracut
%dir %{_localstatedir}/lib/dracut
%dir %{_localstatedir}/lib/dracut/overlay

%files
%defattr(-,root,root,0755)
%license COPYING
%doc README HACKING TODO AUTHORS NEWS dracut.html dracut.png dracut.svg
%{_bindir}/dracut
%{_bindir}/lsinitrd
/sbin/purge-kernels
/sbin/installkernel
/sbin/mkinitrd
/sbin/mkinitrd_setup
%config %{_sysconfdir}/bash_completion.d/lsinitrd
%{_datadir}/pkgconfig/dracut.pc

%config(noreplace) %{_sysconfdir}/dracut.conf
%dir %{_sysconfdir}/dracut.conf.d
%dir /usr/lib/dracut/dracut.conf.d
%config %{_sysconfdir}/dracut.conf.d/99-debug.conf
%if 0%{?fedora} || 0%{?suse_version} || 0%{?rhel}
/usr/lib/dracut/dracut.conf.d/01-dist.conf
%endif
%ifarch %ix86 x86_64
%config %{_sysconfdir}/dracut.conf.d/02-early-microcode.conf
%endif
%ifarch s390 s390x
%config %{_sysconfdir}/dracut.conf.d/10-s390x_persistent_device.conf
%endif

%{_mandir}/man8/dracut.8*
%{_mandir}/man8/mkinitrd.8*
%{_mandir}/man1/lsinitrd.1*
%{_mandir}/man7/dracut.kernel.7*
%{_mandir}/man7/dracut.cmdline.7*
%{_mandir}/man7/dracut.bootup.7*
%{_mandir}/man7/dracut.modules.7*
%{_mandir}/man8/dracut-cmdline.service.8*
%{_mandir}/man8/dracut-initqueue.service.8*
%{_mandir}/man8/dracut-pre-pivot.service.8*
%{_mandir}/man8/dracut-pre-trigger.service.8*
%{_mandir}/man8/dracut-pre-udev.service.8*
%{_mandir}/man8/dracut-mount.service.8.*
%{_mandir}/man8/dracut-pre-mount.service.8.*
%{_mandir}/man8/dracut-shutdown.service.8.*
%{_mandir}/man5/dracut.conf.5*

%dir %{_libexecdir}/kernel
%dir %{_libexecdir}/kernel/install.d
%{_libexecdir}/kernel/install.d/50-dracut.install
%{_libexecdir}/kernel/install.d/51-dracut-rescue.install

%dir %{dracutlibdir}
%{dracutlibdir}/skipcpio
%{dracutlibdir}/dracut-functions.sh
%{dracutlibdir}/dracut-init.sh
%{dracutlibdir}/dracut-functions
%{dracutlibdir}/dracut-version.sh
%{dracutlibdir}/dracut-logger.sh
%{dracutlibdir}/dracut-initramfs-restore
%{dracutlibdir}/dracut-install

%dir %{dracutlibdir}/modules.d
%{dracutlibdir}/modules.d/00bash
%{dracutlibdir}/modules.d/00warpclock
%{dracutlibdir}/modules.d/00systemd
%{dracutlibdir}/modules.d/01systemd-initrd
%{dracutlibdir}/modules.d/02systemd-networkd
%{dracutlibdir}/modules.d/03modsign
%{dracutlibdir}/modules.d/03rescue
%{dracutlibdir}/modules.d/04watchdog
%{dracutlibdir}/modules.d/10i18n
%{dracutlibdir}/modules.d/30convertfs
%{dracutlibdir}/modules.d/40network
%{dracutlibdir}/modules.d/45url-lib
%{dracutlibdir}/modules.d/45ifcfg
%{dracutlibdir}/modules.d/50drm
%{dracutlibdir}/modules.d/50plymouth
%{dracutlibdir}/modules.d/80cms
%{dracutlibdir}/modules.d/81cio_ignore
%{dracutlibdir}/modules.d/90livenet
%{dracutlibdir}/modules.d/90btrfs
%{dracutlibdir}/modules.d/90crypt
%{dracutlibdir}/modules.d/90dm
%{dracutlibdir}/modules.d/90dmraid
%{dracutlibdir}/modules.d/90dmsquash-live
%{dracutlibdir}/modules.d/90kernel-modules
%{dracutlibdir}/modules.d/90lvm
%{dracutlibdir}/modules.d/90mdraid
%{dracutlibdir}/modules.d/90multipath
%{dracutlibdir}/modules.d/90qemu
%{dracutlibdir}/modules.d/90kernel-network-modules
%{dracutlibdir}/modules.d/91crypt-gpg
%{dracutlibdir}/modules.d/91crypt-loop
%{dracutlibdir}/modules.d/91zipl
%{dracutlibdir}/modules.d/95fcoe-uefi
%{dracutlibdir}/modules.d/95nbd
%{dracutlibdir}/modules.d/95nfs
%{dracutlibdir}/modules.d/95ssh-client
%{dracutlibdir}/modules.d/95fcoe
%{dracutlibdir}/modules.d/95iscsi
%{dracutlibdir}/modules.d/95cifs
%{dracutlibdir}/modules.d/95debug
%{dracutlibdir}/modules.d/95resume
%{dracutlibdir}/modules.d/95rootfs-block
%{dracutlibdir}/modules.d/95dcssblk
%{dracutlibdir}/modules.d/95dasd_mod
%{dracutlibdir}/modules.d/95dasd_rules
%{dracutlibdir}/modules.d/95fstab-sys
%{dracutlibdir}/modules.d/95lunmask
%{dracutlibdir}/modules.d/95zfcp_rules
%{dracutlibdir}/modules.d/95terminfo
%{dracutlibdir}/modules.d/95udev-rules
%{dracutlibdir}/modules.d/95virtfs
%{dracutlibdir}/modules.d/95qeth_rules
%{dracutlibdir}/modules.d/97biosdevname
%{dracutlibdir}/modules.d/98ecryptfs
%{dracutlibdir}/modules.d/98pollcdrom
%{dracutlibdir}/modules.d/98selinux
%{dracutlibdir}/modules.d/98syslog
%{dracutlibdir}/modules.d/98dracut-systemd
%{dracutlibdir}/modules.d/98usrmount
%{dracutlibdir}/modules.d/99base
%{dracutlibdir}/modules.d/99fs-lib
%{dracutlibdir}/modules.d/99img-lib
%{dracutlibdir}/modules.d/99shutdown
%{dracutlibdir}/modules.d/99suse
%{dracutlibdir}/modules.d/99uefi-lib

# executable fixups
%attr(0755,root,root) %{dracutlibdir}/modules.d/00warpclock/warpclock.sh
%attr(0755,root,root) %{dracutlibdir}/modules.d/90livenet/livenet-generator.sh
%attr(0755,root,root) %{dracutlibdir}/modules.d/90multipath/multipath-shutdown.sh
%attr(0755,root,root) %{dracutlibdir}/modules.d/95dcssblk/parse-dcssblk.sh
%attr(0755,root,root) %{dracutlibdir}/modules.d/95dcssblk/module-setup.sh
%attr(0755,root,root) %{dracutlibdir}/modules.d/95fcoe/cleanup-fcoe.sh
%attr(0755,root,root) %{dracutlibdir}/modules.d/95fcoe/stop-fcoe.sh
%attr(0755,root,root) %{dracutlibdir}/modules.d/99suse/parse-suse-initrd.sh
%attr(0755,root,root) %{dracutlibdir}/modules.d/99suse/module-setup.sh

%attr(0755,root,root) %{dracutlibdir}/modules.d/95lunmask/sas_transport_scan_lun.sh
%attr(0755,root,root) %{dracutlibdir}/modules.d/95lunmask/parse-lunmask.sh
%attr(0755,root,root) %{dracutlibdir}/modules.d/95lunmask/fc_transport_scan_lun.sh
%attr(0755,root,root) %{dracutlibdir}/modules.d/95lunmask/module-setup.sh

%config(noreplace) %{_sysconfdir}/logrotate.d/dracut
%attr(0640,root,root) %ghost %config(missingok,noreplace) %{_localstatedir}/log/dracut.log
%dir %{_unitdir}/initrd.target.wants
%dir %{_unitdir}/sysinit.target.wants
%{_unitdir}/*.service
%{_unitdir}/*/*.service
%config %{_sysconfdir}/bash_completion.d/dracut

%changelog
