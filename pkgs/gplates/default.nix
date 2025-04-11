{ gplates
, makeDesktopItem
, fetchurl
, utils
, symlinkJoin
}:
let
  iconDrv = utils.archiveTools.extractZip {
    src = fetchurl {
      # Update scripts?
      # This should not change THAT frequently
      url = "https://www.earthbyte.org/webdav/ftp/earthbyte/GPlates_logo.zip";
      hash = "sha256-xgExVQFw3IKDHaojwsoJuoC4Z5DjA3cuKZtmHfE1t9E=";
    };
  };

  desktopItem = makeDesktopItem {
    name = "gplates";
    desktopName = "GPlates";
    comment = "Plate tectonics program";
    exec = "${gplates}/bin/gplates %U";
    icon = "${iconDrv}/newlogo.svg";
  };
in
symlinkJoin {
  pname = "gplates";
  inherit (gplates) version meta;
  paths = [
    gplates
    desktopItem
  ];
}
