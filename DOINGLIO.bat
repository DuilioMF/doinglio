@echo off
setlocal EnableExtensions
set "ROOT=C:\Sistemas\DoingLioLauncher"
set "LAUNCHER=%ROOT%\doinglio_launcher.ps1"
set "RAW=https://raw.githubusercontent.com/DuilioMF/doinglio/main/launcher/doinglio_launcher.ps1"

if not exist "C:\Sistemas" mkdir "C:\Sistemas" >nul 2>nul
if not exist "%ROOT%" mkdir "%ROOT%" >nul 2>nul

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Invoke-WebRequest -UseBasicParsing -Uri '%RAW%' -OutFile '%LAUNCHER%'"
if errorlevel 1 (
  echo No pude actualizar el arrancador de DoingLio.
  pause
  exit /b 1
)

if /I "%DOINGLIO_CI%"=="1" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER%"
  exit /b %errorlevel%
)

start "" powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%LAUNCHER%"
exit /b 0
