{ pkgs
, inputs
}: with pkgs; {
  lexurgy = callPackage ./lexurgy { };
  waybar = callPackage ./waybar { inherit inputs pkgs; };
}
