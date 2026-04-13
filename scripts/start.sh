#!/usr/bin/env bash
set -euo pipefail

controller_conf="docker/controller/controller.conf"
agent_conf="docker/agent/agent.conf"

controller_port=$(awk -F "\"" '/Device\.MQTT\.Client\.1\.BrokerPort/{print $2; exit}' "$controller_conf" || true)
agent_port=$(awk -F '"' '/Device\.MQTT\.Client\.1\.BrokerPort/{print $2; exit}' "$agent_conf" || true)

if [[ "${ALLOW_INTERNAL_TLS_8883:-0}" != "1" ]] && { [[ "$controller_port" == "8883" ]] || [[ "$agent_port" == "8883" ]]; }; then
  echo "Notice: internal MQTT uses port 8883 (TLS)."
  echo "Set ALLOW_INTERNAL_TLS_8883=1 to suppress this notice."
fi

docker compose build
# detached so controller and broker can keep running while you test devices
docker compose up -d

echo "Lab stack started. Follow logs with: docker compose logs -f mqtt controller agent"
