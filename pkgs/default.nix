{ pkgs
, inputs
, myLib
}:
let
  inherit (pkgs)
    lib
    ;

  inherit (lib)
    makeScope
    callPackageWith
    ;

  utils = pkgs.callPackage ../utils { inherit myLib; };

  inherit (makeScope callPackageWith
    (self: {
      inherit myLib inputs pkgs lib utils;
      inherit (self) callPackage;
      inherit (pkgs) system;
    } // pkgs // utils)) callPackage;

  # Exclude from `all`
  exclude = d: {
    excluded = true;
    derivation = d;
  };

  # If the package name is the same as the input name
  getByName = name:
    let
      packages = inputs.${name}.packages.${pkgs.system};
    in
    if builtins.hasAttr name packages
    then packages.${name}
    else packages.default;

  packages = rec {
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
    odin = callPackage ./odin { };
    odin-nightly = callPackage ./odin-nightly { };
    ols = callPackage ./ols { odin = odin-nightly; };
    pasteme = getByName "pasteme";
    waybar = callPackage ./waybar { };
  };
in
packages // {
  update-scripts = utils.updateScripts (myLib.includedPackages packages);
}
