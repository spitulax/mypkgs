#!/usr/bin/env bash

META=$(curl https://odinbinaries.thisdrunkdane.io/file/odin-binaries/nightly.json | jq -r '.files | to_entries | last | .value | .[2]')
VERSION=$(echo $META | jq -r '.name' | sed -r 's/^.*\+(.*)\.zip/\1/')
URL=$(echo $META | jq -r '.url')
SHA256=$(nix-prefetch-url --name source --unpack "$URL" | tail -n 1)

replace () {
    sed -r -e "s/(^ *$1 = \").*(\";)/\1$2\2/" -i pkgs/odin/default.nix
}

escape () {
    echo "$1" | sed -e 's/[\/&]/\\&/g'
}

replace "nightlyVersion" "$VERSION"
replace "nightlyUrl" $(escape "$URL")
replace "nightlySha256" "$SHA256"
