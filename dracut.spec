%if 0%{?fedora} < 12
%define with_switch_root 1
%else
%define with_switch_root 0
%endif

%if %{defined gittag}
%define rdist .git%{gittag}%{?dist}
%define dashgittag -%{gittag}
%else
%define rdist %{?dist}
%endif

Name: dracut
Version: 001
Release: 1%{?rdist}
Summary: Initramfs generator using udev
Group: System Environment/Base		
License: GPLv2+	
URL: http://apps.sourceforge.net/trac/dracut/wiki
Source0: dracut-%{version}%{?dashgittag}.tar.bz2
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: udev
Requires: util-linux-ng
Requires: module-init-tools >= 3.7-9
Requires: cpio
Requires: coreutils
Requires: findutils
Requires: binutils
Requires: grep
Requires: which
Requires: mktemp >= 1.5-5
Requires: mount
Requires: bash
Requires: dash
Requires: /bin/sh 
Requires: fileutils, gzip, tar
Requires: lvm2 >= 2.02.33-9, dhclient
Requires: filesystem >= 2.1.0, cpio, device-mapper, initscripts >= 8.63-1
Requires: e2fsprogs >= 1.38-12, libselinux, libsepol, coreutils
Requires: mdadm, elfutils-libelf, plymouth >= 0.7.0
Requires: cryptsetup-luks
Requires: file
Requires: bzip2
Requires: policycoreutils
Requires: dmraid
Requires: kbd

%if ! 0%{?with_switch_root}
Requires: util-linux-ng >= 2.16
BuildArch: noarch
%endif

%description
dracut is a new, event-driven initramfs infrastructure based around udev.

%package network
Summary: dracut modules to build a dracut initramfs with network support
Requires: %{name} = %{version}-%{release}
Requires: rpcbind nfs-utils 
Requires: iscsi-initiator-utils
Requires: nbd
Requires: net-tools iproute
Requires: bridge-utils

%description network
This package requires everything which is needed to build a generic
all purpose initramfs with network support with dracut.

%package generic
Summary: Metapackage to build a generic initramfs with dracut
Requires: %{name} = %{version}-%{release}
Requires: %{name}-network = %{version}-%{release}

%description generic
This package requires everything which is needed to build a generic
all purpose initramfs with dracut.


%package kernel
Summary: Metapackage to build generic initramfs with dracut with only kernel modules
Requires: %{name} = %{version}-%{release}
Requires: ql2100-firmware
Requires: ql2200-firmware
Requires: ql23xx-firmware
Requires: ql2400-firmware
Requires: ql2500-firmware

%description kernel
This package requires everything which is needed to build a initramfs with all
kernel modules and firmware files needed by dracut modules.

%package tools
Summary: dracut tools to build the local initramfs
Requires: coreutils cryptsetup-luks device-mapper
Requires: diffutils dmraid findutils gawk grep lvm2
Requires: module-init-tools sed
Requires: cpio gzip

%description tools
This package contains tools to assemble the local initrd and host configuration.

%prep
%setup -q -n %{name}-%{version}%{?dashgittag}

%build
make


%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT sbindir=/sbin \
     sysconfdir=/etc mandir=%{_mandir}

%if ! 0%{?with_switch_root}
rm -f $RPM_BUILD_ROOT/sbin/switch_root
%endif

mkdir -p $RPM_BUILD_ROOT/boot/dracut
mkdir -p $RPM_BUILD_ROOT/var/lib/dracut/overlay

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,0755)
%doc README HACKING TODO COPYING AUTHORS NEWS
/sbin/dracut
%if 0%{?with_switch_root}
/sbin/switch_root
%endif
%dir %{_datadir}/dracut
%{_datadir}/dracut/dracut-functions
%config(noreplace) /etc/dracut.conf
%{_mandir}/man8/dracut.8*
%{_datadir}/dracut/modules.d/00dash
%{_datadir}/dracut/modules.d/10redhat-i18n
%{_datadir}/dracut/modules.d/10rpmversion
%{_datadir}/dracut/modules.d/50plymouth
%{_datadir}/dracut/modules.d/90crypt
%{_datadir}/dracut/modules.d/90dmraid
%{_datadir}/dracut/modules.d/90dmsquash-live
%{_datadir}/dracut/modules.d/90kernel-modules
%{_datadir}/dracut/modules.d/90lvm
%{_datadir}/dracut/modules.d/90mdraid
%{_datadir}/dracut/modules.d/95debug
%{_datadir}/dracut/modules.d/95resume
%{_datadir}/dracut/modules.d/95rootfs-block
%{_datadir}/dracut/modules.d/95s390
%{_datadir}/dracut/modules.d/95terminfo
%{_datadir}/dracut/modules.d/95udev-rules
%{_datadir}/dracut/modules.d/95udev-rules.ub810
%{_datadir}/dracut/modules.d/98syslog
%{_datadir}/dracut/modules.d/99base

%files network
%defattr(-,root,root,0755)
%{_datadir}/dracut/modules.d/40network
%{_datadir}/dracut/modules.d/95fcoe
%{_datadir}/dracut/modules.d/95iscsi
%{_datadir}/dracut/modules.d/95nbd
%{_datadir}/dracut/modules.d/95nfs

%files kernel 
%defattr(-,root,root,0755)
%doc README.kernel

%files generic
%defattr(-,root,root,0755)
%doc README.generic

%files tools 
%defattr(-,root,root,0755)
%doc COPYING NEWS
/sbin/dracut-gencmdline
/sbin/dracut-catimages
%dir /boot/dracut
%dir /var/lib/dracut
%dir /var/lib/dracut/overlay

%changelog
* Wed Sep 02 2009 Harald Hoyer <harald@redhat.com> 001-1
- version 001
- see http://dracut.git.sourceforge.net/git/gitweb.cgi?p=dracut/dracut;a=blob_plain;f=NEWS

* Fri Aug 14 2009 Harald Hoyer <harald@redhat.com> 0.9-1
- version 0.9

* Thu Aug 06 2009 Harald Hoyer <harald@redhat.com> 0.8-1
- version 0.8 
- see http://dracut.git.sourceforge.net/git/gitweb.cgi?p=dracut/dracut;a=blob_plain;f=NEWS

* Fri Jul 24 2009 Harald Hoyer <harald@redhat.com> 0.7-1
- version 0.7
- see http://dracut.git.sourceforge.net/git/gitweb.cgi?p=dracut/dracut;a=blob_plain;f=NEWS

* Wed Jul 22 2009 Harald Hoyer <harald@redhat.com> 0.6-1
- version 0.6
- see http://dracut.git.sourceforge.net/git/gitweb.cgi?p=dracut/dracut;a=blob_plain;f=NEWS

* Fri Jul 17 2009 Harald Hoyer <harald@redhat.com> 0.5-1
- version 0.5
- see http://dracut.git.sourceforge.net/git/gitweb.cgi?p=dracut/dracut;a=blob_plain;f=NEWS

* Sat Jul 04 2009 Harald Hoyer <harald@redhat.com> 0.4-1
- version 0.4
- see http://dracut.git.sourceforge.net/git/gitweb.cgi?p=dracut/dracut;a=blob_plain;f=NEWS

* Thu Jul 02 2009 Harald Hoyer <harald@redhat.com> 0.3-1
- version 0.3
- see http://dracut.git.sourceforge.net/git/gitweb.cgi?p=dracut/dracut;a=blob_plain;f=NEWS

* Wed Jul 01 2009 Harald Hoyer <harald@redhat.com> 0.2-1
- version 0.2

* Fri Jun 19 2009 Harald Hoyer <harald@redhat.com> 0.1-1
- first release

* Thu Dec 18 2008 Jeremy Katz <katzj@redhat.com> - 0.0-1
- Initial build

