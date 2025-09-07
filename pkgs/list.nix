{ callPackage
, getByName
, getByName'
, myLib
, ...
}:
let
  inherit (myLib.drv)
    uncache
    ignore
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
  lexurgy = callPackage ./lexurgy { };
  odin = ignore (callPackage ./odin { });
  odin-doc = ignore (callPackage ./odin-doc { odin = odin-git; });
  odin-git = ignore (callPackage ./odin-git { });
  odin-nightly = ignore (callPackage ./odin-nightly { });
  ols = ignore (callPackage ./ols { odin = odin-git; });
  osu-lazer = ignore (callPackage ./osu-lazer { });
  pasteme = getByName "pasteme";
  quickshell = getByName' "quickshell";
  rose-pine-tmux = callPackage ./rose-pine-tmux { };
  waybar = ignore (callPackage ./waybar { });
  whitesur-cursors = callPackage ./whitesur-cursors { };
}
