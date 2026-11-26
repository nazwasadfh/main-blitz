#!/usr/bin/env bash
# Generate the single-file ./build-iso from tools/build-iso.in + src/ (tar.gz, base64). Deterministic output.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
tar --owner=0 --group=0 --numeric-owner --sort=name --mtime='2020-01-01 00:00:00 UTC' -cf - -C src . \
    | gzip -n -9 | base64 -w 76 > "$tmp"
cat tools/build-iso.in "$tmp" > build-iso
chmod +x build-iso
echo "built: $(pwd)/build-iso ($(du -h build-iso | cut -f1))"
