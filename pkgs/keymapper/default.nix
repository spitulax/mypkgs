{ pkgs }:
pkgs.keymapper.overrideAttrs (newAttrs: oldAttrs: {
  version = "4.4.5";
  src = pkgs.fetchFromGitHub {
    owner = "houmain";
    repo = "keymapper";
    rev = newAttrs.version;
    hash = "sha256-G/IQ1QbGoxSEH7oynHL56Oj4T9GDXDZhfd70fSVwCCM=";
  };
})
