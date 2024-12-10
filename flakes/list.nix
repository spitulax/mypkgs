{ callPackage
, ...
}:
{
  # KEEP THE LIST ALPHABETICALLY SORTED!
  crt = callPackage ./crt { };
  gripper = callPackage ./gripper { };
  waybar = callPackage ./waybar { };
}

