{ pkgs }:
pkgs.keymapper.overrideAttrs (newAttrs: oldAttrs: {
  version = "4.5.2";
  src = pkgs.fetchFromGitHub {
    owner = "houmain";
    repo = "keymapper";
    rev = newAttrs.version;
    hash = "sha256-qBYezQdm1ZKSB+eylJYxiP891t77sA4I9IlTAsfDyC4=";
  };
})
