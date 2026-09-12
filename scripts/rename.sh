#!/usr/bin/env bash
#
# Gives the module its own identity, right after cloning the template.
#
#     ./scripts/rename.sh my-module "My Module"
#
# The identifier appears in four places that have to agree: the crate name, the
# manifest `id`, the prefix of every locale key, and the mini-app's package
# name. Doing it by hand means missing one and finding out at install time.
set -euo pipefail

cd "$(dirname "$0")/.."

ID="${1:-}"
NAME="${2:-}"
OLD_ID="noro-module-template"

if [ -z "$ID" ] || [ -z "$NAME" ]; then
    echo "usage: ./scripts/rename.sh <id> \"<display name>\""
    echo "  id: lowercase letters, digits and hyphens only"
    exit 2
fi

# The identifier becomes a Postgres schema name, a URL path and a locale key
# prefix. Nobody is going to escape it in three places, so it is restricted
# here — the master refuses anything else on install anyway.
if ! printf '%s' "$ID" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'; then
    echo "the id \"$ID\" is not allowed: lowercase letters, digits and hyphens, not starting or ending with a hyphen"
    exit 1
fi

grep -rl "$OLD_ID" \
    --include='*.toml' --include='*.rs' --include='*.ftl' \
    --include='*.json' --include='*.js' --include='*.vue' --include='*.md' \
    --include='*.yml' . 2>/dev/null \
    | grep -v '^./target/' | grep -v '^./node_modules/' \
    | while read -r f; do
        # `-i ''` is the BSD form; GNU sed wants `-i` with no argument, hence
        # the temp file instead of either.
        sed "s/$OLD_ID/$ID/g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
        echo "  $f"
    done

# The display name only lives in the manifest, so it is replaced separately.
sed "s/^name = \"Noro Module Template\"/name = \"$NAME\"/" manifest.toml > manifest.tmp
mv manifest.tmp manifest.toml

echo
echo "renamed to $ID (\"$NAME\")"
echo "next: ./scripts/build.sh"
