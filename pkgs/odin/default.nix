{ myLib
, gitHubReleasePkg
, callPackage
, archiveTools
, mkPkg
}:
let
  pkg' = gitHubReleasePkg {
    owner = "odin-lang";
    repo = "odin";
    assetName = "odin-ubuntu-amd64-%V.zip";
    useReleaseName = true;
    prefixVersion = true;
  };
  inherit (pkg') version;
  inherit (pkg'.passthru) dirname;
  updateScript = pkg'.passthru.mypkgsUpdateScript;
in
callPackage myLib.helpers.odinDerivation {
  pname = "odin";
  pkg = mkPkg {
    inherit version dirname updateScript;
    # For some unknown reason, inside the .zip file is another archive (.tar.gz) file
    src = archiveTools.extractTarGz {
      inherit (pkg') src;
      flatten = true;
    };
  };
}
