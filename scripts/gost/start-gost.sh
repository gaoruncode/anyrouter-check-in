#!/usr/bin/env bash
# 最简 gost HTTP 代理启动脚本（Linux / macOS）
# 用法:
#   export GOST_USER=checkin
#   export GOST_PASS='超长随机密码'
#   export GOST_PORT=7890
#   ./start-gost.sh

set -euo pipefail

GOST_USER="${GOST_USER:-checkin}"
GOST_PASS="${GOST_PASS:-}"
GOST_PORT="${GOST_PORT:-7890}"
GOST_BIN="${GOST_BIN:-gost}"

if [[ -z "${GOST_PASS}" || "${GOST_PASS}" == "请改成超长随机密码" ]]; then
	echo "[ERROR] Set GOST_PASS env var to a strong random password first." >&2
	exit 1
fi

if ! command -v "${GOST_BIN}" >/dev/null 2>&1; then
	if [[ -x "./gost" ]]; then
		GOST_BIN="./gost"
	else
		echo "[ERROR] gost binary not found. Install to PATH or place ./gost here." >&2
		echo "Download: https://github.com/go-gost/gost/releases" >&2
		exit 1
	fi
fi

echo "[INFO] Starting gost HTTP proxy on 0.0.0.0:${GOST_PORT}"
echo "[INFO] Auth user: ${GOST_USER}"
exec "${GOST_BIN}" -L "http://${GOST_USER}:${GOST_PASS}@:${GOST_PORT}"
