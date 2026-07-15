#!/bin/bash
set -euo pipefail

REPO="descope/descope-kotlin"
GRADLE_FILE="android/build.gradle"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

# Resolve version: argument or latest release
if [ -n "${1:-}" ]; then
  VERSION="$1"
else
  VERSION=$(gh api "repos/$REPO/releases/latest" --jq '.tag_name')
fi

# The Kotlin SDK is consumed as a Maven dependency, not vendored as source,
# so bump the version pinned in the Gradle build file.
CURRENT=$(grep -oE 'com.descope:descope-kotlin:[0-9]+\.[0-9]+\.[0-9]+' "$GRADLE_FILE" | head -1 | cut -d: -f3)

if [ -z "$CURRENT" ]; then
  echo "Could not find com.descope:descope-kotlin dependency in $GRADLE_FILE" >&2
  exit 1
fi

sed -i '' "s/com.descope:descope-kotlin:$CURRENT/com.descope:descope-kotlin:$VERSION/" "$GRADLE_FILE"

echo "descope-kotlin: $CURRENT -> $VERSION"
echo "Updated: $GRADLE_FILE"
