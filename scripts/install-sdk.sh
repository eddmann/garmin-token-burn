#!/usr/bin/env bash
#
# Downloads the latest Connect IQ SDK for this OS into the given directory, unless
# monkeyc is already there. The SDK index and zips are public; only the
# device files from the SDK Manager need a Garmin login.
set -euo pipefail

sdk_dir="$1"
base="https://developer.garmin.com/downloads/connect-iq/sdks"
platform="linux"
if [[ "$(uname)" == "Darwin" ]]; then
  platform="mac"
fi

if [[ -x "$sdk_dir/bin/monkeyc" ]]; then
  exit 0
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

curl -fsS "$base/sdks.json" -o "$work/sdks.json"
file="$(python3 -c "import json, sys; print(json.load(open(sys.argv[1]))[-1][sys.argv[2]])" "$work/sdks.json" "$platform")"
echo "Downloading $file"
mkdir -p "$sdk_dir"
if [[ "$platform" == "mac" ]]; then
  # The macOS SDK is a disk image holding a single SDK folder.
  curl -fsS -L "$base/$file" -o "$work/sdk.dmg"
  hdiutil attach -quiet -nobrowse -readonly -mountpoint "$work/mnt" "$work/sdk.dmg"
  ditto "$work"/mnt/connectiq-sdk-*/ "$sdk_dir"
  hdiutil detach -quiet "$work/mnt"
else
  curl -fsS -L "$base/$file" -o "$work/sdk.zip"
  unzip -q -o "$work/sdk.zip" -d "$sdk_dir"
fi
chmod +x "$sdk_dir"/bin/*
