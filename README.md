# TR-369 Controller Lab

This repository provides a lightweight TR-369 (USP) controller environment using:

- OB-USP Test Controller
- Mosquitto MQTT broker
- Docker Compose

Features:

- MQTT transport
- WebSocket transport
- TLS support
- Simple certificate generation

## Start

Generate certificates:

./certs/generate-certs.sh

Start environment:

./scripts/start.sh