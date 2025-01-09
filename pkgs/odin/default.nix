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
in
(callPackage myLib.helpers.odinDerivation { }).override {
  pname = "odin";
  pkg = mkPkg {
    inherit (pkg') version updateScript dirname;
    # For some unknown reason, inside the .zip file is another archive (.tar.gz) file
    src = archiveTools.extractTarGz {
      inherit (pkg') src;
      flatten = true;
    };
  };
}
