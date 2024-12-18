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
    foldr
    hasSuffix
    optionalString
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

  getPkgDataPath = dirname: append ./../pkgs (dirname + "/pkg.json");
  getPkgData = dirname: lib.trivial.importJSON (getPkgDataPath dirname);
  getFlakeDataPath = dirname: append ./../flakes (dirname + "/flake.json");
  getFlakeData = dirname: lib.trivial.importJSON (getFlakeDataPath dirname);

  # Prefetch-url `--unpack` flag can unpack zip and tar along with all supported filters from libarchive
  # https://github.com/NixOS/nix/blob/3f3feae33e3381a2ea5928febe03329f0a578b20/src/libutil/tarfile.cc#L109
  # https://github.com/libarchive/libarchive/blob/819a50a0436531276e388fc97eb0b1b61d2134a3/libarchive/archive_read_support_filter_all.c#L41
  isArchive = name:
    foldr (a: b: hasSuffix a name || b) false [
      ".zip"
      ".tar"
      ".tar.bz2"
      ".tar.gz"
      ".tgz"
      ".tar.lz"
      ".tlz"
      ".tar.lz4"
      ".tar.lzma"
      ".tar.xz"
      ".txz"
      ".tar.Z"
      ".tar.lzo"
      ".tar.zst"
    ];

  drv = rec {
    isCached = d: !(d ? _notCached && d._notCached);
    uncached = ds: filterAttrs (_: v: !isCached v) ds;
    cached = ds: filterAttrs (_: isCached) ds;
    isMaintained = d: !(d ? _notMaintained && d._notMaintained);
    unmaintained = ds: filterAttrs (_: v: !isMaintained v) ds;
    maintained = ds: filterAttrs (_: isMaintained) ds;
    uncache = d: d // { _notCached = true; };
    unmaintain = d: d // { _notMaintained = true; };
    ignore = d: d // { _notCached = true; _notMaintained = true; };
  };

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

    getFileHash =
      nix:
      jq:
      { url
      , archive ? null
      , executable ? false
      }:
      let
        archive' =
          if archive == null
          then isArchive url
          else archive;
      in
      "${importJSON jq (
        "$(${nixCmd nix} store prefetch-file --json --name source "
        + (optionalString archive' "--unpack ")
        + (optionalString executable "--executable ")
        + "\"${url}\")"
      )
      ".hash"}";

    echo = val:
      "echo \"${val}\"";
  };
}

