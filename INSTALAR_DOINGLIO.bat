@echo off
setlocal EnableExtensions
title Instalar acceso DoingLio

set "LAUNCHERDIR=C:\Sistemas\DoingLioLauncher"
set "RUNNER=%LAUNCHERDIR%\DOINGLIO.bat"
set "RAW=https://raw.githubusercontent.com/DuilioMF/doinglio/main/DOINGLIO.bat"

if not exist "C:\Sistemas" mkdir "C:\Sistemas" >nul 2>nul
if not exist "%LAUNCHERDIR%" mkdir "%LAUNCHERDIR%" >nul 2>nul

echo.
echo ============================================================
echo              INSTALAR ACCESO DE ESCRITORIO
echo                         DOINGLIO
echo ============================================================
echo.

echo [1/3] Preparando arrancador...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Invoke-WebRequest -UseBasicParsing '%RAW%' -OutFile '%RUNNER%'"
if errorlevel 1 goto :error

echo [2/3] Creando DoingLio.bat en el Escritorio...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$desktop=[Environment]::GetFolderPath('Desktop'); $p=Join-Path $desktop 'DoingLio.bat'; $lines=@('@echo off','setlocal','set ""RUNNER=C:\Sistemas\DoingLioLauncher\DOINGLIO.bat""','powershell -NoProfile -ExecutionPolicy Bypass -Command ""try { Invoke-WebRequest -UseBasicParsing ''https://raw.githubusercontent.com/DuilioMF/doinglio/main/DOINGLIO.bat'' -OutFile ''C:\Sistemas\DoingLioLauncher\DOINGLIO.bat'' } catch {}""','if exist ""%%RUNNER%%"" call ""%%RUNNER%%""','exit /b 0'); [IO.File]::WriteAllLines($p,$lines,[Text.Encoding]::ASCII); Write-Host $p"
if errorlevel 1 goto :error

echo [3/3] Listo. A partir de ahora usa DoingLio.bat del Escritorio.
echo.
call "%RUNNER%"
exit /b 0

:error
echo.
echo No pude crear el acceso de DoingLio.
echo No se borro ninguna configuracion existente.
pause
exit /b 1
