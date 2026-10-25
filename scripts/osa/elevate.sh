#!/usr/bin/env bash
set -euo pipefail

if ((EUID == 0)); then
  exec "$@"
fi

action=${NH_OSA_COMMAND:-system}
host=${NH_OSA_HOST:-}
unit_label="osa-$action${host:+-$host}"
unit_label=${unit_label//[^a-zA-Z0-9_.-]/_}
unit_label=${unit_label:0:180}
exec run0 --pty-late --unit="$unit_label-p$$-$RANDOM.service" \
  --description="OSA: $action${host:+ $host}" "$@"
