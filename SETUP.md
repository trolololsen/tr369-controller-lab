# New PC setup notes

This repo is a local TR-369 / USP lab for controller and MQTT testing. It can be
run locally with Docker Compose and pushed to the public GitHub repo:

https://github.com/trolololsen/tr369-controller-lab

## Required tools

- Docker Desktop
- Git or GitHub Desktop
- Visual Studio Code
- Codex
- OpenSSL only if certificates need to be regenerated

## Current local baseline

The expected stack is:

- `usp-mqtt` on ports `1883` and `8883`
- `usp-controller` on port `9001`
- `usp-agent` as the local simulated USP endpoint

The generated certificate files are intentionally ignored by Git. If the existing
`certs/*.crt`, `certs/*.key`, and `certs/*.pem` files are missing on a new
machine, regenerate them before starting the lab.

## Start the lab

From the repository root:

```powershell
docker compose up -d --build
docker compose ps
docker compose logs -f mqtt controller agent
```

Stop it with:

```powershell
docker compose down
```

## Send a controller command file

For the current real-router test, configure the router side consistently:

```text
Broker address: 192.168.51.102
Broker port: 1883
MQTT protocol: 5.0
MQTT client ID: router-sn-003
USP EndpointID: router-sn-003
Controller EndpointID: controller-1
Controller MQTT topic: /usp/controller
Router MQTT response/subscription topic: /usp/endpoint/router-sn-003
TLS: disabled for first plain-MQTT test
```

Then send the current software-version query:

```powershell
.\scripts\send-ctrl.ps1 .\get_swver.ctrl
```

The test controller sends the USP request but does not print decoded replies.
Watch broker, controller, router, or packet-capture logs when validating replies.

## Regenerate certificates

Use Git Bash, WSL, or another shell with OpenSSL available:

```bash
./scripts/generate-certs.sh
```

If a real router connects to TLS using a hostname or IP that is not already in
the server certificate, regenerate with a matching SAN:

```bash
SERVER_SAN='DNS:broker.example.local,IP:192.168.1.20' ./scripts/generate-certs.sh
```

## Docker permissions on Windows

If Docker Desktop is running but commands fail with Docker API or named pipe
permission errors:

1. Confirm Docker Desktop has finished starting.
2. Confirm the Windows user is in the `docker-users` group.
3. Sign out and back in after group changes.

Inside Codex, Docker commands may require approval because Codex runs in a
sandbox. Approved Docker commands can still control the local stack.

## Git workflow

Check state:

```powershell
git status --short --branch
```

Commit and push:

```powershell
git add <files>
git commit -m "Describe the change"
git push origin main
```

GitHub Desktop can do the same push flow visually. Keep generated certificate
files out of commits unless there is a deliberate reason to publish test certs.
