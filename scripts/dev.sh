#!/usr/bin/env bash
#
# Rebuilds on every save, for use with the master's dev mode.
#
#     ./scripts/dev.sh
#
# Point the master at this folder — admin panel, Modules, Dev mode — and it
# reads the wasm, the mini-app and the locales straight from disk, reloading the
# module itself whenever this script produces a new build. The master is never
# restarted.
set -euo pipefail

cd "$(dirname "$0")/.."

# A one-second poll rather than filesystem notifications. Watchers behave
# differently on macOS and Linux, and both stumble over the atomic rename a
# compiler does when writing output: you get told about a file that is
# momentarily not there. Polling is duller and does not lie.
#
# The marker is an empty file; `find -newer` compares against its timestamp.
# Parsing `stat` output would have meant guessing its format, which differs
# between the two platforms as well.
MARKER=$(mktemp)
trap 'rm -f "$MARKER"' EXIT

changed() {
    find src ui locales manifest.toml Cargo.toml \
        -type f -newer "$MARKER" -print -quit 2>/dev/null | grep -q .
}

build() {
    touch "$MARKER"
    if [ -f package.json ] && [ -d node_modules ]; then
        bun run build >/dev/null 2>&1 || echo "!! the mini-app did not build"
    fi
    if cargo build --release --target wasm32-unknown-unknown 2>&1 | grep -E '^(error|warning: unused)' ; then
        echo "!! wasm did not build"
    else
        echo "== rebuilt $(date +%H:%M:%S)"
    fi
}

[ -f package.json ] && [ -d node_modules ] || { [ -f package.json ] && bun install; }

echo "watching src/ ui/ locales/ — Ctrl-C to stop"
build
while true; do
    sleep 1
    if changed; then
        build
    fi
done
