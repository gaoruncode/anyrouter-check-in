@echo off
setlocal EnableExtensions

rem 最简 gost HTTP 代理启动脚本（Windows）
rem 1. 把 gost.exe 和本脚本放在同一目录
rem 2. 修改下面 USER / PASS / PORT
rem 3. 双击运行，或加入任务计划程序「登录时启动」

set "GOST_USER=checkin"
set "GOST_PASS=请改成超长随机密码"
set "GOST_PORT=7890"

cd /d "%~dp0"

if not exist "%~dp0gost.exe" (
	echo [ERROR] gost.exe not found in %~dp0
	echo Download from https://github.com/go-gost/gost/releases
	exit /b 1
)

if "%GOST_PASS%"=="请改成超长随机密码" (
	echo [ERROR] Please edit GOST_PASS in this script before starting.
	exit /b 1
)

echo [INFO] Starting gost HTTP proxy on 0.0.0.0:%GOST_PORT%
echo [INFO] Auth user: %GOST_USER%
echo [INFO] Keep this window open. Press Ctrl+C to stop.

"%~dp0gost.exe" -L "http://%GOST_USER%:%GOST_PASS%@:%GOST_PORT%"
exit /b %ERRORLEVEL%
