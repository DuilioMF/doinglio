@echo off
setlocal EnableExtensions EnableDelayedExpansion
title DoingLio local

for %%I in ("%~dp0.") do set "APPROOT=%%~fI"
set "CAPDIR=%APPROOT%\capitan-rodolfo"
set "RUBENDIR=%APPROOT%\ruben"
set "WEBPORT=8790"
set "CAPPORT=8787"

echo.
echo ============================================================
echo                    DOINGLIO LOCAL
echo ============================================================
echo Carpeta: %APPROOT%
echo.

where git >nul 2>nul
if errorlevel 1 (
  echo ERROR: Git no esta instalado o no esta en PATH.
  pause
  exit /b 1
)

echo [1/5] Actualizando DoingLio...
git -C "%APPROOT%" pull --ff-only
if errorlevel 1 echo AVISO: DoingLio no pudo hacer pull. Se conserva la copia local.

echo [2/5] Actualizando Capitán Rodolfo...
call :sync_repo "%CAPDIR%" "https://github.com/DuilioMF/capitan-rodolfo.git"

echo [3/5] Actualizando Ruben...
call :sync_repo "%RUBENDIR%" "https://github.com/DuilioMF/ruben.git"

echo [4/5] Iniciando conector SQL de Capitán...
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":%CAPPORT% .*LISTENING"') do taskkill /PID %%P /F >nul 2>nul
if exist "%CAPDIR%\bridge\capitan_rodolfo_local.ps1" (
  start "Capitan Rodolfo SQL" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%CAPDIR%\bridge\capitan_rodolfo_local.ps1" -AppDir "%CAPDIR%"
  set "CAPREADY=0"
  for /L %%I in (1,1,20) do (
    curl.exe --silent --fail "http://127.0.0.1:%CAPPORT%/health" >nul 2>nul
    if not errorlevel 1 (
      set "CAPREADY=1"
      goto :capready
    )
    timeout /t 1 >nul
  )
  :capready
  if "!CAPREADY!"=="1" (
    echo       Conector SQL de Capitan listo.
  ) else (
    echo AVISO: el conector SQL de Capitan no respondio. Podes revisar Nucleo - Datos.
  )
) else (
  echo AVISO: no encontre el bridge de Capitan en %CAPDIR%.
)

echo [5/5] Iniciando DoingLio web local...
set "PY="
where py >nul 2>nul
if not errorlevel 1 set "PY=py"
if not defined PY (
  where python >nul 2>nul
  if not errorlevel 1 set "PY=python"
)
if not defined PY (
  echo ERROR: No encuentro Python para servir DoingLio local.
  pause
  exit /b 1
)

for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":%WEBPORT% .*LISTENING"') do taskkill /PID %%P /F >nul 2>nul
start "DoingLio Web Local" /min %PY% -m http.server %WEBPORT% --bind 127.0.0.1 --directory "%APPROOT%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ok=$false;1..15|%%{try{$r=Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:%WEBPORT%/BUILD' -TimeoutSec 1;if($r.StatusCode -eq 200){$ok=$true;break}}catch{};Start-Sleep -Milliseconds 400};if(-not $ok){exit 1}"
if errorlevel 1 (
  echo ERROR: DoingLio local no respondio en el puerto %WEBPORT%.
  pause
  exit /b 1
)

start "" "http://127.0.0.1:%WEBPORT%/"
exit /b 0

:sync_repo
set "TARGET=%~1"
set "REMOTE=%~2"
if exist "%TARGET%\.git" (
  git -C "%TARGET%" pull --ff-only
  if errorlevel 1 echo AVISO: no se pudo actualizar %TARGET%; se conserva la copia local.
  exit /b 0
)
if exist "%TARGET%" (
  echo AVISO: %TARGET% existe pero no es un repositorio Git.
  echo        No la borro ni la piso. Renombrala o movela para que DoingLio pueda clonarla.
  exit /b 0
)
git clone "%REMOTE%" "%TARGET%"
if errorlevel 1 echo ERROR: no se pudo clonar %REMOTE%.
exit /b 0
