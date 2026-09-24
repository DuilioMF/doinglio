@echo off
setlocal EnableExtensions
title Instalar acceso DoingLio

set "RAW=https://raw.githubusercontent.com/DuilioMF/doinglio/main/DOINGLIO.bat"

echo.
echo ============================================================
echo              INSTALAR ACCESO DOINGLIO
echo ============================================================
echo.

for /f "delims=" %%D in ('powershell.exe -NoProfile -Command "[Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)"') do set "DESKTOP=%%D"
if not defined DESKTOP goto :error

set "DEST=%DESKTOP%\DoingLio.bat"

echo [1/2] Descargando acceso actualizado...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Invoke-WebRequest -UseBasicParsing -Uri '%RAW%?v=18' -OutFile '%DEST%'"
if errorlevel 1 goto :error

if not exist "%DEST%" goto :error

echo [2/2] Acceso creado:
echo       %DEST%
echo.
echo Abriendo DoingLio...
call "%DEST%"
timeout /t 1 >nul
exit /b 0

:error
echo.
echo No pude crear DoingLio.bat en el Escritorio.
echo No se borro ninguna configuracion.
pause
exit /b 1
