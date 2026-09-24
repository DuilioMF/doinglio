@echo off
setlocal EnableExtensions EnableDelayedExpansion
title DoingLio

set "CONNECTOR=C:\Sistemas\DoingLioConnector"
set "BRIDGEDIR=%CONNECTOR%\bridge"
set "BRIDGE=%BRIDGEDIR%\capitan_rodolfo_local.ps1"
set "VERSION_FILE=%CONNECTOR%\VERSION"
set "ALLOWLIST=%CONNECTOR%\sp_allowlist.json"
set "LOG=%CONNECTOR%\doinglio_start.log"
set "CAPRAW=https://raw.githubusercontent.com/DuilioMF/capitan-rodolfo/main"
set "CLOUD=https://duiliomf.github.io/doinglio/?desktop=1"

if not exist "C:\Sistemas" mkdir "C:\Sistemas" >nul 2>nul
if not exist "%CONNECTOR%" mkdir "%CONNECTOR%" >nul 2>nul
if not exist "%BRIDGEDIR%" mkdir "%BRIDGEDIR%" >nul 2>nul

> "%LOG%" echo [%date% %time%] Inicio DoingLio

echo.
echo ============================================================
echo                         DOINGLIO
echo ============================================================
echo.
echo [1/3] Actualizando conector SQL...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Invoke-WebRequest -UseBasicParsing '%CAPRAW%/bridge/capitan_rodolfo_local.ps1' -OutFile '%BRIDGE%'; Invoke-WebRequest -UseBasicParsing '%CAPRAW%/VERSION' -OutFile '%VERSION_FILE%'; Invoke-WebRequest -UseBasicParsing '%CAPRAW%/sp_allowlist.json' -OutFile '%ALLOWLIST%'" >>"%LOG%" 2>&1
if errorlevel 1 (
  echo AVISO: no pude actualizar el conector. Intento usar la copia existente.
)

set "ACTIVE_PORT="
for /f "delims=" %%Q in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$ports=8787,8797,18787,27877,37877,48787,57877; foreach($p in $ports){ try{$r=Invoke-RestMethod -Uri ('http://127.0.0.1:'+ $p +'/health') -TimeoutSec 1; if($r.ok){Write-Output $p; break}}catch{}}"') do set "ACTIVE_PORT=%%Q"

if not defined ACTIVE_PORT (
  echo [2/3] Iniciando acceso a SQL Server...
  if exist "%BRIDGE%" (
    start "" powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%BRIDGE%" -AppDir "%CONNECTOR%"
    for /L %%I in (1,1,20) do (
      if not defined ACTIVE_PORT (
        for /f "delims=" %%Q in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$ports=8787,8797,18787,27877,37877,48787,57877; foreach($p in $ports){ try{$r=Invoke-RestMethod -Uri ('http://127.0.0.1:'+ $p +'/health') -TimeoutSec 1; if($r.ok){Write-Output $p; break}}catch{}}"') do set "ACTIVE_PORT=%%Q"
        if not defined ACTIVE_PORT timeout /t 1 >nul
      )
    )
  )
) else (
  echo [2/3] Conector SQL ya estaba activo.
)

if defined ACTIVE_PORT (
  echo [%date% %time%] Conector activo puerto !ACTIVE_PORT! >>"%LOG%"
  echo       SQL local disponible.
) else (
  echo [%date% %time%] AVISO: conector SQL no respondio >>"%LOG%"
  echo       AVISO: la pagina va a abrir, pero el SQL puede figurar desconectado.
)

echo [3/3] Abriendo DoingLio en la nube...
start "" "%CLOUD%"
timeout /t 1 >nul
exit /b 0
