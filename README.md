This repository provides a lightweight TR-369 (USP) lab using:

- OB-USP test controller container (`obuspa-test-controller`)
- Mosquitto MQTT broker
- Optional OB-USP agent simulator
- Docker Compose

## What this lab is for

- Bring up a local ACS-like environment for USP development
- Validate MQTT-based USP connectivity before onboarding a real router
- Reuse the same certs and broker settings when moving to real hardware

## Prerequisites

- Docker / Docker Compose
- OpenSSL

## Quick start

For new-machine setup notes, see `SETUP.md`.

1. Generate lab certificates:

```bash
./scripts/generate-certs.sh
```

2. Build and start containers:

```bash
./scripts/start.sh
```

3. Watch logs:

```bash
docker compose logs -f mqtt controller agent
```

4. Stop lab:

```bash
./scripts/stop.sh
```

## Services

- MQTT broker: `localhost:1883` (plain) and `localhost:8883` (TLS)
- Controller WebSocket: `localhost:9001`


### Why `-a` and `-t` are passed to OB-USPA in compose

The lab starts both `controller` and `agent` with:

- Controller uses `-a /certs/controller.pem` (controller certificate + private key bundle)
- Agent uses `-a /certs/agent.pem` (agent certificate + private key bundle)
- Both use `-t /certs/ca.crt` (trusted CA file)

`./scripts/generate-certs.sh` now creates separate CA-signed identities for the two local endpoints:
- `controller.crt` / `controller.pem` for endpoint `controller-1`
- `agent.crt` / `agent.pem` for endpoint `router-1`

Each `*.pem` bundle now contains `cert + ca + key`, while CA trust is also supplied separately via `-t /certs/ca.crt`.

Purpose: provide a certificate chain context so OB-USPA can determine trust role during USP/MQTT session setup.
Without these, logs can show `Failed to determine controller trust role - No cert chain` followed by disconnect loops.

## Internal lab MQTT settings (what they are and why)

For the **built-in simulated path** (`controller` + `agent` via mosquitto), baseline settings are:

- Controller (`docker/controller/controller.conf`):
  - `Device.LocalAgent.MTP.1.*` and `Device.LocalAgent.Controller.1.*` are populated for MQTT controller operation
  - `Device.MQTT.Client.1.BrokerAddress "mqtt"`
  - `Device.MQTT.Client.1.BrokerPort "8883"`
  - `Device.MQTT.Client.1.ClientID "controller-1"`
  - `Device.MQTT.Client.1.TransportProtocol "TLS"`
- Agent (`docker/agent/agent.conf`):
  - `Device.LocalAgent.MTP.1.*` and `Device.LocalAgent.Controller.1.*` are populated for MQTT agent/controller linkage
  - `Device.MQTT.Client.1.BrokerAddress "mqtt"`
  - `Device.MQTT.Client.1.BrokerPort "8883"`
  - `Device.MQTT.Client.1.ClientID "router-1"`
  - `Device.MQTT.Client.1.TransportProtocol "TLS"`
  - `Device.MQTT.Client.1.KeepAliveTime "60"`

Purpose: keep local validation simple and stable first. Once this baseline is healthy, move your **real router/client** to TLS on `8883` with CA trust configured.

## Connecting a real router (recommended sequence)

1. **Start with MQTT over 1883 (no TLS)** to validate baseline USP messaging.
2. Configure router USP MQTT client with:
   - Broker host: `<your-lab-ip-or-dns>`
   - Port: `1883`
   - USP endpoint ID: unique value per router (for example `router-sn123456`)
3. Confirm controller sees connection/events in logs.
4. Move to TLS (`8883`) **for the real router/client under test**:
   - Internal lab `controller` + `agent` simulation now defaults to TLS on `8883` with `TransportProtocol "TLS"` and cert args (`-a`/`-t`).
   - Import `certs/ca.crt` into router trust store.
   - Set broker host to the certificate SAN/CN name (default includes `mqtt`, `usp-mqtt`, `localhost`, `127.0.0.1`).
   - If your router uses a different hostname/IP, regenerate with `SERVER_SAN`:

```bash
SERVER_SAN='DNS:broker.example.local,IP:192.168.1.20' ./scripts/generate-certs.sh
```

Then restart the stack.


If you use internal MQTT on `8883`, keep `Device.MQTT.Client.1.TransportProtocol "TLS"` and cert arguments (`-a`, `-t`) enabled. If TLS settings are mismatched, Mosquitto will report protocol/TLS errors.

## First controller query target

The current development milestone is to move beyond initial connection and verify that the controller can read at least one real parameter from the device under test.

The repo includes a first draft request in `get_swver.ctrl`:

```text
msg_id:"1" to_id:"os::14360E-S240Y41000039" mqtt_topic:"/usp/endpoint/router-sn-001" mqtt_instance:"1"
msg_type:"Get" param_paths:"Device.DeviceInfo.SoftwareVersion"
```

Before using it against a real router, confirm these values match the device you are testing:

- `to_id`: the router's USP endpoint ID
- `mqtt_topic`: the router's USP response topic
- `mqtt_instance`: the controller MQTT client instance to use

`controller-query.conf` is the matching controller-side config snapshot intended for query testing against endpoint `os::14360E-S240Y41000039`.

Recommended next validation:

1. Start the lab.
2. Confirm the router establishes its USP session.
3. Send the `Get` request for `Device.DeviceInfo.SoftwareVersion`.
4. Capture the response and add the exact invocation steps to this README once confirmed.

## Notes

- This is a lab scaffold, not a hardened production ACS.
- Anonymous MQTT is enabled currently for easier bring-up.
- Keep endpoint IDs unique for each real router.
- On Git Bash (Windows), certificate subject arguments can be path-converted; if you had subject format errors, pull latest script changes and retry `./scripts/generate-certs.sh`.

## Next suggested improvements

- Add MQTT auth (username/password or mTLS)
- Persist controller + broker data volumes
- Add router-specific onboarding docs for your hardware model
- Add GitHub Actions checks for config lint/build validation

## Canonical lab file set (authoritative)

These are the exact runtime files this repo expects for the current baseline:

- `docker/controller/Dockerfile` (obuspa-test-controller source build, runs `./obuspa -r /config/controller.conf`)
- `docker/controller/controller.conf` (controller MQTT/WebSocket settings)
- `docker/agent/Dockerfile`
- `docker/agent/agent.conf`
- `docker/mosquitto/mosquitto.conf`
- `docker-compose.yml`

If your local files differ, align them first, then rebuild with `--no-cache`.
