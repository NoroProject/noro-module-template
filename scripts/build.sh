#!/usr/bin/env bash
#
# Builds the module into a single `.noromod` file.
#
#     ./scripts/build.sh
#
# The result is `dist/<id>.noromod` — that is what you upload in the panel.
set -euo pipefail

cd "$(dirname "$0")/.."
[ -f manifest.toml ] || { echo "manifest.toml is missing"; exit 1; }

# The identifier becomes the package filename. Taken from the manifest so it
# cannot disagree with the name the module installs under.
ID=$(grep -m1 '^id *=' manifest.toml | sed 's/.*= *"\(.*\)"/\1/')
[ -n "$ID" ] || { echo "manifest.toml has no id"; exit 1; }

# The frontend goes first: its errors are easier to read, and wasm takes longer.
if [ -f package.json ]; then
    echo "==> mini-app"
    if command -v bun >/dev/null 2>&1; then
        [ -d node_modules ] || bun install
        bun run build
    else
        [ -d node_modules ] || npm install
        npm run build
    fi
fi

echo "==> wasm"
cargo build --release --target wasm32-unknown-unknown

WASM=$(find target/wasm32-unknown-unknown/release -maxdepth 1 -name '*.wasm' | head -1)
[ -n "$WASM" ] || { echo "no wasm was produced"; exit 1; }

# wasm-opt cuts the size by about a third and is not installed everywhere, so
# it stays optional.
if command -v wasm-opt >/dev/null 2>&1; then
    echo "==> wasm-opt"
    wasm-opt -Oz "$WASM" -o "$WASM.opt" && mv "$WASM.opt" "$WASM"
else
    echo "==> wasm-opt not found, skipping (the package will be larger)"
fi

echo "==> packaging"
rm -rf dist
mkdir -p dist/pkg
cp manifest.toml dist/pkg/
cp "$WASM" dist/pkg/module.wasm
[ -d locales ] && cp -r locales dist/pkg/
[ -d web ] && cp -r web dist/pkg/
[ -d migrations ] && cp -r migrations dist/pkg/
[ -f icon.png ] && cp icon.png dist/pkg/

# `-X` drops the macOS metadata: without it `__MACOSX` entries travel into the
# archive and the master sees files the author never put there.
(cd dist/pkg && zip -q -r -X "../$ID.noromod" .)
rm -rf dist/pkg

echo "done: dist/$ID.noromod ($(du -h "dist/$ID.noromod" | cut -f1))"
