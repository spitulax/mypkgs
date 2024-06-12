{ pkgs }:
pkgs.keymapper.overrideAttrs (newAttrs: oldAttrs: {
  version = "4.4.0";
  src = pkgs.fetchFromGitHub {
    owner = "houmain";
    repo = "keymapper";
    rev = newAttrs.version;
    hash = "sha256-NB9sVSkd01lm9Ia8fGrnICjD1cNdPfcvJ++Yy3NO5QQ=";
  };
  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ (with pkgs; [
    libayatana-appindicator
  ]);
})
