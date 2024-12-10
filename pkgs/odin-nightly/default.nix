{ lib
, myLib
, curl
, callPackage
, fetchzip
, writeShellScript
, jq
, gnused
, nix
, mkPkg
, exitIfNoNewVer
}:
let
  inherit (lib)
    toShellVar
    getExe
    replaceStrings
    ;

  inherit (myLib)
    getPkgData
    shell
    ;

  inherit (shell)
    echo
    ;

  importJSON = shell.importJSON jq;
  serialiseJSON = shell.serialiseJSON jq;
  getFileHash = shell.getFileHash nix jq;

  dirname = "odin-nightly";
  pkgData = getPkgData dirname;
  inherit (pkgData) version;

  src = fetchzip {
    inherit (pkgData) url hash;
  };

  updateScript = writeShellScript dirname ''
    set -euo pipefail

    ${toShellVar "CURL" (getExe curl)}
    ${toShellVar "SED" (getExe gnused)}

    META=${importJSON "$($CURL -s 'https://odinbinaries.thisdrunkdane.io/file/odin-binaries/nightly.json')" ".files | to_entries | last | .value | .[0]"}
    VERSION=$(${echo (importJSON "$META" ".name")} | $SED -r 's/^.*\+(.*)\.tar\.gz$/\1/')
    ${exitIfNoNewVer "$VERSION"}
    URL=${importJSON "$META" ".url"}
    HASH=${getFileHash "$URL"}

    ${serialiseJSON {
      version = "$VERSION";
      url = "$URL";
      hash = "$HASH";
    }}
  '';
in
(callPackage myLib.helpers.odinDerivation { }).override {
  pname = "odin-nightly";
  pkg = mkPkg {
    inherit src updateScript dirname version;
  };
}
