@echo off
setlocal EnableExtensions
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
echo [1/3] Actualizando acceso SQL...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Invoke-WebRequest -UseBasicParsing '%CAPRAW%/bridge/capitan_rodolfo_local.ps1' -OutFile '%BRIDGE%'; Invoke-WebRequest -UseBasicParsing '%CAPRAW%/VERSION' -OutFile '%VERSION_FILE%'; Invoke-WebRequest -UseBasicParsing '%CAPRAW%/sp_allowlist.json' -OutFile '%ALLOWLIST%'" >>"%LOG%" 2>&1
if errorlevel 1 (
  echo       No pude actualizar ahora; uso la copia existente.
)

echo [2/3] Iniciando SQL Server en segundo plano...
if exist "%BRIDGE%" (
  start "" powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%BRIDGE%" -AppDir "%CONNECTOR%" -BackgroundChild
) else (
  echo       AVISO: falta el componente SQL local.
  echo [%date% %time%] Falta %BRIDGE% >>"%LOG%"
)

echo [3/3] Abriendo DoingLio en la nube...
start "" "%CLOUD%"

rem Diagnostico asincrono: nunca bloquea el acceso.
start "" /min powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "Start-Sleep -Seconds 4; $ports=8787,8797,18787,27877,37877,48787,57877; $found=$null; foreach($p in $ports){try{$c=New-Object Net.Sockets.TcpClient; $ar=$c.BeginConnect('127.0.0.1',$p,$null,$null); if($ar.AsyncWaitHandle.WaitOne(180)){ $c.EndConnect($ar); $found=$p; $c.Close(); break }; $c.Close()}catch{}}; Add-Content -Path '%LOG%' -Value ('['+(Get-Date).ToString('s')+'] Puerto SQL: '+($(if($found){$found}else{'sin respuesta'})))"

timeout /t 1 >nul
exit /b 0
