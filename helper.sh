# RUN THIS SCRIPT WITH `nix run .#helper -- <args...>`

# TODO: Rewrite this

set -euo pipefail

# You can change this to your own cache.
CACHIX_NAME="spitulax"

command -v nom >/dev/null
NOM=$?

_nix () {
    nix --experimental-features 'nix-command flakes' --accept-flake-config $@
}

echoErr () {
    echo -en "\033[31m" 1>&2
    echo $@ 1>&2
    echo -en "\033[0m" 1>&2
}

decolor () {
    sed -e 's/\x1b\[[0-9;]*m//g'
}

paths () {
    _nix path-info --json result/ | jq -r '.[].references.[]'
}

build () {
    echo -e '\033[1mBuilding packages...\033[0m'
    if [ $NOM -eq 0 ]; then
        _nix build .#cached --log-format internal-json -v |& nom --json
    else
        _nix build .#cached
    fi
}

push () {
    echo -e '\033[1mPushing packages...\033[0m'
    cachix push "$CACHIX_NAME" $(paths)
}

upinput () {
    echo -e '\033[1mUpdating flake inputs...\033[0m'
    _nix flake update
}

uplist () {
    echo -e '\033[1mUpdating package list...\033[0m'
    local path=$(_nix build .#mypkgs-list --json | jq -r '.[].outputs.out')
    install -m644 "$path" list.md
}

# Arguments:
# - DIRNAME: one or more directories to update (pkgs/* or flakes/*)
# - SKIP_EXIST: if 1, skip directories where pkg.json already exists
# - FORCE: if 1, update even if the found version is the same as the old version
# - FLAKE_ONLY: if 1, only update the flakes
upscript () {
    up () {
        local type="$1"
        local dirname="$2"
        local script="$3"
        if ! [ -d "${dirname}" ]; then
            echoErr "${dirname} did not exist"
            return
        fi

        local json_path
        case "$type" in
            "flake")
                json_path="${dirname}/flake.json"
                ;;
            "pkg")
                json_path="${dirname}/pkg.json"
                ;;
            *)
                echoErr "Unknown type: ${type}"
                return
        esac

        if [ "${SKIP_EXIST:-0}" -eq 1 ] && [ -f "$json_path" ]; then
            return
        fi
        echo -e "\033[1mUpdating ${dirname}...\033[0m"
        local oldver
        if [ -r "$json_path" ]; then
            if [ "$type" == "flake" ]; then
                oldver=$(cat "$json_path" | jq -r '.rev')
            elif [ "$type" == "pkg" ]; then
                oldver=$(cat "$json_path" | jq -r '.orig_version')
            fi
        fi

        local json
        set +e
        export FORCE="${FORCE:-0}"
        json=$($script "${oldver:-}")
        local status=$?
        if [ $status -eq 0 ]; then
            echo "$json" > "$json_path"
        elif [ $status -eq 200 ]; then
            echo "Skipped"
        else
            echoErr "Failed to update ${dirname}"
            exit 1
        fi
        set -e
    }

    echo -e '\033[1mRunning update scripts...\033[0m'

    local pkgs_drv
    local flakes_drv=$(_nix build .#flakes-update-scripts --json | jq -r '.[].outputs.out')
    if [ "${FLAKE_ONLY:-0}" -ne 1 ]; then
        pkgs_drv=$(_nix build .#pkgs-update-scripts --json | jq -r '.[].outputs.out')
    fi

    for x in $(find -L "$flakes_drv" -type f -executable); do
        if [ -v DIRNAME ]; then
            for dirname in $DIRNAME; do
                if [[ "$dirname" != flakes/* ]]; then
                    continue
                fi
                if [ "$dirname" == "flakes/$(basename "$x")" ]; then
                    up "flake" "$dirname" "$x"
                    break
                fi
            done
        else
            up "flake" "flakes/$(basename "$x")" "$x"
        fi
    done

    [ "${FLAKE_ONLY:-0}" -eq 1 ] && return

    for x in $(find -L "$pkgs_drv" -type f -executable); do
        if [ -v DIRNAME ]; then
            for dirname in $DIRNAME; do
                if [[ "$dirname" != pkgs/* ]]; then
                    continue
                fi
                if [ "$dirname" == "pkgs/$(basename "$x")" ]; then
                    up "pkg" "$dirname" "$x"
                    break
                fi
            done
        else
            up "pkg" "pkgs/$(basename "$x")" "$x"
        fi
    done
}

commitup () {
    # TODO: Implement the new `commitup`
    echoErr "Unimplemented"
    exit 1
}

usage () {
    echo "Arguments are passed via environment variables."
    echo "Subcommands:"
    echo "- build"
    echo "- commitup"
    echo "- partup"
    echo "- pushinput"
    echo "- pushpkgs"
    echo "- up"
    echo "- upinput"
    echo "- uplist"
    echo "- upscript"
}

[ $# -ne 1 ] && usage && exit 1

case "$1" in
# Update this flake's inputs.
"upinput")
    upinput
    ;;

# Build cached packages.
"build")
    build
    ;;

# Push this flake's inputs to cachix.
"pushinput")
    echo -e '\033[1mPushing inputs to cachix...\033[0m'
    _nix flake archive --json \
        | jq -r '.path,(.inputs|to_entries[].value.path)' \
        | cachix push "$CACHIX_NAME"
    ;;

# Push recently built packages to cachix.
# Typically used right after calling `build`.
"pushpkgs")
    push
    ;;

# Update `list.md`.
"uplist")
    uplist
    ;;

# Run the update scipt of maintained packages and flakes.
"upscript")
    upscript
    ;;

# Full update routine.
"up")
    upinput && upscript && build && push && uplist
    ;;

# Partial update (useful for adding new packages without updating other packages).
"partup")
    build && push && uplist
    ;;

# Commit current changes as an update.
"commitup")
    commitup
    ;;

*)
    usage
    exit 1
    ;;
esac
