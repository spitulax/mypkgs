{ pkgs }:
pkgs.keymapper.overrideAttrs (newAttrs: oldAttrs: {
  version = "4.4.4";
  src = pkgs.fetchFromGitHub {
    owner = "houmain";
    repo = "keymapper";
    rev = newAttrs.version;
    hash = "sha256-TAMDnJYiFRUidYvsrMIJG/ple+eY8bL8HF+bGwh9+X8=";
  };
})
