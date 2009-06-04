# define gittag 2c02c831
%define replace_mkinitrd 0
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
Requires: lvm2
Requires: cryptsetup-luks
Requires: module-init-tools
Requires: cpio
Requires: device-mapper
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

%description
dracut is a new, event-driven initramfs infrastructure based around udev.

%prep
%setup -q -n %{name}-%{version}%{?dashgittag}

%build
make


%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT sbindir=/sbin sysconfdir=/etc

%if 0%{?replace_mkinitrd}
ln -s dracut $RPM_BUILD_ROOT/sbin/mkinitrd
ln -s dracut/dracut-functions $RPM_BUILD_ROOT/usr/libexec/initrd-functions
%endif

#mkdir -p $RPM_BUILD_ROOT/sbin
#mv $RPM_BUILD_ROOT/%{_prefix}/lib/dracut/modules.d/99base/switch_root $RPM_BUILD_ROOT/sbin

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc README HACKING TODO COPYING
/sbin/dracut
/sbin/switch_root
%if 0%{?replace_mkinitrd}
/sbin/mkinitrd
/usr/libexec/initrd-functions
%endif
%dir %{_prefix}/lib/dracut
%{_prefix}/lib/dracut/dracut-functions
%{_prefix}/lib/dracut/modules.d
%config(noreplace) /etc/dracut.conf


%changelog
* Thu Dec 18 2008 Jeremy Katz <katzj@redhat.com> - 0.0-1.gitc0815e4e%{?dist}
- Initial build

