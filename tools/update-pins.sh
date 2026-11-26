#!/usr/bin/env bash
# Refresh the commit/tag pins in tools/build-iso.in from the upstream HEADs / latest Bibata release.
# Dry run by default; --write edits the PINS block. Afterwards run tools/bundle.sh and review the diff.
set -euo pipefail
cd "$(dirname "$0")/.."
WRITE=0; [[ ${1:-} == --write ]] && WRITE=1
F=tools/build-iso.in
head_of() { git ls-remote "$1" HEAD | awk '{ print $1 }'; }
declare -A NEW
# take the URLs from the file itself, so they cannot drift
url_of() { sed -n "s/^readonly $1=\"\(.*\)\"/\1/p" "$F" | head -1; }
NEW[PIN_OMZ]=$(head_of "$(url_of OMZ_URL)")
NEW[PIN_SDDM]=$(head_of "$(url_of SDDM_URL)")
NEW[PIN_II]=$(head_of "$(url_of II_URL)")
NEW[PIN_E4]=$(head_of "$(url_of E4_URL)")
repo=$(url_of CURSOR_REPO)
tag=$(git ls-remote --tags --refs "$repo" 'v*' | awk '{ sub("refs/tags/", "", $2); print $2 }' | sort -V | tail -1)
NEW[PIN_BIBATA_TAG]=$tag
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
curl -fsSL -o "$tmp" "$repo/releases/download/$tag/Bibata-Modern-Classic.tar.xz"
NEW[PIN_BIBATA_SHA256]=$(sha256sum "$tmp" | cut -d' ' -f1)
for k in PIN_OMZ PIN_SDDM PIN_II PIN_E4 PIN_BIBATA_TAG PIN_BIBATA_SHA256; do
  old=$(sed -n "s/^$k=\"\(.*\)\"/\1/p" "$F")
  [[ -n ${NEW[$k]} ]] || { echo "no value for $k" >&2; exit 1; }
  if [[ $old == "${NEW[$k]}" ]]; then printf '= %-18s unchanged\n' "$k"
  else printf '~ %-18s %s -> %s\n' "$k" "${old:0:12}" "${NEW[$k]:0:12}"
       ((WRITE)) && sed -i "s/^$k=\".*\"/$k=\"${NEW[$k]}\"/" "$F"
  fi
done
((WRITE)) || echo "(dry run; use --write, then tools/bundle.sh)"
