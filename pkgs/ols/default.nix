{ stdenv
, lib
, src
, odin
, makeWrapper
, myLib
}:

stdenv.mkDerivation {
  pname = "ols";
  version = "master+date=" + (myLib.mkDate (src.lastModifiedDate or "19700101")) + "_" + (src.shortRev or "dirty");

  inherit src;

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    odin
  ];

  patchPhase = ''
    patchShebangs ./build.sh ./odinfmt.sh
  '';

  buildPhase = ''
    ./build.sh && ./odinfmt.sh
  '';

  installPhase = ''
    install -Dm755 ols odinfmt -t $out/bin
    wrapProgram $out/bin/ols --set-default ODIN_ROOT ${odin}/share
  '';

  meta = with lib; {
    inherit (odin.meta) platforms;
    description = "Language server for Odin";
    mainProgram = [ "ols" "odinfmt" ];
    homepage = "https://github.com/DanielGavin/ols";
    license = licenses.mit;
    maintainers = with maintainers; [ spitulax ];
  };
}
