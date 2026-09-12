#!/usr/bin/env bash
set -euo pipefail

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/bin" "$work_dir/config"
touch "$work_dir/config/flake.nix"

cat >"$work_dir/bin/nix" <<'EOF'
#!@bash@
printf 'nix %s\n' "$*" >>"$OSA_TEST_LOG"
EOF
chmod +x "$work_dir/bin/nix"

export OSA_TEST_LOG="$work_dir/log"
export PATH="$work_dir/bin:$PATH"

bash @osaScript@ update --config "$work_dir/config" -- --refresh

expected=$'nix run .#write-flake\nnix flake update --refresh\nnix run .#write-flake'
actual=$(<"$OSA_TEST_LOG")
[[ $actual == "$expected" ]]

if bash @osaScript@ update --config "$work_dir/missing" 2>/dev/null; then
  echo "osa accepted a missing configuration directory" >&2
  exit 1
fi
