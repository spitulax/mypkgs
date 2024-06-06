{ pkgs
, src
, myLib
}:
(pkgs.odin.override {
  llvmPackages_13 = pkgs.llvmPackages_17;
}).overrideAttrs (newAttrs: oldAttrs: {
  version = myLib.mkNightlyVersion src;
  inherit src;

  buildFlags = [ "nightly" ];

  preBuild = ''
    cd vendor/stb/src
    make
    cd ../../..
  '';
})
