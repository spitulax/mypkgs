{ pkgs }:
pkgs.keymapper.overrideAttrs (newAttrs: oldAttrs: {
  version = "4.6.0";
  src = pkgs.fetchFromGitHub {
    owner = "houmain";
    repo = "keymapper";
    rev = newAttrs.version;
    hash = "sha256-xHnCRn7fGo46T5rs9BtvEAEdxCY08zDTUipbbl6OUlU=";
  };
})
