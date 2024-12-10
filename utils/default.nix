{ lib
, myLib
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
    flakeRefToString
    getFlake
    hasAttr
    ;

  inherit (lib)
    getExe
    replaceStrings
    filterAttrs
    toShellVar
    mapAttrs'
    nameValuePair
    toLower
    ;

  inherit (myLib)
    shell
    getPkgData
    ;

  serialiseJSON = shell.serialiseJSON jq;
  importJSON = shell.importJSON jq;
  getFileHash = shell.getFileHash nix jq;
in
rec {
  updateScripts = packages:
    let
      scripts = mapAttrs'
        (_: v: nameValuePair v.passthru.dirname v.passthru.mypkgsUpdateScript)
        (filterAttrs
          (_: v: v.passthru ? mypkgsUpdateScript)
          packages);
    in
    runCommand
      "mypkgs-update-scripts"
      { }
      ''
        mkdir -p $out
        ${toShellVar "SCRIPTS" scripts}
        for name in "''${!SCRIPTS[@]}"; do
          ${coreutils}/bin/ln -s ''${SCRIPTS[$name]} $out/$name
        done
      '';

  # NOTE: *Pkg and *Script are only expected to be used from somewhere within `/pkgs`
  # MAYBE: preUpdateScripts or postUpdateScripts

  gitHubVersionScript =
    { owner
    , repo
    , ref ? "" # empty means fetch latest release
    , dirname ? repo
    , ...
    }:
    let
      updateScript = writeShellScript "mypkgs-update-version-${dirname}" ''
        set -eufo pipefail

        ${toShellVar "CURL" (getExe curl)}
        ${toShellVar "SED" (getExe gnused)}
        ${toShellVar "DATE" "${coreutils}/bin/date"}
        ${toShellVar "HEAD" "${coreutils}/bin/head"}

        if [ -z "${ref}" ]; then
          # FIXME: Pre-releases are always included
          RELEASE_URL=${importJSON "$($CURL -s 'https://api.github.com/repos/${owner}/${repo}/releases')" ".[0].url"}
          RELEASE=$($CURL -s "$RELEASE_URL")
          REV=${importJSON "$RELEASE" ".target_commitish"}
          RELEASE_NAME=${importJSON "$RELEASE" ".name"}
          VERSION=$(echo "$RELEASE_NAME" | $SED 's/[^1-9]*//')
        else
          COMMIT=$($CURL -s 'https://api.github.com/repos/${owner}/${repo}/commits/${ref}')
          REV=${importJSON "$COMMIT" ".sha"}
          COMMIT_DATE=${importJSON "$COMMIT" ".commit.committer.date"} 
          DATE=$($DATE -d "$COMMIT_DATE" --utc '+%Y.%m.%d')
          VERSION=$(printf '%s+%s_%s' "$DATE" "${ref}" "$(echo "$REV" | "$HEAD" -c7)")
        fi

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
        set -eufo pipefail

        URL="${url}"
        HASH=${getFileHash "$URL"}

        ${serialiseJSON {
          url = "$URL";
          hash = "$HASH";
        }}
      '';
    in
    updateScript;

  mkPassthru =
    { updateScript
    , dirname
    }: {
      passthru = {
        inherit dirname;
        mypkgsUpdateScript = updateScript;
      };
    };

  mkPkg =
    { version
    , src
    , updateScript
    , dirname
    }: {
      inherit version src;
    } // mkPassthru { inherit updateScript dirname; };

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
        set -eufo pipefail

        VERSIONDATA=$(${versionScript})
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
        set -eufo pipefail

        VERSIONDATA=$(${versionScript})
        VERSION=${importJSON "$VERSIONDATA" ".version"}
        RELEASE_NAME=${importJSON "$VERSIONDATA" ".release_name"}
        ARCHIVEDATA=$(${hashScript} "$RELEASE_NAME" "$VERSION")
        HASH=${importJSON "$ARCHIVEDATA" ".hash"}
        URL=${importJSON "$ARCHIVEDATA" ".url"}

        if [ -n '${toString useReleaseName}' ]; then
          VERSION="$RELEASE_NAME"
        fi
        if [ -n '${toString prefixVersion}' ]; then
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
}

