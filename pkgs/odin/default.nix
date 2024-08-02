{ stdenv
, lib
, fetchzip
, makeWrapper
, autoPatchelfHook
, patchelf
, pkgs
, odin
, unzip

, nightly ? false
}:
let
  releaseLlvmVersion = "17";
  nightlyLlvmVersion = "18";

  llvmVersion = if nightly then nightlyLlvmVersion else releaseLlvmVersion;
  llvmPackages = pkgs."llvmPackages_${llvmVersion}";

  releaseVersion = "0.dev-2024-07";

  nightlyVersion = "2024-08-01";
  nightlyUrl = "https://f001.backblazeb2.com/file/odin-binaries/nightly/odin-ubuntu-amd64-nightly%2B2024-08-01.zip";
  nightlySha256 = "1xk1m5p0ymj93d3rg2qbq762qb7526hjksrmpm87iydnlvz8c8dy";
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
          sha256 = nightlySha256;
        }
    else
      fetchzip
        {
          url = "https://github.com/odin-lang/Odin/releases/download/${lib.removePrefix "0." version}/odin-ubuntu-amd64-dev-2024-07.zip";
          hash = "sha256-jUyG/8FGm6sgPRRKnram4UD/rNUHycuCDRbP99PjciY=";
        }
  ;

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
    patchelf
    unzip
  ];

  buildInputs = [
    llvmPackages.libllvm
  ];

  dontConfigure = nightly;

  configurePhase = ''
    runHook preConfigure
    
    unzip dist.zip
    mv dist/* .
    rmdir dist

    runHook postConfigure
  '';

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

    patchelf --replace-needed libLLVM-${llvmVersion}.so.${llvmVersion}.1 libLLVM-${llvmVersion}.so $out/bin/odin
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
