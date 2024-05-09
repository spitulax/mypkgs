{ pkgs }:
pkgs.keymapper.overrideAttrs (newAttrs: oldAttrs: {
  version = "4.2.0";
  src = pkgs.fetchFromGitHub {
    owner = "houmain";
    repo = "keymapper";
    rev = newAttrs.version;
    hash = "sha256-vissxbl+vFLGlbXVB2nWEnbzET0yAvtc5sInsESfrjQ=";
  };
  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ (with pkgs; [
    gtk3
    libappindicator
  ]);
})
