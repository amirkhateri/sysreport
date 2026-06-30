Name:           sysreport
Version:        @VERSION@
Release:        1%{?dist}
Summary:        Ultimate Linux Server Audit CLI

License:        MIT
URL:            https://github.com/amirkhateri/sysreport

BuildArch:      noarch

Source0:        %{name}-%{version}.tar.gz

Requires: bash

%description
Ultimate Linux Server Audit CLI

%prep

%setup -q

%install

mkdir -p %{buildroot}/usr/local/bin

install -m 755 scripts/sysreport.sh %{buildroot}/usr/local/bin/sysreport

%files

/usr/local/bin/sysreport

%changelog