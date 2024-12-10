{ lib }:
let
  inherit (builtins)
    toJSON
    ;

  inherit (lib)
    filterAttrs
    getExe
    concatStringsSep
    escape
    ;
  inherit (lib.path)
    append
    ;
in
rec {
  mkDate = longDate: (concatStringsSep "-" [
    (builtins.substring 0 4 longDate)
    (builtins.substring 4 2 longDate)
    (builtins.substring 6 2 longDate)
  ]);

  mkNightlyVersion = src: mkDate (src.lastModifiedDate or "19700101") + "+rev=" + (src.shortRev or "dirty");

  excludedPackages = packages: filterAttrs (_: v: v.passthru ? excluded && v.passthru.excluded) packages;
  includedPackages = packages: filterAttrs (_: v: !(v.passthru ? excluded) || !v.passthru.excluded) packages;

  getPkgDataPath = dirname: append ./../pkgs (dirname + "/pkg.json");
  getPkgData = dirname: lib.trivial.importJSON (getPkgDataPath dirname);

  helpers = {
    odinDerivation =
      { stdenv
      , makeWrapper
      , llvmPackages_latest
      , odin

      , pkg ? { }
      , pname ? ""
      , llvmPackages ? llvmPackages_latest
      }:
      stdenv.mkDerivation (newAttrs:
      pkg // {
        inherit pname;

        nativeBuildInputs = [
          makeWrapper
        ];

        buildPhase = ''
          runHook preBuild

          cd vendor/stb/src
          make
          cd ../../..

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          mv odin $out/bin/odin

          mkdir -p $out/share
          mv base $out/share/base
          mv core $out/share/core
          mv vendor $out/share/vendor
          mv shared $out/share/shared

          wrapProgram $out/bin/odin \
            --prefix PATH : ${lib.makeBinPath (with llvmPackages; [
              bintools
              llvm
              clang
              lld
            ])} \
            --set-default ODIN_ROOT $out/share

          runHook postInstall
        '';

        meta = odin.meta // {
          maintainers = with lib.maintainers; [ spitulax ];
        };
      });
  };

  shell = rec {
    nixCmd = nix: "${getExe nix} --experimental-features 'nix-command flakes'";

    serialiseJSON = jq: val: "echo \"" + escape [ "\"" ] (toJSON val) + "\" | ${getExe jq} .";

    runScripts = scripts:
      concatStringsSep "\n" (map (x: "${x}") scripts);

    importJSON = jq: json: filt:
      "$(echo \"${json}\" | ${getExe jq} -r \"${filt}\")";

    getFileHash = nix: jq: url:
      "${importJSON jq "$(${nixCmd nix} flake prefetch --json \"${url}\")" ".hash"}";

    echo = val:
      "echo \"${val}\"";
  };
}

