{ callPackage
, getByName
, exclude
, ...
}: rec {
  # KEEP THE LIST ALPHABETICALLY SORTED!
  crt = getByName "crt";
  gripper = getByName "gripper";
  hunspell-id = callPackage ./hunspell-id { };
  hyprlock = getByName "hyprlock";
  hyprpaper = getByName "hyprpaper";
  hyprpicker = getByName "hyprpicker";
  hyprpolkitagent = getByName "hyprpolkitagent";
  keymapper = callPackage ./keymapper { };
  lexurgy = callPackage ./lexurgy { };
  odin = exclude (callPackage ./odin { });
  odin-nightly = callPackage ./odin-nightly { };
  ols = callPackage ./ols { odin = odin-nightly; };
  pasteme = getByName "pasteme";
  waybar = callPackage ./waybar { };
}
