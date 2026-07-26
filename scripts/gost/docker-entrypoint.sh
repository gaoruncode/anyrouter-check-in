#!/bin/sh
set -eu

if [ -z "${GOST_PASS:-}" ]; then
	echo "[ERROR] GOST_PASS is required. Set it in .env or compose environment." >&2
	exit 1
fi

GOST_USER="${GOST_USER:-checkin}"
GOST_PORT="${GOST_PORT:-7890}"

echo "[INFO] Starting gost HTTP proxy on 0.0.0.0:${GOST_PORT}"
echo "[INFO] Auth user: ${GOST_USER}"
echo "[INFO] Make sure this Docker host does NOT use a global VPN as default route"

exec gost -L "http://${GOST_USER}:${GOST_PASS}@:${GOST_PORT}"
