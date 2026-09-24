@echo off
setlocal EnableExtensions
title Instalar DoingLio con icono de cerebro

set "ROOT=C:\Sistemas\DoingLioLauncher"
set "INSTALLER=%ROOT%\instalar_acceso.ps1"
set "RAW=https://raw.githubusercontent.com/DuilioMF/doinglio/main/launcher/instalar_acceso.ps1"

if not exist "%ROOT%" mkdir "%ROOT%"
if errorlevel 1 goto :error

echo.
echo ======================================
echo   DOINGLIO - ACCESO DE ESCRITORIO
echo ======================================
echo.
echo Instalando el icono de cerebro...

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Invoke-WebRequest -UseBasicParsing -Uri '%RAW%' -OutFile '%INSTALLER%' -TimeoutSec 40"
if errorlevel 1 goto :error

if /I "%DOINGLIO_CI%"=="1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%INSTALLER%" -NoLaunch
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%INSTALLER%"
)
if errorlevel 1 goto :error

echo Listo. Usa el acceso DoingLio con icono de cerebro del Escritorio.
exit /b 0

:error
echo No se pudo instalar. Log: %ROOT%\instalador.log
pause
exit /b 1
