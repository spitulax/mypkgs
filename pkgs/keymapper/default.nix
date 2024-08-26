{ pkgs }:
pkgs.keymapper.overrideAttrs (newAttrs: oldAttrs: {
  version = "4.7.2";
  src = pkgs.fetchFromGitHub {
    owner = "houmain";
    repo = "keymapper";
    rev = newAttrs.version;
    hash = "sha256-G8sSconiREMiNCZ7R5L4onZpaue967eI1BXTCG9xi/I=";
  };
})
