{ pkgs }:
pkgs.keymapper.overrideAttrs (newAttrs: oldAttrs: {
  version = "4.9.1";
  src = pkgs.fetchFromGitHub {
    owner = "houmain";
    repo = "keymapper";
    rev = newAttrs.version;
    hash = "sha256-i/iAOj2fdC4XeC3XbQU0BPoY36Ccva5YaYIvDdrmCD8=";
  };
})
