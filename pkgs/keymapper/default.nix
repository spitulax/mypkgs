{ pkgs }:
pkgs.keymapper.overrideAttrs (newAttrs: oldAttrs: {
  version = "4.3.1";
  src = pkgs.fetchFromGitHub {
    owner = "houmain";
    repo = "keymapper";
    rev = newAttrs.version;
    hash = "sha256-SjYPkcXBEHjK7zgwL6U4ltjvhKuGMZWbp55LtndU400=";
  };
  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ (with pkgs; [
    gtk3
    libayatana-appindicator
  ]);
})
