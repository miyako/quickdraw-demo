#!/bin/sh
# Stage a local quickdraw component build into Components/ for development.
# The Dependency Manager resolves github:miyako/quickdraw tag:0.1.3 when the
# project is opened in the IDE; Components/ stays out of version control.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
src=${1:-}
if [ -z "$src" ] || [ ! -d "$src" ]; then
  echo "usage: $0 /path/to/quickdraw.4dbase" >&2
  exit 2
fi
if [ ! -d "$src/Resources/bin/macOS" ]; then
  echo "not a quickdraw component: $src" >&2
  exit 2
fi
rm -rf "$root/Components/quickdraw.4dbase"
mkdir -p "$root/Components"
cp -R "$src" "$root/Components/quickdraw.4dbase"
echo "staged $root/Components/quickdraw.4dbase"
