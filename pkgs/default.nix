{ pkgs
, inputs
, myLib
}:
with pkgs;
with lib;
let
  myCallPackage = (makeScope callPackageWith
    (self: {
      inherit myLib inputs pkgs lib;
      inherit (self) callPackage;
      inherit (pkgs) system;
    })).callPackage;
  # exclude from `all`
  exclude = d: {
    excluded = true;
    derivation = d;
  };
  # if the package name is the same as the input name
  getByName = name:
    let
      packages = inputs.${name}.packages.${pkgs.system};
    in
    if builtins.hasAttr name packages
    then packages.${name}
    else packages.default;
in
rec {
  crt = getByName "crt";
  gripper = getByName "gripper";
  hyprlock = getByName "hyprlock";
  keymapper = myCallPackage ./keymapper { };
  lexurgy = callPackage ./lexurgy { };
  odin = exclude (callPackage ./odin { });
  odin-nightly = callPackage ./odin { nightly = true; };
  ols = myCallPackage ./ols { odin = odin-nightly; src = inputs.ols; };
  waybar = myCallPackage ./waybar { };
}
