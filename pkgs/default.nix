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
  odin = myCallPackage ./odin { src = inputs.odin; };
  ols = myCallPackage ./ols { inherit odin; src = inputs.ols; };
  waybar = myCallPackage ./waybar { };
}
