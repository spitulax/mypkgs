{ pkgs
, src
}:
pkgs.odin.overrideAttrs (newAttrs: oldAttrs: {
  version = "dev-2024-06" + "_" + (src.shortRev or "dirty");
  inherit src;
})
