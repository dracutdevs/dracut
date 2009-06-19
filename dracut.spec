# define gittag 2c02c831
%define replace_mkinitrd 0
%define with_switch_root 0
Name: dracut
Version: 0.1
%if %{defined gittag}
Release: 1.git%{gittag}%{?dist}
%define dashgittag -%{gittag}
%else
Release: 1%{?dist}
%endif
Summary: Initramfs generator using udev
Group: System Environment/Base		
License: GPLv2	
URL: http://apps.sourceforge.net/trac/dracut/wiki
Source0: dracut-%{version}%{?dashgittag}.tar.bz2
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: udev
Requires: util-linux-ng
Requires: module-init-tools
Requires: cpio
Requires: coreutils
Requires: findutils
Requires: grep
Requires: mktemp
Requires: mount
Requires: bash

%if 0%{?replace_mkinitrd}
Obsoletes: mkinitrd < 7.0
Provides: mkinitrd = 7.0
%endif

%if ! 0%{?with_switch_root}
BuildArch: noarch
%endif

%description
dracut is a new, event-driven initramfs infrastructure based around udev.


%package generic
Summary: Metapackage to build a generic initramfs
Requires: %{name} = %{version}-%{release}
Requires: device-mapper
Requires: cryptsetup-luks
Requires: rpcbind nfs-utils 
Requires: lvm2
Requires: iscsi-initiator-utils
Requires: nbd
Requires: mdadm
Requires: net-tools iproute

%description generic
This package requires everything, which is needed to build a generic
all purpose initramfs.


%prep
%setup -q -n %{name}-%{version}%{?dashgittag}

%build
make


%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT sbindir=/sbin sysconfdir=/etc mandir=%{_mandir}

%if 0%{?replace_mkinitrd}
ln -s dracut $RPM_BUILD_ROOT/sbin/mkinitrd
ln -s dracut/dracut-functions $RPM_BUILD_ROOT/usr/libexec/initrd-functions
%endif

%if ! 0%{?with_switch_root}
rm -f $RPM_BUILD_ROOT/sbin/switch_root
%endif

#mkdir -p $RPM_BUILD_ROOT/sbin
#mv $RPM_BUILD_ROOT/%{_prefix}/lib/dracut/modules.d/99base/switch_root $RPM_BUILD_ROOT/sbin

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,0755)
%doc README HACKING TODO COPYING AUTHORS
/sbin/dracut
%if 0%{?with_switch_root}
/sbin/switch_root
%endif
%if 0%{?replace_mkinitrd}
/sbin/mkinitrd
/usr/libexec/initrd-functions
%endif
%dir %{_datadir}/dracut
%{_datadir}/dracut/dracut-functions
%{_datadir}/dracut/modules.d
%config(noreplace) /etc/dracut.conf
%{_mandir}/man8/dracut.8*

%files generic
%defattr(-,root,root,0755)
%doc README.generic

%changelog
* Fri Jun 19 2009 Harald Hoyer <harald@redhat.com> 0.1-1
- first release

* Thu Dec 18 2008 Jeremy Katz <katzj@redhat.com> - 0.0-1
- Initial build

