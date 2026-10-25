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
  if [[ -n $invoking_user ]]; then
    runuser --user "$invoking_user" -- \
      env HOME="$user_home" USER="$invoking_user" LOGNAME="$invoking_user" PATH="$PATH" "$@"
  else
    "$@"
  fi
}

run_in_config() {
  (cd "$config_dir" && run_unprivileged "$@")
}

run_privileged() {
  if ((EUID == 0)); then
    "$@"
  else
    # Polkit's StartTransientUnit prompt shows the unit name, not Description.
    # Keep the operation readable and leave room for a unique invocation suffix.
    local unit_label="osa-$command${configuration:+-$configuration}"
    unit_label=${unit_label//[^a-zA-Z0-9_.-]/_}
    unit_label=${unit_label:0:180}
    run0 --unit="$unit_label-p$$-$RANDOM.service" \
      --description="OSA: $command${configuration:+ $configuration}" "$@"
  fi
}

has_nom() {
  [[ $no_nom == false ]] && command -v nom >/dev/null 2>&1
}

# Build through nom (nix-output-monitor) when available, plain nix otherwise.
run_build() {
  if has_nom; then
    run_in_config nom build "$@"
  else
    run_in_config nix build "$@"
  fi
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
  echo "==> Deleting old Home Manager generations" >&2
  run_unprivileged home-manager expire-generations now
  echo "==> Deleting old user Nix generations and collecting garbage" >&2
  run_unprivileged nix-collect-garbage --delete-old
  echo "==> Deleting old system Nix generations and collecting garbage" >&2
  run_privileged nix-collect-garbage --delete-old
}

rebuild() {
  local action=$1 system_path answer attr_configuration
  attr_configuration=${configuration//\\/\\\\}
  attr_configuration=${attr_configuration//\"/\\\"}
  if [[ $update == true ]]; then
    update_flake
  else
    write_flake
  fi
  echo "==> Building $configuration" >&2
  system_path=$(run_build ".#nixosConfigurations.\"$attr_configuration\".config.system.build.toplevel" \
    "${extra_args[@]}" --out-link "$config_dir/result" --print-out-paths)
  [[ $system_path == /nix/store/* && -x $system_path/bin/switch-to-configuration ]] \
    || die "build did not return a NixOS system"

  if [[ $no_diff == false && -e /run/current-system ]]; then
    echo "==> Comparing generations" >&2
    run_unprivileged nvd diff /run/current-system "$system_path"
  fi
  if [[ $action == build || $dry == true ]]; then
    echo "==> Built $system_path" >&2
    return
  fi
  if [[ $ask == true ]]; then
    read -r -p "Activate $configuration ($action)? [y/N] " answer || return 1
    case $answer in
      y|Y|yes|YES) ;;
      *) echo "==> Activation cancelled" >&2; return 0 ;;
    esac
  fi
  echo "==> Activating $configuration ($action)" >&2
  # Keep the profile update and activation in one authorization request. Pass
  # paths as arguments so configuration names never become shell source.
  # shellcheck disable=SC2016
  run_privileged "$(command -v bash)" -c '
    set -euo pipefail
    if [[ $2 != test ]]; then
      "$3" --profile /nix/var/nix/profiles/system --set "$1"
    fi
    exec "$1/bin/switch-to-configuration" "$2"
  ' "$program" "$system_path" "$action" "$(command -v nix-env)"
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
      run_build ".#$prefix.$image_attr" "${extra_args[@]}"
      return
    fi
  done

  die "configuration '$configuration' exports neither system.build.sdImage nor system.build.isoImage"
}

build_installer() {
  write_flake
  echo "==> Building installer for $configuration" >&2
  run_build ".#$configuration-installer" "${extra_args[@]}"
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
