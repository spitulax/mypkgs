{ pkgs }:
pkgs.keymapper.overrideAttrs (newAttrs: oldAttrs: {
  version = "4.3.0";
  src = pkgs.fetchFromGitHub {
    owner = "houmain";
    repo = "keymapper";
    rev = newAttrs.version;
    hash = "sha256-QfISsRm0j/VoTmpDQes5XQooXHcmjqRD/WS/nvPDl00=";
  };
  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ (with pkgs; [
    gtk3
    libappindicator
  ]);
})
