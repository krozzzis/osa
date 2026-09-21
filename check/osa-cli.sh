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

cat >"$work_dir/bin/nix-collect-garbage" <<'EOF'
#!@bash@
printf 'nix-collect-garbage %s\n' "$*" >>"$OSA_TEST_LOG"
EOF
chmod +x "$work_dir/bin/nix-collect-garbage"

cat >"$work_dir/bin/home-manager" <<'EOF'
#!@bash@
printf 'home-manager %s\n' "$*" >>"$OSA_TEST_LOG"
EOF
chmod +x "$work_dir/bin/home-manager"

cat >"$work_dir/bin/run0" <<'EOF'
#!@bash@
printf 'run0 %s\n' "$*" >>"$OSA_TEST_LOG"
EOF
chmod +x "$work_dir/bin/run0"

cat >"$work_dir/bin/getent" <<'EOF'
#!@bash@
printf 'tester:x:%s:100::%s:/bin/bash\n' "$2" "$OSA_TEST_USER_HOME"
EOF
chmod +x "$work_dir/bin/getent"

cat >"$work_dir/bin/runuser" <<'EOF'
#!@bash@
printf 'runuser %s\n' "$*" >>"$OSA_TEST_LOG"
EOF
chmod +x "$work_dir/bin/runuser"

export OSA_TEST_LOG="$work_dir/log"
export OSA_TEST_USER_HOME="$work_dir/tester"
export PATH="$work_dir/bin:$PATH"

bash @osaScript@ update --config "$work_dir/config" -- --refresh

expected=$'nix run .#write-flake\nnix flake update --refresh\nnix run .#write-flake'
actual=$(<"$OSA_TEST_LOG")
[[ $actual == "$expected" ]]

: >"$OSA_TEST_LOG"
bash @osaScript@ update-osa --config "$work_dir/config" -- --refresh

expected=$'nix run .#write-flake\nnix flake update osa --refresh\nnix run .#write-flake'
actual=$(<"$OSA_TEST_LOG")
[[ $actual == "$expected" ]]

: >"$OSA_TEST_LOG"
HOME="$work_dir/home-without-config" bash @osaScript@ clean

expected=$'home-manager expire-generations now\nnix-collect-garbage --delete-old\nrun0 nix-collect-garbage --delete-old'
actual=$(<"$OSA_TEST_LOG")
[[ $actual == "$expected" ]]

: >"$OSA_TEST_LOG"
sed 's/EUID == 0/0 == 0/g' @osaScript@ >"$work_dir/osa-as-root"
expected_elevated_clean="runuser --user tester -- env HOME=$work_dir/tester USER=tester LOGNAME=tester PATH=$PATH home-manager expire-generations now
runuser --user tester -- env HOME=$work_dir/tester USER=tester LOGNAME=tester PATH=$PATH nix-collect-garbage --delete-old
nix-collect-garbage --delete-old"

HOME="$work_dir/root" bash "$work_dir/osa-as-root" \
  clean --config "$work_dir/config"
actual=$(<"$OSA_TEST_LOG")
[[ $actual == "$expected_elevated_clean" ]]

if HOME="$work_dir/root" bash "$work_dir/osa-as-root" clean 2>/dev/null; then
  echo "osa accepted a root invocation without --config" >&2
  exit 1
fi

if bash @osaScript@ update --config "$work_dir/missing" 2>/dev/null; then
  echo "osa accepted a missing configuration directory" >&2
  exit 1
fi
