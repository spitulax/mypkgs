{ lib
, stdenv
, makeWrapper
, odin
, gitHubPkg
}:
stdenv.mkDerivation (
  (gitHubPkg {
    owner = "DanielGavin";
    repo = "ols";
    ref = "master";
  }) // {
    pname = "ols";

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
      mainProgram = "ols";
      homepage = "https://github.com/DanielGavin/ols";
      license = licenses.mit;
      maintainers = with maintainers; [ spitulax ];
    };
  }
)
