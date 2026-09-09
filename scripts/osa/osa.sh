#!/usr/bin/env bash

set -euo pipefail

program=${0##*/}
default_config_dir="${HOME}/osa-user"

usage() {
  cat <<EOF
Usage: $program <command> [--config PATH] <configuration> [-- EXTRA_ARGS...]
       $program update [--config PATH] [-- EXTRA_ARGS...]

Commands:
  update           Regenerate flake.nix and update flake.lock
  update-switch    Update, then activate the configuration now
  update-boot      Update, then activate the configuration on next boot
  switch           Build and activate the configuration now
  boot             Build and activate the configuration on next boot
  build-iso        Build a bootable ready-to-run image (sdImage or isoImage)
  build-installer  Build the <configuration>-installer package

Options:
  -c, --config PATH  Configuration flake (default: $default_config_dir)
  -h, --help         Show this help

Examples:
  $program switch nixlaptop-niri
  $program switch --config ~/osa-user nixlaptop-niri
  $program update --config ~/osa-user
  $program build-installer eeepc-xfce
EOF
}

die() {
  echo "$program: error: $*" >&2
  exit 2
}

run_in_config() {
  (cd "$config_dir" && "$@")
}

write_flake() {
  echo "==> Regenerating $config_dir/flake.nix" >&2
  run_in_config nix run .#write-flake
}

update_flake() {
  echo "==> Updating flake inputs in $config_dir" >&2
  run_in_config nix flake update "${extra_args[@]}"
  # Generate with the updated inputs. Doing this before the lock update can
  # fail when local configuration already uses an option added by a new input.
  write_flake
}

rebuild() {
  local action=$1
  write_flake
  echo "==> Running nixos-rebuild $action for $configuration" >&2
  sudo nixos-rebuild "$action" --flake "$config_dir#$configuration" "${extra_args[@]}"
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

config_dir=${config_dir/#\~/$HOME}
[[ -d $config_dir ]] || die "configuration directory '$config_dir' does not exist"
config_dir=$(cd "$config_dir" && pwd -P)
[[ -f $config_dir/flake.nix ]] || die "'$config_dir' is not a flake directory"

case $command in
  update)
    [[ -z $configuration ]] || die "the update command does not take a configuration name"
    update_flake
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
    sudo nixos-rebuild "${command#update-}" --flake "$config_dir#$configuration" "${extra_args[@]}"
    ;;
  build-iso)
    [[ -n $configuration ]] || die "$command requires a configuration name"
    build_system_image
    ;;
  build-installer)
    [[ -n $configuration ]] || die "$command requires a configuration name"
    build_installer
    ;;
  help)
    usage
    ;;
  *)
    die "unknown command '$command' (see '$program help')"
    ;;
esac
