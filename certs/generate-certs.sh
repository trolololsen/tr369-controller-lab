#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

CA_SUBJECT="${CA_SUBJECT:-/CN=TR369-Lab-CA}"
SERVER_SUBJECT="${SERVER_SUBJECT:-/CN=usp-mqtt}"
CONTROLLER_SUBJECT="${CONTROLLER_SUBJECT:-/CN=controller-1}"
AGENT_SUBJECT="${AGENT_SUBJECT:-/CN=router-1}"
SERVER_SAN="${SERVER_SAN:-DNS:mqtt,DNS:usp-mqtt,DNS:localhost,IP:127.0.0.1}"
VALID_DAYS="${VALID_DAYS:-3650}"

OPENSSL_REQ=(openssl req)
case "${OSTYPE:-}" in
  msys*|cygwin*|win32*)
    OPENSSL_REQ=(env MSYS2_ARG_CONV_EXCL="*" openssl req)
    ;;
esac

OLD_CERT_FILES=(
  ca.crt
  ca.key
  ca.srl
  server.crt
  server.csr
  server.key
  controller.crt
  controller.csr
  controller.key
  controller.pem
  agent.crt
  agent.csr
  agent.key
  agent.pem
)

echo "[0/7] Removing previous cert artifacts (if present)"
rm -f "${OLD_CERT_FILES[@]}"

SERVER_EXTFILE="$(mktemp)"
cleanup() {
  rm -f "${SERVER_EXTFILE}"
}
trap cleanup EXIT
printf 'subjectAltName=%s\n' "${SERVER_SAN}" > "${SERVER_EXTFILE}"

echo "[1/7] Generating CA key"
openssl genrsa -out ca.key 4096

echo "[2/7] Generating CA certificate"
"${OPENSSL_REQ[@]}" -x509 -new -nodes   -key ca.key   -sha256   -days "${VALID_DAYS}"   -subj "${CA_SUBJECT}"   -out ca.crt

echo "[3/7] Generating broker server key and CSR"
openssl genrsa -out server.key 2048
"${OPENSSL_REQ[@]}" -new   -key server.key   -subj "${SERVER_SUBJECT}"   -out server.csr

echo "[4/7] Signing broker server certificate"
openssl x509 -req   -in server.csr   -CA ca.crt   -CAkey ca.key   -CAcreateserial   -out server.crt   -days "${VALID_DAYS}"   -sha256   -extfile "${SERVER_EXTFILE}"

echo "[5/7] Generating controller certificate bundle"
openssl genrsa -out controller.key 2048
"${OPENSSL_REQ[@]}" -new   -key controller.key   -subj "${CONTROLLER_SUBJECT}"   -out controller.csr
openssl x509 -req   -in controller.csr   -CA ca.crt   -CAkey ca.key   -CAcreateserial   -out controller.crt   -days "${VALID_DAYS}"   -sha256
cat controller.crt ca.crt controller.key > controller.pem

echo "[6/7] Generating agent certificate bundle"
openssl genrsa -out agent.key 2048
"${OPENSSL_REQ[@]}" -new   -key agent.key   -subj "${AGENT_SUBJECT}"   -out agent.csr
openssl x509 -req   -in agent.csr   -CA ca.crt   -CAkey ca.key   -CAcreateserial   -out agent.crt   -days "${VALID_DAYS}"   -sha256
cat agent.crt ca.crt agent.key > agent.pem

echo "[7/7] Certificates created in ${SCRIPT_DIR}:"
<<<<<<< ours
ls -l ca.crt ca.key ca.srl server.crt server.csr server.key controller.crt controller.csr controller.key controller.pem agent.crt agent.csr agent.key agent.pem
=======
ls -l ca.crt ca.key ca.srl server.crt server.csr server.key controller.crt controller.csr controller.key controller.pem agent.crt agent.csr agent.key agent.pem
>>>>>>> theirs
