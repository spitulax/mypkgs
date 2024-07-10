{ system
, myLib
, src
, ...
}:
src.packages.${system}.zls.overrideAttrs (newAttrs: oldAttrs: {
  name = "zls-" + newAttrs.version;
  version = myLib.mkNightlyVersion src;
})
