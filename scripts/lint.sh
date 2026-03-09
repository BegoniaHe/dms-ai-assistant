#!/usr/bin/env bash
# lint.sh — Run qmllint with DMS module stubs
#
# .qmllint.ini cannot specify import paths, so this wrapper sets
# QML_IMPORT_PATH and passes -E to qmllint.
#
# Usage:  ./scripts/lint.sh [files...]
# If no files are given, all *.qml in the project root are linted.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STUBS="$REPO_ROOT/.qmllint/qs"

if [[ ! -d "$STUBS" ]]; then
    echo "Module stubs not found. Running setup first..." >&2
    "$REPO_ROOT/scripts/setup-qmllint.sh"
fi

export QML_IMPORT_PATH="$REPO_ROOT/.qmllint:/usr/lib64/qt6/qml"

files=("$@")
if [[ ${#files[@]} -eq 0 ]]; then
    mapfile -t files < <(find "$REPO_ROOT" -maxdepth 1 -name '*.qml' -type f | sort)
fi

exec qmllint-qt6 -E "${files[@]}"
