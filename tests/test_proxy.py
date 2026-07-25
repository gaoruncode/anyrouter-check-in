import sys
from pathlib import Path

project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from utils.proxy import get_playwright_proxy, get_proxy_server


def test_get_proxy_server_respects_use_proxy(monkeypatch):
	monkeypatch.setenv('CHECKIN_PROXY_URL', 'http://user:pass@proxy.example.com:27890')
	assert get_proxy_server(use_proxy=False) is None
	assert get_proxy_server(use_proxy=True) == 'http://user:pass@proxy.example.com:27890'


def test_get_proxy_server_empty(monkeypatch):
	monkeypatch.delenv('CHECKIN_PROXY_URL', raising=False)
	assert get_proxy_server(use_proxy=True) is None


def test_playwright_proxy_splits_auth(monkeypatch):
	monkeypatch.setenv('CHECKIN_PROXY_URL', 'http://checkin:s3cret@proxy.example.com:27890')
	assert get_playwright_proxy(use_proxy=True) == {
		'server': 'http://proxy.example.com:27890',
		'username': 'checkin',
		'password': 's3cret',
	}


def test_playwright_proxy_url_encoded_auth(monkeypatch):
	monkeypatch.setenv('CHECKIN_PROXY_URL', 'http://user%40mail:p%40ss@proxy.example.com:7890')
	assert get_playwright_proxy(use_proxy=True) == {
		'server': 'http://proxy.example.com:7890',
		'username': 'user@mail',
		'password': 'p@ss',
	}


def test_playwright_proxy_without_auth(monkeypatch):
	monkeypatch.setenv('CHECKIN_PROXY_URL', 'http://127.0.0.1:7890')
	assert get_playwright_proxy(use_proxy=True) == {'server': 'http://127.0.0.1:7890'}


def test_playwright_proxy_disabled(monkeypatch):
	monkeypatch.setenv('CHECKIN_PROXY_URL', 'http://user:pass@proxy.example.com:27890')
	assert get_playwright_proxy(use_proxy=False) is None
