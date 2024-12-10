{ myLib
, gitHubReleasePkg
, callPackage
}:
(callPackage myLib.helpers.odinDerivation { }).override {
  pname = "odin";
  pkg = gitHubReleasePkg {
    owner = "odin-lang";
    repo = "odin";
    assetName = "odin-linux-amd64-%V.tar.gz";
    useReleaseName = true;
    prefixVersion = true;
  };
}
