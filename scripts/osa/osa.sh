#!/usr/bin/env bash

set -euo pipefail

program=${0##*/}

die() {
  echo "$program: error: $*" >&2
  exit 2
}

invoking_user=
user_home=$HOME
default_config_dir="${OSA_CONFIG:-${user_home}/osa-user}"

usage() {
  cat <<EOF
Usage: $program <command> [--config PATH] <configuration> [-- EXTRA_ARGS...]
       $program {update|update-osa} [--config PATH] [-- EXTRA_ARGS...]
       $program clean

Commands:
  update           Regenerate flake.nix and update flake.lock
  update-osa       Regenerate flake.nix and update only the osa input
  update-switch    Update, then activate the configuration now
  update-boot      Update, then activate the configuration on next boot
  switch           Build and activate the configuration now
  boot             Build and activate the configuration on next boot
  test             Build and activate without adding a boot generation
  build            Build the system without activating it
  build-iso        Build a bootable ready-to-run image (sdImage or isoImage)
  build-installer  Build the <configuration>-installer package
  clean            Delete old Home Manager and Nix generations, then run GC

Options:
  -c, --config PATH  Configuration flake (default: $default_config_dir)
  -u, --update       Update inputs before building
  -a, --ask          Confirm before activation
  -n, --dry          Build and show changes without activating
      --no-nom       Use plain Nix build output
      --no-diff      Skip the generation comparison
  -h, --help         Show this help

Examples:
  $program switch nixlaptop-niri
  $program switch --config ~/osa-user nixlaptop-niri
  $program update --config ~/osa-user
  $program update-osa
  $program clean
  $program build-installer eeepc-xfce
EOF
}

run_unprivileged() {
  local github_token= nix_config
  local -a user_env=(env HOME="$user_home" USER="${invoking_user:-${USER:-}}" LOGNAME="${invoking_user:-${LOGNAME:-}}" PATH="$PATH")

  if command -v gh >/dev/null 2>&1; then
    if [[ -n $invoking_user ]]; then
      github_token=$(runuser --user "$invoking_user" -- \
        env HOME="$user_home" USER="$invoking_user" LOGNAME="$invoking_user" PATH="$PATH" \
        gh auth token --hostname github.com 2>/dev/null) || github_token=
    else
      github_token=$(gh auth token --hostname github.com 2>/dev/null) || github_token=
    fi
  fi

  if [[ -n $github_token ]]; then
    nix_config=${NIX_CONFIG-}
    [[ -z $nix_config ]] || nix_config+=$'\n'
    nix_config+="access-tokens = github.com=$github_token"
    user_env+=("NIX_CONFIG=$nix_config")
  fi

  if [[ -n $invoking_user ]]; then
    runuser --user "$invoking_user" -- \
      "${user_env[@]}" "$@"
  elif [[ -n $github_token ]]; then
    NIX_CONFIG="$nix_config" "$@"
  else
    "$@"
  fi
}

run_in_config() {
  (cd "$config_dir" && run_unprivileged "$@")
}

run_privileged() {
  NH_OSA_COMMAND=$command NH_OSA_HOST=$configuration osa-elevate "$@"
}

run_nh() {
  run_in_config env NH_OSA_COMMAND="$command" NH_OSA_HOST="$configuration" \
    NH_OSA_CONFIG="$config_dir" nh "$@"
}

write_flake() {
  echo "==> Regenerating $config_dir/flake.nix" >&2
  run_in_config nix run .#write-flake
}

update_flake() {
  local -a update_args=("${extra_args[@]}")

  if [[ ${1-} == osa ]]; then
    update_args=(osa "${update_args[@]}")
  fi

  # Refresh the generated input declarations before updating the lock file.
  # Regenerate again afterwards because updated inputs can change flake-file output.
  write_flake
  if [[ ${1-} == osa ]]; then
    echo "==> Updating the osa flake input in $config_dir" >&2
  else
    echo "==> Updating flake inputs in $config_dir" >&2
  fi
  run_in_config nix flake update "${update_args[@]}"
  write_flake
}

clean_system() {
  # Keep cleanup scoped to generations, as before; don't remove project roots.
  run_unprivileged nh clean user --no-gc --no-gcroots --no-direnv
  run_privileged nh clean all --no-gcroots --no-direnv
}

rebuild() {
  local action=$1
  local -a nh_args=(--hostname "$configuration" --out-link "$config_dir/result")
  [[ $no_nom == true ]] && nh_args+=(--no-nom)
  if [[ $no_diff == true ]]; then
    nh_args+=(--diff never)
  else
    nh_args+=(--diff always)
  fi
  [[ $dry == true ]] && action=build
  if [[ $update == true ]]; then
    update_flake
  else
    write_flake
  fi
  if ((EUID == 0)); then
    # Build and compare as the owner. NH's root phase consumes the completed
    # store path, so it cannot accidentally build the configuration as root.
    run_nh os build "$config_dir" "${nh_args[@]}" -- "${extra_args[@]}"
    [[ $action == build ]] && return
    local -a activation_args=(--bypass-root-check --elevation-strategy none --diff never --show-activation-logs)
    [[ $ask == true ]] && activation_args+=(--ask)
    nh os "$action" "$config_dir/result" "${activation_args[@]}"
  else
    [[ $ask == true && $action != build ]] && nh_args+=(--ask)
    [[ $action != build ]] && nh_args+=(--show-activation-logs)
    run_nh os "$action" "$config_dir" "${nh_args[@]}" \
      --elevation-strategy "$(command -v osa-elevate)" -- "${extra_args[@]}"
  fi
}

flake_has_attr() {
  local attr=$1
  run_in_config nix eval --raw ".#${attr}.drvPath" >/dev/null 2>&1
}

build_system_image() {
  local prefix="nixosConfigurations.$configuration.config.system.build"
  local image_attr

  write_flake
  for image_attr in sdImage isoImage; do
    if flake_has_attr "$prefix.$image_attr"; then
      echo "==> Building $image_attr for $configuration" >&2
      build_image "$image_attr"
      return
    fi
  done

  die "configuration '$configuration' exports neither system.build.sdImage nor system.build.isoImage"
}

build_installer() {
  write_flake
  echo "==> Building installer for $configuration" >&2
  build_image installer
}

build_image() {
  local variant=$1 expression
  local -a nh_args=(--diff never --no-specialisation --out-link "$config_dir/result" --impure)
  [[ $no_nom == true ]] && nh_args+=(--no-nom)
  # NH's image command expects config.system.build.images; OSA also supports
  # legacy sdImage/isoImage and standalone installer packages. Adapt their
  # derivations to NH's build input without injecting paths into Nix source.
  if [[ $variant == installer ]]; then
    # Nix interpolation, deliberately not shell interpolation.
    # shellcheck disable=SC2016
    expression='{ config.system.build.toplevel = (builtins.getFlake (builtins.getEnv "NH_OSA_CONFIG")).packages.${builtins.currentSystem}.${(builtins.getEnv "NH_OSA_HOST") + "-installer"}; }'
  else
    # shellcheck disable=SC2016
    expression='{ config.system.build.toplevel = (builtins.getFlake (builtins.getEnv "NH_OSA_CONFIG")).nixosConfigurations.${builtins.getEnv "NH_OSA_HOST"}.config.system.build.${builtins.getEnv "NH_OSA_IMAGE"}; }'
  fi
  run_in_config env NH_OSA_CONFIG="$config_dir" NH_OSA_HOST="$configuration" \
    NH_OSA_IMAGE="$variant" nh os build --expr "$expression" "${nh_args[@]}" \
    -- "${extra_args[@]}"
}

if (($# == 0)); then
  usage >&2
  exit 2
fi

command=$1
shift
[[ $command == -h || $command == --help ]] && command=help
# Accept the familiar nh-style system command group as well.
if [[ $command == os ]]; then
  (($#)) || die "os requires a command"
  command=$1
  shift
fi
config_dir=$default_config_dir
config_explicit=false
configuration=
extra_args=()
no_nom=false
no_diff=false
ask=false
dry=false
update=false

while (($#)); do
  case $1 in
    -c|--config)
      (($# >= 2)) || die "$1 requires a path"
      config_dir=$2
      config_explicit=true
      shift 2
      ;;
    --config=*)
      config_dir=${1#*=}
      config_explicit=true
      shift
      ;;
    -u|--update) update=true; shift ;;
    -a|--ask) ask=true; shift ;;
    -n|--dry) dry=true; shift ;;
    --no-nom) no_nom=true; shift ;;
    --no-diff) no_diff=true; shift ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      extra_args=("$@")
      break
      ;;
    -*)
      die "unknown option '$1' (pass command-specific Nix arguments after --)"
      ;;
    *)
      [[ -z $configuration ]] || die "unexpected argument '$1'"
      configuration=$1
      shift
      ;;
  esac
done

if [[ $update == true || $ask == true || $dry == true || $no_diff == true ]]; then
  case $command in
    switch|boot|test|build|update-switch|update-boot) ;;
    *) die "--update, --ask, --dry and --no-diff require a system build command" ;;
  esac
fi

needs_config=true
[[ $command == clean || $command == help ]] && needs_config=false

if ((EUID == 0)) && [[ $command != help ]]; then
  [[ $config_explicit == true ]] || die "running as root requires --config PATH"
  needs_config=true
fi

if [[ $needs_config == true ]]; then
  config_dir=${config_dir/#\~/$user_home}
  [[ -d $config_dir ]] || die "configuration directory '$config_dir' does not exist"
  config_dir=$(cd "$config_dir" && pwd -P)
  [[ -f $config_dir/flake.nix ]] || die "'$config_dir' is not a flake directory"
fi

if ((EUID == 0)) && [[ $command != help ]]; then
  config_uid=$(stat -c %u "$config_dir")
  [[ $config_uid != 0 ]] || die "configuration directory '$config_dir' must be owned by a non-root user"
  passwd_entry=$(getent passwd "$config_uid") \
    || die "cannot resolve owner of configuration directory '$config_dir'"
  IFS=: read -r invoking_user _ invoking_uid _ _ user_home _ <<<"$passwd_entry"
  [[ -n $invoking_user && -n $user_home && $invoking_uid == "$config_uid" ]] \
    || die "invalid owner of configuration directory '$config_dir'"
fi

case $command in
  update)
    [[ -z $configuration ]] || die "the update command does not take a configuration name"
    update_flake
    ;;
  update-osa)
    [[ -z $configuration ]] || die "the update-osa command does not take a configuration name"
    update_flake osa
    ;;
  switch|boot|test|build)
    [[ -n $configuration ]] || die "$command requires a configuration name"
    rebuild "$command"
    ;;
  update-switch|update-boot)
    [[ -n $configuration ]] || die "$command requires a configuration name"
    update=true
    rebuild "${command#update-}"
    ;;
  build-iso)
    [[ -n $configuration ]] || die "$command requires a configuration name"
    build_system_image
    ;;
  build-installer)
    [[ -n $configuration ]] || die "$command requires a configuration name"
    build_installer
    ;;
  clean)
    [[ -z $configuration ]] || die "the clean command does not take a configuration name"
    ((${#extra_args[@]} == 0)) || die "the clean command does not take extra arguments"
    clean_system
    ;;
  help)
    usage
    ;;
  *)
    die "unknown command '$command' (see '$program help')"
    ;;
esac
