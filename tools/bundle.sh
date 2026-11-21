#!/usr/bin/env bash
# Generate the single-file ./build-iso from tools/build-iso.in + src/ (tar.gz, base64).
set -euo pipefail
cd "$(dirname "$0")/.."
tar --owner=0 --group=0 --numeric-owner --sort=name -czf - -C src . | base64 -w 76 > /tmp/blitzart-payload.b64
cat tools/build-iso.in /tmp/blitzart-payload.b64 > build-iso
chmod +x build-iso
rm -f /tmp/blitzart-payload.b64
echo "built: $(pwd)/build-iso ($(du -h build-iso | cut -f1))"
