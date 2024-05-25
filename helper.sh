#!/usr/bin/env bash

case "$1" in
"update")
  printf '\033[1mUpdating flake inputs...\n'
  nix flake update --accept-flake-config
;;

"build")
  nix build .#all --accept-flake-config
;;

"push-inputs")
  printf '\033[1mPushing inputs to cachix...\n'
  nix flake archive --accept-flake-config --json \
    | jq -r '.path,(.inputs|to_entries[].value.path)' \
    | cachix push spitulax
;;

"push-pkgs")
printf '\033[1mBuilding packages...\n'
nix build .#all --accept-flake-config --json \
  | jq -r '.[].outputs | to_entries[].value' \
  | cachix push spitulax
;;
esac
