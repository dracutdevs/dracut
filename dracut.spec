%define gittag c0815e4e
Name: dracut
Version: 0.0
Release: 1.git%{gittag}%{?dist}
Summary: Initramfs generator using udev
Group: System Environment/Base		
License: GPLv2	
URL: http://fedoraproject.org/wiki/Initrdrewrite		
Source0: dracut-%{gittag}.tar.bz2
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
Requires: nash
Requires: bash
Requires: /usr/bin/eu-readelf
Obsoletes: mkinitrd < 7.0
Provides: mkinitrd = 7.0
BuildArch: noarch

%description
dracut is an attempt to build a new, event-driven initramfs infrastructure 
based around udev.


%prep
%setup -q -n %{name}


%build
make


%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

ln -s dracut $RPM_BUILD_ROOT/sbin/mkinitrd
ln -s dracut/functions $RPM_BUILD_ROOT/usr/libexec/initrd-functions


%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
%doc README HACKING TODO COPYING
/sbin/dracut
/sbin/mkinitrd
/usr/libexec/initrd-functions
%dir /usr/libexec/dracut
/usr/libexec/dracut/functions
/usr/libexec/dracut/init
/usr/libexec/dracut/switch_root
/usr/libexec/dracut/rules.d



%changelog
* Thu Dec 18 2008 Jeremy Katz <katzj@redhat.com> - 0.0-1.gitc0815e4e%{?dist}
- Initial build

