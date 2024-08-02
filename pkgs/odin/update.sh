#!/usr/bin/env bash

META=$(curl -s https://odinbinaries.thisdrunkdane.io/file/odin-binaries/nightly.json | jq -r '.files | to_entries | last | .value | .[2]')
VERSION=$(echo $META | jq -r '.name' | sed -r 's/^.*\+(.*)\.zip/\1/')
URL=$(echo $META | jq -r '.url')
HASH=$(nix flake prefetch "$URL" --json | jq -r '.hash')

replace () {
    sed -r -e "s/(^ *$1 = \").*(\";)/\1$2\2/" -i pkgs/odin/default.nix
}

escape () {
    echo "$1" | sed -e 's/[\/&]/\\&/g'
}

replace "nightlyVersion" "$VERSION"
replace "nightlyUrl" $(escape "$URL")
replace "nightlyHash" $(escape "$HASH")
