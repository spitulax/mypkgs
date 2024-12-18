{ callPackage
, getByName
, myLib
, ...
}:
let
  inherit (myLib.drv)
    uncache
    ;
in
rec {
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
  odin = uncache (callPackage ./odin { });
  odin-nightly = callPackage ./odin-nightly { };
  ols = callPackage ./ols { odin = odin-nightly; };
  osu-lazer = uncache (callPackage ./osu-lazer { });
  pasteme = getByName "pasteme";
  waybar = callPackage ./waybar { };
}
