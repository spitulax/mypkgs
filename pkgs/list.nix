{ callPackage
, getByName
, getByName'
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
  crt = getByName' "crt";
  gplates = callPackage ./gplates { };
  gripper = getByName "gripper";
  hunspell-id = callPackage ./hunspell-id { };
  hyprlock = getByName "hyprlock";
  hyprpaper = getByName "hyprpaper";
  hyprpicker = getByName "hyprpicker";
  hyprpolkitagent = getByName "hyprpolkitagent";
  hyprswitch = getByName "hyprswitch";
  keymapper = callPackage ./keymapper { };
  lexurgy = callPackage ./lexurgy { };
  musializer = getByName' "musializer";
  odin = unmaintain (uncache (callPackage ./odin { }));
  odin-doc = callPackage ./odin-doc { odin = odin-git; };
  odin-git = callPackage ./odin-git { };
  odin-nightly = unmaintain (uncache (callPackage ./odin-nightly { }));
  ols = callPackage ./ols { odin = odin-git; };
  osu-lazer = unmaintain (uncache (callPackage ./osu-lazer { }));
  pasteme = getByName "pasteme";
  waybar = unmaintain (callPackage ./waybar { });
  whitesur-cursors = callPackage ./whitesur-cursors { };
}
