{ pkgs }:
pkgs.keymapper.overrideAttrs (newAttrs: oldAttrs: {
  version = "4.9.0";
  src = pkgs.fetchFromGitHub {
    owner = "houmain";
    repo = "keymapper";
    rev = newAttrs.version;
    hash = "sha256-GckqlKpF1N7Khq/9ju1IG1+jfPBuWhFAHhYnlCMC5Cw=";
  };
})
