{ lib
, myLib
, outputs
, pkgs
, curl
, jq
, writeShellScript
, fetchFromGitHub
, nix
, coreutils
, fetchzip
, runCommand
, gnused
}:
let
  inherit (builtins)
    toString
    ;

  inherit (lib)
    getExe
    replaceStrings
    toShellVar
    ;

  inherit (myLib)
    shell
    getPkgData
    getFlakeData
    ;

  serialiseJSON = shell.serialiseJSON jq;
  importJSON = shell.importJSON jq;
  getFileHash = shell.getFileHash nix jq;
in
rec {
  getFlake = name:
    outputs.flakes.${pkgs.system}.${name}.flake;
  getFlakePackage = flake: name:
    flake.packages.${pkgs.system}.${name};
  getFlakePackage' = flakeName: pkgName:
    (getFlake flakeName).packages.${pkgs.system}.${pkgName};
  getFlakePackages = flake:
    flake.packages.${pkgs.system};
  getFlakePackages' = flakeName:
    (getFlake flakeName).packages.${pkgs.system};

  # NOTE: *VersionScript should accept the previous version (for *Pkg) or rev (for *Flake) as an argument ($1) and add this.
  # NOTE: Any custom update script that doesn't call *VersionScript must also add this.

  exitIfNoNewVer = ver: ''
    if [ "$FORCE" -ne 1 ]; then
      [ "${ver}" = "$1" ] && exit 1
    fi
  '';

  gitHubVersionScript =
    { owner
    , repo
    , ref ? "" # empty means fetch latest release
    , dirname ? repo
    , ...
    }:
    let
      # FIXME: Pre-releases are always included
      # FIXME: `target_commitish` is not always a commit hash.
      # It's more reliable to get the commit hash from the tag's name
      # https://stackoverflow.com/questions/67040794/how-can-i-get-the-commit-hash-of-the-latest-release-from-github-api
      updateScript = writeShellScript "mypkgs-update-version-${dirname}" ''
        set -euo pipefail

        ${toShellVar "CURL" (getExe curl)}
        ${toShellVar "SED" (getExe gnused)}
        ${toShellVar "DATE" "${coreutils}/bin/date"}
        ${toShellVar "HEAD" "${coreutils}/bin/head"}

        if [ -z "${ref}" ]; then
          RELEASE_INFO=$($CURL -s 'https://api.github.com/repos/${owner}/${repo}/releases/latest')
          REV=${importJSON "$RELEASE_INFO" ".target_commitish"}
          RELEASE_NAME=${importJSON "$RELEASE_INFO" ".name"}
          VERSION=$(echo "$RELEASE_NAME" | $SED 's/[^1-9]*//')
        else
          COMMIT=$($CURL -s 'https://api.github.com/repos/${owner}/${repo}/commits/${ref}')
          REV=${importJSON "$COMMIT" ".sha"}
          COMMIT_DATE=${importJSON "$COMMIT" ".commit.committer.date"}
          DATE=$($DATE -d "$COMMIT_DATE" --utc '+%Y.%m.%d')
          VERSION=$(printf '%s+%s_%s' "$DATE" "${ref}" "$(echo "$REV" | "$HEAD" -c7)")
        fi

        ${exitIfNoNewVer "$VERSION"}

        ${serialiseJSON {
          rev = "$REV";
          version = "$VERSION";
          release_name = "\${RELEASE_NAME:-}";
        }}
      '';
    in
    updateScript;

  archiveScript =
    { url
    , dirname
    }:
    let
      updateScript = writeShellScript "mypkgs-update-archive-${dirname}" ''
        set -euo pipefail

        URL="${url}"
        HASH=${getFileHash "$URL"}

        ${serialiseJSON {
          url = "$URL";
          hash = "$HASH";
        }}
      '';
    in
    updateScript;

  # NOTE: *Pkg are only expected to be used from somewhere within `/pkgs`
  # NOTE: *Pkg generate `pkg.json`
  # MAYBE: preUpdateScripts or postUpdateScripts

  mkPkg =
    { version
    , src
    , updateScript
    , dirname
    }: {
      inherit version src;
      passthru = {
        inherit dirname;
        mypkgsUpdateScript = updateScript;
      };
    };

  # NOTE: *Pkg should accept the previous version as an argument ($1).
  # When calling *VersionScript, it should pass the argument.
  # NOTE: For *Pkg, storing version in pkg.json is necessary.

  gitHubPkg =
    { owner
    , repo
    , ref ? "" # empty means fetch latest release
    , dirname ? repo
    }@inputs:
    let
      pkgData = getPkgData dirname;
      versionScript = gitHubVersionScript inputs;

      src = fetchFromGitHub {
        inherit owner repo;
        inherit (pkgData) hash rev;
      };

      updateScript = writeShellScript "mypkgs-update-github-${dirname}" ''
        set -euo pipefail

        VERSIONDATA=$(${versionScript} "$1")
        REV=${importJSON "$VERSIONDATA" ".rev"}
        VERSION=${importJSON "$VERSIONDATA" ".version"}
        HASH=${getFileHash "https://github.com/${owner}/${repo}/archive/\${REV}.tar.gz"}

        ${serialiseJSON {
          hash = "$HASH";
          rev = "$REV";
          version = "$VERSION";
        }}
      '';
    in
    mkPkg {
      inherit (pkgData) version;
      inherit src updateScript dirname;
    };

  gitHubReleasePkg =
    { owner
    , repo
      # "%v" will be replaced by the version (without any non-digit prefix)
      # "%V" will be replaced by the release name
    , assetName
    , dirname ? repo
    , prefixVersion ? false # Prefix the version with "0."
    , useReleaseName ? false # Use the full release name for the version
    }@inputs:
    let
      pkgData = getPkgData dirname;
      versionScript = gitHubVersionScript inputs;
      inherit (pkgData) version;

      shAssetName = replaceStrings [ "%V" "%v" ] [ "\${1}" "\${2}" ] assetName;
      hashScript = archiveScript {
        inherit dirname;
        url = "https://github.com/${owner}/${repo}/releases/download/\${1}/${shAssetName}";
      };

      src = fetchzip {
        inherit (pkgData) hash url;
      };

      updateScript = writeShellScript "mypkgs-update-githubrelease-${dirname}" ''
        set -euo pipefail

        VERSIONDATA=$(${versionScript} "$1")
        [ $? -eq 1 ] && exit 1
        VERSION=${importJSON "$VERSIONDATA" ".version"}
        RELEASE_NAME=${importJSON "$VERSIONDATA" ".release_name"}
        ARCHIVEDATA=$(${hashScript} "$RELEASE_NAME" "$VERSION")
        HASH=${importJSON "$ARCHIVEDATA" ".hash"}
        URL=${importJSON "$ARCHIVEDATA" ".url"}

        if [ '${toString useReleaseName}' = 1 ]; then
          VERSION="$RELEASE_NAME"
        fi
        if [ '${toString prefixVersion}' = 1 ]; then
          VERSION="0.$VERSION"
        fi

        ${serialiseJSON {
          url = "$URL";
          version = "$VERSION";
          hash = "$HASH";
        }}
      '';
    in
    mkPkg {
      inherit updateScript dirname src version;
    };

  # NOTE: *Flake are only expected to be used from somewhere within `/flakes`
  # NOTE: *Flake generate `flake.json`

  mkFlake =
    { updateScript
    , flake
    , dirname
    }: {
      inherit updateScript dirname flake;
    };

  # NOTE: For *Flake, storing rev in pkg.json is necessary.
  gitHubFlake =
    { owner
    , repo
    , ref ? "" # empty means fetch latest release
    , dirname ? repo
    }@inputs:
    let
      versionScript = gitHubVersionScript inputs;

      # TODO: https://github.com/NixOS/nix/pull/11952 overridable inputs
      flake = builtins.getFlake "github:${owner}/${repo}/${(getFlakeData dirname).rev}";

      updateScript = writeShellScript "mypkgs-update-githubflake-${dirname}" ''
        set -euo pipefail

        VERSIONDATA=$(${versionScript} "$1")
        REV=${importJSON "$VERSIONDATA" ".rev"}
        ${exitIfNoNewVer "$REV"}

        ${serialiseJSON {
          rev = "$REV";
        }}
      '';
    in
    mkFlake {
      inherit updateScript dirname flake;
    };
}

