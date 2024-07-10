{ pkgs
, inputs
, callPackage
, lib
}:
inputs.zig-overlay.packages.${pkgs.system}.master.overrideAttrs (newAttrs: oldAttrs: {
  outputs = [ "out" "doc" ];

  env.ZIG_GLOBAL_CACHE_DIR = "$TMPDIR/zig-cache";
  postPatch = ''
    substituteInPlace lib/std/zig/system.zig \
      --replace "/usr/bin/env" "${lib.getExe' pkgs.coreutils "env"}"
  '';

  installPhase = ''
    mkdir -p $out/{bin,lib}
    mkdir -p $doc
    cp -r lib/* $out/lib
    cp zig $out/bin/zig
    install -Dm444 doc/langref.html -t $doc/share/doc/zig-${newAttrs.version}/html
  '';

  passthru.hook =
    callPackage (inputs.nixpkgs + "/pkgs/development/compilers/zig/0.13/hook.nix")
      { inherit (pkgs) makeSetupHook; zig = newAttrs.finalPackage; };

  inherit (pkgs.zig) meta;
})
