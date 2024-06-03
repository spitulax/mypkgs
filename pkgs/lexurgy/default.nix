{ stdenvNoCC
, fetchurl
, makeWrapper
, jre_minimal
, jdk
, lib
}:
stdenvNoCC.mkDerivation rec {
  pname = "lexurgy";
  version = "1.7.0";

  src = fetchurl {
    url = "https://github.com/def-gthill/lexurgy/releases/download/v${version}/lexurgy-${version}.tar";
    hash = "sha256-/UOpvtbyAnbAsbgAqNrSLFRmbQwHae3ExZYtBesA/jc=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ jre_minimal ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    mv * $out
    rm $out/bin/*.bat
    wrapProgram $out/bin/lexurgy \
      --set JAVA_HOME ${jre_minimal.home}
  '';

  meta = {
    inherit (jdk.meta) platforms;
    description = "A high-powered sound change applier";
    mainProgram = "lexurgy";
    homepage = "https://github.com/def-gthill/lexurgy";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ spitulax ];
  };
}
