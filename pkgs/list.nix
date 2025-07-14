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
  gplates = uncache (callPackage ./gplates { });
  gripper = getByName "gripper";
  hunspell-id = callPackage ./hunspell-id { };
  hyprlock = getByName "hyprlock";
  hyprpaper = getByName "hyprpaper";
  hyprpicker = getByName "hyprpicker";
  hyprpolkitagent = getByName "hyprpolkitagent";
  keymapper = unmaintain (uncache (callPackage ./keymapper { }));
  lexurgy = callPackage ./lexurgy { };
  odin = unmaintain (uncache (callPackage ./odin { }));
  odin-doc = unmaintain (uncache (callPackage ./odin-doc { odin = odin-git; }));
  odin-git = unmaintain (uncache (callPackage ./odin-git { }));
  odin-nightly = unmaintain (uncache (callPackage ./odin-nightly { }));
  ols = unmaintain (uncache (callPackage ./ols { odin = odin-git; }));
  osu-lazer = unmaintain (uncache (callPackage ./osu-lazer { }));
  pasteme = getByName "pasteme";
  waybar = unmaintain (callPackage ./waybar { });
  whitesur-cursors = callPackage ./whitesur-cursors { };
}
