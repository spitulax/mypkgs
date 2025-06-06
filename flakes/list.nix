{ callPackage
, ...
}: {
  # KEEP THE LIST ALPHABETICALLY SORTED!
  crt = callPackage ./crt { };
  gripper = callPackage ./gripper { };
  hyprlock = callPackage ./hyprlock { };
  hyprpaper = callPackage ./hyprpaper { };
  hyprpicker = callPackage ./hyprpicker { };
  hyprpolkitagent = callPackage ./hyprpolkitagent { };
  hyprshell = callPackage ./hyprshell { };
  musializer = callPackage ./musializer { };
  pasteme = callPackage ./pasteme { };
  waybar = callPackage ./waybar { };
}

