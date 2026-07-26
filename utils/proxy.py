"""代理配置：读取环境变量并供浏览器 / HTTP 客户端使用。"""

from __future__ import annotations

import os
from urllib.parse import unquote, urlparse


def get_proxy_server(*, use_proxy: bool = True) -> str | None:
	"""按平台配置读取 CHECKIN_PROXY_URL；use_proxy=False 时不返回代理地址。"""
	if not use_proxy:
		return None
	server = os.getenv('CHECKIN_PROXY_URL', '').strip()
	return server or None


def get_playwright_proxy(*, use_proxy: bool = True, bypass: str | None = None) -> dict[str, str] | None:
	"""返回 Playwright/Chromium 可用的 proxy 配置。

	Playwright 要求把代理认证拆成 username/password 字段；
	若把 user:pass 写在 server URL 里，Chromium 会报 net::ERR_INVALID_AUTH_CREDENTIALS。

	``bypass`` 可选，逗号分隔的域名列表，这些域名不走代理（如 ``github.com``）。
	"""
	server = get_proxy_server(use_proxy=use_proxy)
	if not server:
		return None

	parsed = urlparse(server)
	if not parsed.scheme or not parsed.hostname:
		# 非标准 URL 时原样交给 Playwright，避免静默丢代理
		return {'server': server}

	port = f':{parsed.port}' if parsed.port else ''
	proxy: dict[str, str] = {'server': f'{parsed.scheme}://{parsed.hostname}{port}'}
	if parsed.username is not None:
		proxy['username'] = unquote(parsed.username)
	if parsed.password is not None:
		proxy['password'] = unquote(parsed.password)
	if bypass:
		proxy['bypass'] = bypass
	return proxy
