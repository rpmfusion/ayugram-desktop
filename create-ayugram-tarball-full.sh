#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <ayugram-version>"
    exit 1
fi

SCRIPT_PWD="$(pwd)"

VERSION="$1"
REPO="https://github.com/AyuGram/AyuGramDesktop.git"

TOPDIR="AyuGramDesktop-${VERSION}-full"
TARBALL="${TOPDIR}.tar.gz"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "Cloning AyuGramDesktop v${VERSION} with submodules..."
git clone --recursive --branch "v${VERSION}" --depth 1 "$REPO" "$TMPDIR/$TOPDIR"

cd "$TMPDIR/$TOPDIR"

echo "Generating bundled() Provides into provides.txt..."

PROVIDES_FILE="${SCRIPT_PWD}/provides.txt"
: > "$PROVIDES_FILE"

git submodule foreach --recursive --quiet '
commit=$(git rev-parse --short=7 HEAD)
url=$(git config --get remote.origin.url)
name="${url##*/}"
name="${name%.git}"

if tag=$(git describe --tags --exact-match 2>/dev/null); then
    ver=${tag#v}
elif tag=$(git describe --tags --abbrev=0 2>/dev/null); then
    ver="${tag#v}~git${commit}"
else
    ver="0~git${commit}"
fi

echo "# $url"
echo "Provides: bundled(${name}) = ${ver}"
' >> "$PROVIDES_FILE"

echo "Removing all .git directories..."
find . -name .git -prune -exec rm -rf {} +

cd "$TMPDIR"

echo "Creating tarball ${TARBALL}..."
tar --sort=name \
    --mtime="@${SOURCE_DATE_EPOCH:-$(date +%s)}" \
    --owner=0 --group=0 --numeric-owner \
    -czf "$TARBALL" "$TOPDIR"

mv "$TARBALL" "$SCRIPT_PWD/"

echo "Done:"
echo "$(readlink -f "$SCRIPT_PWD/$TARBALL")"
