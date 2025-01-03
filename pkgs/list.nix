{ callPackage
, getByName
, myLib
, ...
}:
let
  inherit (myLib.drv)
    unmaintain
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
  hyprswitch = getByName "hyprswitch";
  keymapper = callPackage ./keymapper { };
  lexurgy = callPackage ./lexurgy { };
  musializer = getByName "musializer";
  odin = uncache (callPackage ./odin { });
  odin-doc = callPackage ./odin-doc { odin = odin-nightly; };
  odin-git = unmaintain (uncache (callPackage ./odin-git { }));
  odin-nightly = callPackage ./odin-nightly { };
  ols = callPackage ./ols { odin = odin-nightly; };
  osu-lazer = uncache (callPackage ./osu-lazer { });
  pasteme = getByName "pasteme";
  waybar = callPackage ./waybar { };
}
