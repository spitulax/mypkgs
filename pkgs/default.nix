{ pkgs
, inputs
}: with pkgs;
let
  # if the package name is the same as the input name
  getByName = name: inputs.${name}.packages.${pkgs.system}.${name};
in
{
  hyprlock = getByName "hyprlock";
  keymapper = callPackage ./keymapper { inherit pkgs; };
  lexurgy = callPackage ./lexurgy { };
  waybar = callPackage ./waybar { inherit inputs pkgs; };
}
