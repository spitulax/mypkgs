{ pkgs
, src
}:
(pkgs.odin.override {
  llvmPackages_13 = pkgs.llvmPackages_17;
}).overrideAttrs (newAttrs: oldAttrs: {
  version = "dev-2024-06" + "_" + (src.shortRev or "dirty");
  inherit src;

  preBuild = ''
    cd vendor/stb/src
    make
    cd ../../..
  '';
})
