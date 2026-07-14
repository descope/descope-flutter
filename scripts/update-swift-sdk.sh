#!/bin/bash
set -euo pipefail

REPO="descope/descope-swift"
SDK_SRC="src"
TARGET_DIR="ios/descope/Sources/descope/descope-swift-sdk"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

if [ -n "${1:-}" ]; then
  VERSION="$1"
else
  VERSION=$(gh api "repos/$REPO/releases/latest" --jq '.tag_name')
fi

echo "Fetching descope-swift $VERSION"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

gh api "repos/$REPO/tarball/$VERSION" > "$TMPDIR/sdk.tar.gz"
tar -xzf "$TMPDIR/sdk.tar.gz" -C "$TMPDIR" --strip-components=1

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

for entry in "$TMPDIR/$SDK_SRC"/*; do
  name=$(basename "$entry")
  [ "$name" = "docs" ] && continue
  cp -r "$entry" "$TARGET_DIR/"
done

echo "SDK version: $VERSION"
echo "Sources copied to: $TARGET_DIR"
