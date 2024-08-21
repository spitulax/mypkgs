{ pkgs }:
pkgs.keymapper.overrideAttrs (newAttrs: oldAttrs: {
  version = "4.7.1";
  src = pkgs.fetchFromGitHub {
    owner = "houmain";
    repo = "keymapper";
    rev = newAttrs.version;
    hash = "sha256-fpXFjvxN1krViBE45her0sgAMzcaubx6TneDGg07BTE=";
  };
})
