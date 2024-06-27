{ pkgs }:
pkgs.keymapper.overrideAttrs (newAttrs: oldAttrs: {
  version = "4.4.1";
  src = pkgs.fetchFromGitHub {
    owner = "houmain";
    repo = "keymapper";
    rev = newAttrs.version;
    hash = "sha256-pM273Ma8ELFVQV8zxCmtEvhBz5HLiIBtPtRv9Hh5dGY=";
  };
})
