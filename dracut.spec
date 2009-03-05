# define gittag f8a22bfb
%define replace_mkinitrd 0
Name: dracut
Version: 0.0
%if %{defined gittag}
Release: 1.git%{gittag}%{?dist}
%define dashgittag -%{gittag}
%else
Release: 1%{?dist}
%endif
Summary: Initramfs generator using udev
Group: System Environment/Base		
License: GPLv2	
URL: http://fedoraproject.org/wiki/Initrdrewrite		
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
dracut is an attempt to build a new, event-driven initramfs infrastructure 
based around udev.


%prep
%setup -q -n %{name}-%{version}%{?dashgittag}

%build
make


%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%if 0%{?replace_mkinitrd}
ln -s dracut $RPM_BUILD_ROOT/sbin/mkinitrd
ln -s dracut/functions $RPM_BUILD_ROOT/usr/libexec/initrd-functions
%endif

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc README HACKING TODO COPYING
/sbin/dracut
%if 0%{?replace_mkinitrd}
/sbin/mkinitrd
/usr/libexec/initrd-functions
%endif
%dir /usr/libexec/dracut
/usr/libexec/dracut/functions
%dir /usr/libexec/dracut/modules.d
/usr/libexec/dracut/modules.d
%config(noreplace) /etc/dracut.conf


%changelog
* Thu Dec 18 2008 Jeremy Katz <katzj@redhat.com> - 0.0-1.gitc0815e4e%{?dist}
- Initial build

