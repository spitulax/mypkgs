{ lib }:
with lib;
rec {
  mkDate = longDate: (concatStringsSep "-" [
    (builtins.substring 0 4 longDate)
    (builtins.substring 4 2 longDate)
    (builtins.substring 6 2 longDate)
  ]);

  mkNightlyVersion = src: mkDate (src.lastModifiedDate or "19700101") + "+rev=" + (src.shortRev or "dirty");
}
