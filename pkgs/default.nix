{ pkgs
, inputs
, myLib
}: with pkgs;
let
  # if the package name is the same as the input name
  getByName = name: inputs.${name}.packages.${pkgs.system}.${name};
in
rec {
  crt = getByName "crt";
  gripper = getByName "gripper";
  hyprlock = getByName "hyprlock";
  keymapper = callPackage ./keymapper { inherit pkgs; };
  lexurgy = callPackage ./lexurgy { };
  odin = callPackage ./odin { inherit pkgs; src = inputs.odin; };
  ols = callPackage ./ols { inherit myLib odin; src = inputs.ols; };
  waybar = callPackage ./waybar { inherit inputs pkgs; };
}
