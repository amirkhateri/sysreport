#!/usr/bin/env bash

set -euo pipefail

sudo install -Dm755 bin/sysreport /usr/local/bin/sysreport
sudo install -d /usr/local/lib/sysreport/modules
sudo install -m644 src/sysreport/core.sh /usr/local/lib/sysreport/core.sh
sudo install -m644 VERSION /usr/local/lib/sysreport/VERSION
sudo install -m644 src/sysreport/modules/*.sh /usr/local/lib/sysreport/modules/

echo "Installed successfully."
echo "Run:"
echo "sysreport"
