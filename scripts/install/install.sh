#!/usr/bin/env bash

set -e

sudo install -Dm755 scripts/sysreport.sh /usr/local/bin/sysreport

echo "Installed successfully."

echo "Run:"
echo "sysreport"