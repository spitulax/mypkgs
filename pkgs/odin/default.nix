{ pkgs
, src
, myLib
}:
pkgs.odin.overrideAttrs (newAttrs: oldAttrs: {
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
