{ getFlakePackage'
, pkgs
}: (getFlakePackage' "waybar" "waybar").override {
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
