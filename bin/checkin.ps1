# AnyRouter 签到启动脚本（Windows PowerShell）
# 用法: .\bin\checkin.ps1
# 一次启动 = 一轮签到，结束后退出

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = (Resolve-Path (Join-Path $ScriptDir '..')).Path
Set-Location $ProjectRoot

if (-not (Test-Path (Join-Path $ProjectRoot 'checkin.py'))) {
	Write-Error "checkin.py not found in $ProjectRoot"
	exit 1
}

if (-not (Test-Path (Join-Path $ProjectRoot '.env'))) {
	Write-Warning '.env not found. Copy .env.example to .env and configure ANYROUTER_ACCOUNTS.'
}

Write-Host "[INFO] Project root: $ProjectRoot"
Write-Host '[INFO] Starting check-in...'

function Test-Command {
	param([string]$Name)
	return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

if (Test-Command 'uv') {
	& uv run checkin.py @args
	exit $LASTEXITCODE
}

Write-Warning 'uv not found, falling back to system Python.'

if (Test-Command 'python') {
	& python checkin.py @args
	exit $LASTEXITCODE
}

if (Test-Command 'py') {
	& py -3 checkin.py @args
	exit $LASTEXITCODE
}

Write-Error 'Neither uv nor python/py found in PATH. Install uv (https://docs.astral.sh/uv/) or Python 3.11+.'
exit 1
