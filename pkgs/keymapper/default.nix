{ pkgs }:
pkgs.keymapper.overrideAttrs (newAttrs: oldAttrs: {
  version = "4.8.2";
  src = pkgs.fetchFromGitHub {
    owner = "houmain";
    repo = "keymapper";
    rev = newAttrs.version;
    hash = "sha256-4LYGsqHD3msJNgkaInJyH7o+jebeQoh/rUAsvIsqkdM=";
  };
})
