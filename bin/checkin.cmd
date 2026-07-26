@echo off
setlocal EnableExtensions

rem AnyRouter 签到启动脚本（Windows）
rem 用法: bin\checkin.cmd
rem 一次启动 = 一轮签到，结束后退出

set "SCRIPT_DIR=%~dp0"
rem 去掉末尾反斜杠再取上级目录
for %%I in ("%SCRIPT_DIR%..") do set "PROJECT_ROOT=%%~fI"
cd /d "%PROJECT_ROOT%" || (
	echo [ERROR] Failed to enter project root: %PROJECT_ROOT%
	exit /b 1
)

if not exist "%PROJECT_ROOT%\checkin.py" (
	echo [ERROR] checkin.py not found in %PROJECT_ROOT%
	exit /b 1
)

if not exist "%PROJECT_ROOT%\.env" (
	echo [WARN] .env not found. Copy .env.example to .env and configure ANYROUTER_ACCOUNTS.
)

echo [INFO] Project root: %PROJECT_ROOT%
echo [INFO] Starting check-in...

where uv >nul 2>&1
if %ERRORLEVEL%==0 (
	uv run checkin.py %*
	exit /b %ERRORLEVEL%
)

echo [WARN] uv not found, falling back to system Python.

where python >nul 2>&1
if %ERRORLEVEL%==0 (
	python checkin.py %*
	exit /b %ERRORLEVEL%
)

where py >nul 2>&1
if %ERRORLEVEL%==0 (
	py -3 checkin.py %*
	exit /b %ERRORLEVEL%
)

echo [ERROR] Neither uv nor python/py found in PATH.
echo Install uv ^(https://docs.astral.sh/uv/^) or Python 3.11+.
exit /b 1
