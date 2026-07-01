Name:           sysreport
Version:        @VERSION@
Release:        1%{?dist}
Summary:        Linux server audit and operations summary CLI

License:        MIT
URL:            https://github.com/amirkhateri/sysreport

BuildArch:      noarch

Source0:        %{name}-%{version}.tar.gz

Requires:       bash

%description
Linux server audit and operations summary CLI.

%prep

%setup -q

%install

mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/lib/%{name}/modules

install -m 755 bin/sysreport %{buildroot}/usr/bin/sysreport
install -m 644 src/sysreport/core.sh %{buildroot}/usr/lib/%{name}/core.sh
install -m 644 VERSION %{buildroot}/usr/lib/%{name}/VERSION
install -m 644 src/sysreport/modules/*.sh %{buildroot}/usr/lib/%{name}/modules/

%files

/usr/bin/sysreport
%dir /usr/lib/%{name}
%dir /usr/lib/%{name}/modules
/usr/lib/%{name}/core.sh
/usr/lib/%{name}/VERSION
/usr/lib/%{name}/modules/*.sh

%changelog
