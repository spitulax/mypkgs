{ pkgs
, src
, myLib
}:
(pkgs.odin.override {
  llvmPackages_13 = pkgs.llvmPackages;
}).overrideAttrs (newAttrs: oldAttrs: {
  version = myLib.mkNightlyVersion src;
  inherit src;

  buildFlags = [ "nightly" ];

  preBuild = ''
    cd vendor/stb/src
    make
    cd ../../..
  '';

  postInstall = ''
    cp -r shared $out/share/shared
  '';
})
