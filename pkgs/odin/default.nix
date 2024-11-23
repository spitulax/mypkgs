{ stdenv
, lib
, fetchzip
, makeWrapper
, pkgs
, odin

, nightly ? false
}:
let
  llvmPackages = pkgs.llvmPackages_latest;

  releaseVersion = "0.dev-2024-08";
  releaseHash = "sha256-viGG/qa2+XhQvTXrKaER5SwszMELi5dHG0lWD26pYfY=";

  nightlyVersion = "2024-11-22";
  nightlyUrl = "https://f001.backblazeb2.com/file/odin-binaries/nightly/odin-linux-amd64-nightly%2B2024-11-22.tar.gz";
  nightlyHash = "sha256-zLYWNkXHXBustCYB57qJ9ABnnV5YtUwGp/iA7r0j+T8=";
in
stdenv.mkDerivation (newAttrs: rec {
  pname = "odin" + (lib.optionalString nightly "-nightly");
  version = if nightly then nightlyVersion else releaseVersion;
  src =
    if nightly
    then
      fetchzip
        {
          url = nightlyUrl;
          sha256 = nightlyHash;
        }
    else
      fetchzip
        {
          url = "https://github.com/odin-lang/Odin/releases/download/${lib.removePrefix "0." version}/odin-ubuntu-amd64-dev-2024-07.zip";
          hash = releaseHash;
        }
  ;

  nativeBuildInputs = [
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    cd vendor/stb/src
    make
    cd ../../..

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mv odin $out/bin/odin

    mkdir -p $out/share
    mv base $out/share/base
    mv core $out/share/core
    mv vendor $out/share/vendor
    mv shared $out/share/shared

    wrapProgram $out/bin/odin \
      --prefix PATH : ${lib.makeBinPath (with llvmPackages; [
        bintools
        llvm
        clang
        lld
      ])} \
      --set-default ODIN_ROOT $out/share

    runHook postInstall
  '';

  meta = odin.meta // {
    maintainers = with lib.maintainers; [ spitulax ];
  };
})
