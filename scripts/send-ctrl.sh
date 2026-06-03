#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: ./scripts/send-ctrl.sh <file.ctrl>" >&2
  exit 2
fi

file="$1"

if [[ ! -f "$file" ]]; then
  echo "Control file not found: $file" >&2
  exit 1
fi

container_path="/tmp/$(basename "$file")"

docker cp "$file" "usp-controller:$container_path"
MSYS_NO_PATHCONV=1 docker exec usp-controller ./obuspa -p -v 4 -x "$container_path" -a /certs/controller.pem -t /certs/ca.crt
