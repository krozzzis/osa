#!/usr/bin/env bash
set -euo pipefail
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/bin" "$work_dir/config"
touch "$work_dir/config/flake.nix"
cp @osaScript@ "$work_dir/osa"
sed '1c\#!@bash@' @elevationScript@ >"$work_dir/bin/osa-elevate"
chmod +x "$work_dir/bin/osa-elevate"
export OSA_TEST_LOG="$work_dir/log"
export PATH="$work_dir/bin:$PATH"
cat >"$work_dir/bin/nix" <<'EOF'
#!@bash@
printf 'nix %s\n' "$*" >>"$OSA_TEST_LOG"
EOF
cat >"$work_dir/bin/nh" <<'EOF'
#!@bash@
printf 'nh %s\n' "$*" >>"$OSA_TEST_LOG"
[[ ${OSA_TEST_FAIL:-0} == 0 ]] || exit 42
EOF
cat >"$work_dir/bin/run0" <<'EOF'
#!@bash@
printf 'run0 %s\n' "$*" >>"$OSA_TEST_LOG"
EOF
cat >"$work_dir/bin/getent" <<'EOF'
#!@bash@
printf 'tester:x:%s:100::/tmp/tester:/bin/bash\n' "$2"
EOF
cat >"$work_dir/bin/runuser" <<'EOF'
#!@bash@
printf 'runuser %s\n' "$*" >>"$OSA_TEST_LOG"
shift 3
exec "$@"
EOF
chmod +x "$work_dir/bin/"*
osa_script=$work_dir/osa
for action in update update-osa; do
  : >"$OSA_TEST_LOG"
  bash "$osa_script" "$action" --config "$work_dir/config" -- --refresh
  actual=$(<"$OSA_TEST_LOG")
  input=
  [[ $action != update-osa ]] || input='osa '
  [[ $actual == "nix run .#write-flake"$'\n'"nix flake update ${input}--refresh"$'\n'"nix run .#write-flake" ]]
done
for action in switch boot test build update-switch update-boot; do
  : >"$OSA_TEST_LOG"
  bash "$osa_script" "$action" --config "$work_dir/config" 'test/host name' -- --show-trace
  actual=$(<"$OSA_TEST_LOG")
  [[ $actual == *"nh os ${action#update-} $work_dir/config --hostname test/host name --out-link $work_dir/config/result --diff always"* ]]
  [[ $actual == *"--elevation-strategy $work_dir/bin/osa-elevate -- --show-trace"* ]]
done
: >"$OSA_TEST_LOG"
bash "$osa_script" os switch --dry --no-nom --no-diff --config "$work_dir/config" host
actual=$(<"$OSA_TEST_LOG")
[[ $actual == *'nh os build '* && $actual == *'--no-nom --diff never'* ]]
[[ $actual != *'--show-activation-logs'* ]]
: >"$OSA_TEST_LOG"
bash "$osa_script" switch --ask --config "$work_dir/config" host
[[ $(<"$OSA_TEST_LOG") == *'--ask --show-activation-logs'* ]]
if OSA_TEST_FAIL=1 bash "$osa_script" switch --config "$work_dir/config" host; then
  echo 'OSA ignored NH failure' >&2
  exit 1
fi
for action in build-iso build-installer; do
  : >"$OSA_TEST_LOG"
  bash "$osa_script" "$action" --config "$work_dir/config" host
  actual=$(<"$OSA_TEST_LOG")
  [[ $actual == *'nh os build --expr { config.system.build.toplevel ='* ]]
  [[ $actual == *'--diff never --no-specialisation'* && $actual == *'--impure'* ]]
done
: >"$OSA_TEST_LOG"
HOME="$work_dir/missing-home" bash "$osa_script" clean
actual=$(<"$OSA_TEST_LOG")
[[ $actual == *'nh clean user --no-gc --no-gcroots --no-direnv'* ]]
[[ $actual == *'--description=OSA: clean nh clean all --no-gcroots --no-direnv'* ]]
: >"$OSA_TEST_LOG"
NH_OSA_COMMAND=switch NH_OSA_HOST='test/host name' osa-elevate env EXAMPLE=value command 'argument with spaces'
actual=$(<"$OSA_TEST_LOG")
[[ $actual =~ --unit=osa-switch-test_host_name-p[0-9]+-[0-9]+\.service ]]
[[ $actual == *'--description=OSA: switch test/host name env EXAMPLE=value command argument with spaces' ]]
sed 's/EUID == 0/0 == 0/g' @osaScript@ >"$work_dir/osa-root"
: >"$OSA_TEST_LOG"
bash "$work_dir/osa-root" switch --config "$work_dir/config" host
actual=$(<"$OSA_TEST_LOG")
[[ $actual == *'runuser --user tester'* ]]
[[ $actual == *"nh os build $work_dir/config"* ]]
[[ $actual == *"nh os switch $work_dir/config/result --bypass-root-check --elevation-strategy none"* ]]
if bash "$work_dir/osa-root" clean 2>/dev/null; then exit 1; fi
if bash "$osa_script" clean --dry 2>/dev/null; then exit 1; fi
if bash "$osa_script" update --config "$work_dir/missing" 2>/dev/null; then exit 1; fi
