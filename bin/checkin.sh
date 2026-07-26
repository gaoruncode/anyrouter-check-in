#!/usr/bin/env bash
# AnyRouter 签到启动脚本（Linux / macOS / Git Bash）
# 用法: ./bin/checkin.sh
# 一次启动 = 一轮签到，结束后退出

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

if [[ ! -f "${PROJECT_ROOT}/checkin.py" ]]; then
	echo "[ERROR] checkin.py not found in ${PROJECT_ROOT}" >&2
	exit 1
fi

if [[ ! -f "${PROJECT_ROOT}/.env" ]]; then
	echo "[WARN] .env not found. Copy .env.example to .env and configure ANYROUTER_ACCOUNTS." >&2
fi

run_with_uv() {
	uv run checkin.py "$@"
}

run_with_python() {
	if command -v python3 >/dev/null 2>&1; then
		python3 checkin.py "$@"
	elif command -v python >/dev/null 2>&1; then
		python checkin.py "$@"
	else
		echo "[ERROR] Neither uv nor python3/python found in PATH." >&2
		echo "Install uv (https://docs.astral.sh/uv/) or Python 3.11+." >&2
		exit 1
	fi
}

echo "[INFO] Project root: ${PROJECT_ROOT}"
echo "[INFO] Starting check-in..."

if command -v uv >/dev/null 2>&1; then
	run_with_uv "$@"
else
	echo "[WARN] uv not found, falling back to system Python." >&2
	run_with_python "$@"
fi
