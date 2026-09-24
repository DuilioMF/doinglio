@echo off
setlocal EnableExtensions
set "ROOT=C:\Sistemas\DoingLioLauncher"
set "LAUNCHER=%ROOT%\doinglio_launcher.ps1"
set "RAW=https://raw.githubusercontent.com/DuilioMF/doinglio/main/launcher/doinglio_launcher.ps1"
set "CLOUD=https://duiliomf.github.io/doinglio/?desktop=1&build=18"

if not exist "C:\Sistemas" mkdir "C:\Sistemas" >nul 2>nul
if not exist "%ROOT%" mkdir "%ROOT%" >nul 2>nul

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; try { Invoke-WebRequest -UseBasicParsing -Uri '%RAW%?v=18' -OutFile '%LAUNCHER%' } catch {}"

if /I "%DOINGLIO_CI%"=="1" (
  if exist "%LAUNCHER%" exit /b 0
  exit /b 1
)

if exist "%LAUNCHER%" (
  start "" powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%LAUNCHER%"
) else (
  start "" "%CLOUD%"
)
exit /b 0
