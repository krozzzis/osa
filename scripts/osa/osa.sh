#!/usr/bin/env bash

set -euo pipefail

program=${0##*/}

die() {
  echo "$program: error: $*" >&2
  exit 2
}

sudo_user=
user_home=$HOME
if ((EUID == 0)) && [[ -n ${SUDO_USER:-} && $SUDO_USER != root ]]; then
  sudo_user=$SUDO_USER
  passwd_entry=$(getent passwd "$sudo_user") || die "cannot resolve sudo user '$sudo_user'"
  IFS=: read -r _ _ _ _ _ user_home _ <<<"$passwd_entry"
  [[ -n $user_home ]] || die "sudo user '$sudo_user' has no home directory"
fi
default_config_dir="${user_home}/osa-user"

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
  build-iso        Build a bootable ready-to-run image (sdImage or isoImage)
  build-installer  Build the <configuration>-installer package
  clean            Delete old Home Manager and Nix generations, then run GC

Options:
  -c, --config PATH  Configuration flake (default: $default_config_dir)
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
  if [[ -n $sudo_user ]]; then
    runuser --user "$sudo_user" -- \
      env HOME="$user_home" USER="$sudo_user" LOGNAME="$sudo_user" PATH="$PATH" "$@"
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
    run0 "$@"
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
  local action=$1
  write_flake
  echo "==> Running nixos-rebuild $action for $configuration" >&2
  run_privileged nixos-rebuild "$action" --flake "$config_dir#$configuration" "${extra_args[@]}"
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
      run_in_config nix build ".#$prefix.$image_attr" "${extra_args[@]}"
      return
    fi
  done

  die "configuration '$configuration' exports neither system.build.sdImage nor system.build.isoImage"
}

build_installer() {
  write_flake
  echo "==> Building installer for $configuration" >&2
  run_in_config nix build ".#$configuration-installer" "${extra_args[@]}"
}

if (($# == 0)); then
  usage >&2
  exit 2
fi

command=$1
shift
config_dir=$default_config_dir
configuration=
extra_args=()

while (($#)); do
  case $1 in
    -c|--config)
      (($# >= 2)) || die "$1 requires a path"
      config_dir=$2
      shift 2
      ;;
    --config=*)
      config_dir=${1#*=}
      shift
      ;;
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

if [[ $command != clean && $command != help ]]; then
  config_dir=${config_dir/#\~/$user_home}
  [[ -d $config_dir ]] || die "configuration directory '$config_dir' does not exist"
  config_dir=$(cd "$config_dir" && pwd -P)
  [[ -f $config_dir/flake.nix ]] || die "'$config_dir' is not a flake directory"
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
  switch|boot)
    [[ -n $configuration ]] || die "$command requires a configuration name"
    rebuild "$command"
    ;;
  update-switch|update-boot)
    [[ -n $configuration ]] || die "$command requires a configuration name"
    update_flake
    # update_flake has already generated flake.nix from the updated inputs.
    echo "==> Running nixos-rebuild ${command#update-} for $configuration" >&2
    run_privileged nixos-rebuild "${command#update-}" --flake "$config_dir#$configuration" "${extra_args[@]}"
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
