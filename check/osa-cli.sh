#!/usr/bin/env bash
set -euo pipefail

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/bin" "$work_dir/config"
touch "$work_dir/config/flake.nix"
mkdir -p "$work_dir/store/system/bin"
cat >"$work_dir/store/system/bin/switch-to-configuration" <<'EOF'
#!@bash@
printf 'activate %s\n' "$*" >>"$OSA_TEST_LOG"
EOF
chmod +x "$work_dir/store/system/bin/switch-to-configuration"
sed -e "s|/nix/store/|$work_dir/store/|g" \
  -e "s|/run/current-system|$work_dir/store/system|g" @osaScript@ >"$work_dir/osa"
osa_script=$work_dir/osa
export OSA_TEST_SYSTEM="$work_dir/store/system"

cat >"$work_dir/bin/nix" <<'EOF'
#!@bash@
printf 'nix %s\n' "$*" >>"$OSA_TEST_LOG"
if [[ $1 == build ]]; then
  [[ ${OSA_TEST_FAIL_BUILD:-0} == 0 ]] || exit 42
  printf '%s\n' "$OSA_TEST_SYSTEM"
fi
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
if [[ ${OSA_TEST_EXEC_ACTIVATION:-0} == 1 ]]; then
  shift 2
  exec "$@"
fi
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

for tool in nom nvd nix-env; do
  cat >"$work_dir/bin/$tool" <<'EOF'
#!@bash@
printf '%s %s\n' "${0##*/}" "$*" >>"$OSA_TEST_LOG"
if [[ ${0##*/} == nom ]]; then
  exec nix "$@"
fi
if [[ ${0##*/} == nix-env && ${OSA_TEST_FAIL_PROFILE:-0} == 1 ]]; then
  exit 43
fi
if [[ ${0##*/} == nvd && ${OSA_TEST_FAIL_DIFF:-0} == 1 ]]; then
  exit 44
fi
EOF
  chmod +x "$work_dir/bin/$tool"
done

export OSA_TEST_LOG="$work_dir/log"
export OSA_TEST_USER_HOME="$work_dir/tester"
export PATH="$work_dir/bin:$PATH"

bash "$osa_script" update --config "$work_dir/config" -- --refresh

expected=$'nix run .#write-flake\nnix flake update --refresh\nnix run .#write-flake'
actual=$(<"$OSA_TEST_LOG")
[[ $actual == "$expected" ]]

: >"$OSA_TEST_LOG"
bash "$osa_script" update-osa --config "$work_dir/config" -- --refresh

expected=$'nix run .#write-flake\nnix flake update osa --refresh\nnix run .#write-flake'
actual=$(<"$OSA_TEST_LOG")
[[ $actual == "$expected" ]]

: >"$OSA_TEST_LOG"
HOME="$work_dir/home-without-config" bash "$osa_script" clean

expected=$'home-manager expire-generations now\nnix-collect-garbage --delete-old\nrun0 --unit=osa-clean-INVOCATION.service --description=OSA: clean nix-collect-garbage --delete-old'
actual=$(<"$OSA_TEST_LOG")
actual=$(sed -E 's/osa-clean-p[0-9]+-[0-9]+\.service/osa-clean-INVOCATION.service/' <<<"$actual")
[[ $actual == "$expected" ]]

for action in switch boot test update-switch update-boot; do
  : >"$OSA_TEST_LOG"
  bash "$osa_script" "$action" --config "$work_dir/config" 'test/host name' -- --show-trace
  actual=$(<"$OSA_TEST_LOG")
  [[ $actual == *'nom build .#nixosConfigurations."test/host name".config.system.build.toplevel --show-trace'* ]]
  [[ $actual == *"nvd diff $OSA_TEST_SYSTEM $OSA_TEST_SYSTEM"* ]]
  [[ $actual =~ --unit=osa-$action-test_host_name-p[0-9]+-[0-9]+\.service ]]
  [[ $actual == *"--description=OSA: $action test/host name"* ]]
  [[ $actual == *"$OSA_TEST_SYSTEM ${action#update-} $work_dir/bin/nix-env"* ]]
done

for action in build 'switch --dry' 'switch --ask'; do
  : >"$OSA_TEST_LOG"
  read -r -a action_args <<<"$action"
  bash "$osa_script" "${action_args[@]}" --no-nom --config "$work_dir/config" host <<<n
  actual=$(<"$OSA_TEST_LOG")
  [[ $actual == *'nix build'* && $actual != *'nom build'* && $actual != *'run0 '* ]]
done

: >"$OSA_TEST_LOG"
if OSA_TEST_FAIL_BUILD=1 bash "$osa_script" os switch --config "$work_dir/config" host; then
  echo "osa ignored a failed build" >&2
  exit 1
fi
actual=$(<"$OSA_TEST_LOG")
[[ $actual != *'run0 '* ]]

: >"$OSA_TEST_LOG"
if OSA_TEST_FAIL_DIFF=1 bash "$osa_script" switch --config "$work_dir/config" host; then
  echo "osa ignored a failed comparison" >&2
  exit 1
fi
actual=$(<"$OSA_TEST_LOG")
[[ $actual != *'run0 '* ]]

: >"$OSA_TEST_LOG"
OSA_TEST_FAIL_DIFF=1 bash "$osa_script" switch --no-diff --config "$work_dir/config" host
actual=$(<"$OSA_TEST_LOG")
[[ $actual != *'nvd diff'* && $actual == *'run0 '* ]]

for action in switch boot test; do
  : >"$OSA_TEST_LOG"
  OSA_TEST_EXEC_ACTIVATION=1 bash "$osa_script" "$action" --config "$work_dir/config" host
  actual=$(<"$OSA_TEST_LOG")
  [[ $actual == *"activate $action" ]]
  if [[ $action == test ]]; then
    [[ $actual != *$'\nnix-env --profile'* ]]
  else
    [[ $actual == *"nix-env --profile /nix/var/nix/profiles/system --set $OSA_TEST_SYSTEM"* ]]
  fi
done

: >"$OSA_TEST_LOG"
if OSA_TEST_EXEC_ACTIVATION=1 OSA_TEST_FAIL_PROFILE=1 bash "$osa_script" switch --config "$work_dir/config" host; then
  echo "osa ignored a failed profile update" >&2
  exit 1
fi
actual=$(<"$OSA_TEST_LOG")
[[ $actual != *$'\nactivate '* ]]

if bash "$osa_script" clean --dry; then
  echo "osa accepted --dry for a destructive cleanup" >&2
  exit 1
fi

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

if bash "$osa_script" update --config "$work_dir/missing" 2>/dev/null; then
  echo "osa accepted a missing configuration directory" >&2
  exit 1
fi
