# Changelog

## 1.1.2

- Improved WHM/cPanel output formatting for PHP-FPM units.
- Added CSF, LFD, Imunify360, firewalld, and ufw service status checks.
- Kept `--no-color` output clean by suppressing fastfetch's colored block.

## 1.1.1

- Fixed installed CLI version detection by installing `VERSION` with the runtime files.
- Included `VERSION` in nFPM and RPM package layouts.

## 1.1.0

- Rebuilt SysReport as a modular CLI with a small launcher and reusable report modules.
- Added CI smoke tests and GitHub release archive automation.
- Added public project docs: README, contributing guide, security policy, license, and packaging metadata.
- Added safer runtime behavior for public use: report-only execution, section filtering, and graceful skips for missing tools.

## 1.0.2

- Refactored the CLI into a modular runtime under `src/sysreport/`.
- Added section filtering with `--section` and discovery with `--list-sections`.
- Removed automatic dependency installation during report execution.
- Updated package metadata and install paths for public distribution.

## 1.0.0

- Initial release.
- Hardware audit.
- Network audit.
- PHP audit.
- MySQL audit.
- Security audit.
- SEO audit.
