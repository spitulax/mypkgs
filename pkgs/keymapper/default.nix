{ pkgs
, gitHubPkg
}:
pkgs.keymapper.overrideAttrs
  (gitHubPkg {
    owner = "houmain";
    repo = "keymapper";
  })
