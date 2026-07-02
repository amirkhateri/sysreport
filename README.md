# SysReport

[![npm version](https://img.shields.io/npm/v/sysreport?logo=npm&color=cb3837)](https://www.npmjs.com/package/sysreport)
[![npm downloads](https://img.shields.io/npm/dm/sysreport?logo=npm&color=cb3837)](https://www.npmjs.com/package/sysreport)
[![GitHub release](https://img.shields.io/github/v/release/amirkhateri/sysreport?logo=github&color=2ea44f)](https://github.com/amirkhateri/sysreport/releases)
[![CI](https://github.com/amirkhateri/sysreport/actions/workflows/ci.yml/badge.svg)](https://github.com/amirkhateri/sysreport/actions/workflows/ci.yml)
[![Release](https://github.com/amirkhateri/sysreport/actions/workflows/release.yml/badge.svg)](https://github.com/amirkhateri/sysreport/actions/workflows/release.yml)
[![COPR](https://img.shields.io/badge/COPR-khateri%2Fsysreport-3c6eb4?logo=fedora)](https://copr.fedorainfracloud.org/coprs/khateri/sysreport/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnubash&logoColor=white)](bin/sysreport)
[![Linux](https://img.shields.io/badge/platform-linux-FCC624?logo=linux&logoColor=black)](README.md)
[![dnf](https://img.shields.io/badge/install-dnf-294172?logo=fedora&logoColor=white)](#debian--ubuntu-and-rpm)
[![apt](https://img.shields.io/badge/install-apt-A81D33?logo=debian&logoColor=white)](#debian--ubuntu-and-rpm)
[![GitHub stars](https://img.shields.io/github/stars/amirkhateri/sysreport?style=social)](https://github.com/amirkhateri/sysreport/stargazers)

SysReport is a lightweight Linux server audit CLI for sysadmins, DevOps engineers, and hosting operators. Run one command and get a practical summary of the server's health, identity, network, web stack, databases, security posture, and optimization signals.

```bash
sysreport
```

## Highlights

- Modular Bash architecture: each report area lives in `src/sysreport/modules/`.
- Safe by default: it does not install dependencies or change server configuration while reporting.
- Works on generic Linux servers and adds extra context when cPanel/WHM, PHP, MySQL, Redis, Memcached, or common firewalls are detected.
- Supports targeted checks with `--section`.
- Friendly to package managers: npm, deb/rpm layouts, and manual install scripts are included.

## Installation

Install from npm, COPR, GitHub Releases, or directly from source.

### Manual

```bash
git clone https://github.com/amirkhateri/sysreport.git
cd sysreport
bash scripts/install/install.sh
sysreport
```

### npm

```bash
npm install -g sysreport
sysreport
```

### Debian / Ubuntu and RPM

Download packages from the GitHub release page, or install the RPM directly with `dnf`:

```bash
VERSION=1.1.3
sudo dnf install -y "https://github.com/amirkhateri/sysreport/releases/download/v${VERSION}/sysreport-${VERSION}-1.noarch.rpm"
```

You can also enable the COPR repository:

```bash
sudo dnf install -y dnf-plugins-core
sudo dnf copr enable khateri/sysreport
sudo dnf install -y sysreport
```

Debian/Ubuntu users can install the `.deb` package from the same release:

```bash
VERSION=1.1.3
curl -LO "https://github.com/amirkhateri/sysreport/releases/download/v${VERSION}/sysreport_${VERSION}_all.deb"
sudo apt install ./sysreport_${VERSION}_all.deb
```

Package templates are available under `templates/`, and release automation publishes `.deb` and `.rpm` artifacts.

For GitHub releases, download the `sysreport-<version>.tar.gz` archive, extract it, and run the installer:

```bash
tar -xzf sysreport-<version>.tar.gz
cd sysreport-<version>
bash scripts/install/install.sh
```

## Usage

```bash
sysreport                 # run the full report
sysreport --list-sections # show available sections
sysreport --section system --section security
sysreport --no-color
sysreport --version
```

Current sections:

- `system`
- `identity`
- `network`
- `services`
- `webstack`
- `database`
- `security`
- `optimization`

You can customize network ping targets:

```bash
SYSREPORT_PING_TARGETS="1.1.1.1 github.com example.com" sysreport --section network
```

## Optional Dependencies

SysReport runs without these tools, but it reports more detail when they exist:

- `curl` for public IP detection
- `jq` for IP geolocation parsing
- `fastfetch` for an optional system profile block
- `systemctl`, `ss`, `ip`, `ping`, `free`, `df`, `awk`, `sed`, `grep`
- `mysql`, `psql`, `php`, `nginx`, `httpd` or `apache2` for stack-specific checks

## Development

Run locally:

```bash
make run
make sections
```

Syntax check:

```bash
make check
```

Add a new report module by creating a file in `src/sysreport/modules/`:

```bash
report_example() {
  sysreport_section "Example"
  sysreport_item "Status" "ok"
}

sysreport_register_section "example" "Example report" "report_example"
```

## Philosophy

SysReport should be useful on the first run, readable by humans, conservative on production servers, and easy to extend. It reports what it can see and skips what is unavailable instead of failing the whole run.

## License

MIT
