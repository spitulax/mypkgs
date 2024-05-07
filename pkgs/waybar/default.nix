{ inputs
, pkgs
}: inputs.waybar.packages.${pkgs.system}.waybar.override {
  pkgs = pkgs // {
    overlays = [
      (final: prev: {
        waybar = prev.waybar.override {
          swaySupport = false;
        };
      })
    ];
  };
}
