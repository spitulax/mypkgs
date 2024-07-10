{ pkgs }:
pkgs.keymapper.overrideAttrs (newAttrs: oldAttrs: {
  version = "4.4.2";
  src = pkgs.fetchFromGitHub {
    owner = "houmain";
    repo = "keymapper";
    rev = newAttrs.version;
    hash = "sha256-JMDUsWjzqe7JaOqowMmgG3sVJt54YSM75uS9TeF7bsc=";
  };
})
