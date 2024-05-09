{ pkgs
, inputs
}: with pkgs;
let
  # [pkgs] -> {pkg_name = pkg; ...}
  redefine = packages: builtins.listToAttrs
    (builtins.map
      (p: { name = p.pname; value = p; })
      packages);

  getByName = name: inputs.${name}.packages.${pkgs.system}.${name};
in
{
  lexurgy = callPackage ./lexurgy { };
  waybar = callPackage ./waybar { inherit inputs pkgs; };
  keymapper = callPackage ./keymapper { inherit pkgs; };
} // redefine [
  (getByName "hyprlock")
]
