#!/usr/bin/env bash
# 一键：校验出口 IP 是否为家宽（不要是 VPN IP）
# 用法: ./check-exit-ip.sh [代理地址]
# 例:   ./check-exit-ip.sh http://checkin:密码@127.0.0.1:7890

set -euo pipefail

PROXY_URL="${1:-}"
if [[ -z "${PROXY_URL}" ]]; then
	if [[ -f .env ]]; then
		# shellcheck disable=SC1091
		set -a
		# 只读需要的变量，避免奇怪字符
		GOST_USER="$(grep -E '^GOST_USER=' .env | cut -d= -f2- || true)"
		GOST_PASS="$(grep -E '^GOST_PASS=' .env | cut -d= -f2- || true)"
		GOST_PORT="$(grep -E '^GOST_PORT=' .env | cut -d= -f2- || true)"
		set +a
		GOST_USER="${GOST_USER:-checkin}"
		GOST_PORT="${GOST_PORT:-7890}"
		if [[ -n "${GOST_PASS:-}" && "${GOST_PASS}" != "请改成超长随机密码" ]]; then
			PROXY_URL="http://${GOST_USER}:${GOST_PASS}@127.0.0.1:${GOST_PORT}"
		fi
	fi
fi

if [[ -z "${PROXY_URL}" ]]; then
	echo "Usage: $0 http://user:pass@host:port" >&2
	exit 1
fi

echo "[INFO] Direct exit IP:"
DIRECT_IP="$(curl -fsS --connect-timeout 8 https://api.ipify.org || true)"
echo "  ${DIRECT_IP:-failed}"

echo "[INFO] Via proxy exit IP:"
PROXY_IP="$(curl -fsS --connect-timeout 15 -x "${PROXY_URL}" https://api.ipify.org || true)"
echo "  ${PROXY_IP:-failed}"

if [[ -z "${PROXY_IP}" ]]; then
	echo "[FAILED] Proxy not reachable or auth failed"
	exit 1
fi

if [[ -n "${DIRECT_IP}" && "${DIRECT_IP}" == "${PROXY_IP}" ]]; then
	echo "[OK] Proxy exit matches host direct exit (likely home WAN if host has no VPN)"
else
	echo "[WARN] Proxy exit differs from host direct exit, or direct failed"
	echo "       If PROXY_IP looks like a VPN/datacenter IP, disable VPN on Docker host"
fi
