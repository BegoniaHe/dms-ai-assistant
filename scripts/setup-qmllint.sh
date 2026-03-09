#!/usr/bin/env bash
# setup-qmllint.sh — Generate .qmllint/qs/ module stubs for qmllint
#
# DMS uses a custom "qs." import prefix resolved by Quickshell at runtime.
# These modules have no qmldir files, so qmllint cannot resolve them.
# This script creates a local mirror with qmldir + symlinks so qmllint
# can understand qs.Common, qs.Widgets, and qs.Services.
#
# Usage:  ./scripts/setup-qmllint.sh
# Re-run after DMS updates to pick up new/removed types.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DMS_ROOT="/usr/share/quickshell/dms"
OUT_ROOT="$REPO_ROOT/.qmllint/qs"

if [[ ! -d "$DMS_ROOT" ]]; then
    echo "error: DMS not found at $DMS_ROOT" >&2
    exit 1
fi

MODULES=("Common" "Widgets" "Services")

for mod in "${MODULES[@]}"; do
    src="$DMS_ROOT/$mod"
    dest="$OUT_ROOT/$mod"

    if [[ ! -d "$src" ]]; then
        echo "warning: $src not found, skipping" >&2
        continue
    fi

    # Clean and recreate
    rm -rf "$dest"
    mkdir -p "$dest"

    # Start qmldir
    echo "module qs.$mod" > "$dest/qmldir"

    # Symlink QML files and add to qmldir.
    # Detect "pragma Singleton" to emit the singleton keyword.
    for qml in "$src"/*.qml; do
        [[ -f "$qml" ]] || continue
        name="$(basename "$qml" .qml)"
        ln -sf "$qml" "$dest/$name.qml"
        if head -5 "$qml" | grep -q 'pragma Singleton'; then
            echo "singleton $name 1.0 $name.qml" >> "$dest/qmldir"
        else
            echo "$name 1.0 $name.qml" >> "$dest/qmldir"
        fi
    done

    # Symlink JS files (singletons / pragma library)
    for js in "$src"/*.js; do
        [[ -f "$js" ]] || continue
        ln -sf "$js" "$dest/$(basename "$js")"
    done

    count=$(grep -c '\.qml$' "$dest/qmldir" || true)
    singletons=$(grep -c '^singleton ' "$dest/qmldir" || true)
    echo "qs.$mod: $count types ($singletons singletons)"
done

echo "Done. Module stubs written to $OUT_ROOT"
