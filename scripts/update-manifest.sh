#!/usr/bin/env bash
# Updates bucket/kuml.json to the latest kUML release: version, URL, extract_dir
# and the SHA-256 that GitHub reports for the Windows runtime ZIP (no download).
# Exits 0 without a change when the manifest is current or the ZIP is not
# attached to the release yet.
set -euo pipefail

repo="kuml-dev/kUML"
manifest="bucket/kuml.json"

tag="$(gh release view --repo "$repo" --json tagName -q .tagName)"
version="${tag#v}"
asset="kuml-runtime-${version}-windows-x86_64.zip"
digest="$(gh release view "$tag" --repo "$repo" --json assets \
  -q ".assets[] | select(.name == \"${asset}\") | .digest")"

if [ -z "$digest" ]; then
  echo "No ${asset} on release ${tag} yet; nothing to do."
  exit 0
fi
hash="${digest#sha256:}"
if ! [[ "$hash" =~ ^[0-9a-f]{64}$ ]]; then
  echo "Unexpected digest '${digest}' for ${asset}" >&2
  exit 1
fi

jq --arg v "$version" --arg h "$hash" --arg t "$tag" --arg a "$asset" '
  .version = $v
  | .architecture."64bit".url = "https://github.com/kuml-dev/kUML/releases/download/\($t)/\($a)"
  | .architecture."64bit".hash = $h
  | .architecture."64bit".extract_dir = "kuml-\($v)"
' "$manifest" > "${manifest}.tmp"
mv "${manifest}.tmp" "$manifest"
echo "Manifest now at ${version} (${hash})"
