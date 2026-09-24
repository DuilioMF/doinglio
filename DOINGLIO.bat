@echo off
setlocal
set "ROOT=C:\Sistemas\DoingLioLauncher"
set "LAUNCHER=%ROOT%\doinglio_launcher.ps1"
set "RAW=https://raw.githubusercontent.com/DuilioMF/doinglio/main/launcher/doinglio_launcher.ps1"

if not exist "%ROOT%" mkdir "%ROOT%" >nul 2>nul

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; try { Invoke-WebRequest -UseBasicParsing '%RAW%?ts=' + [DateTime]::UtcNow.Ticks -OutFile '%LAUNCHER%' } catch {}"

if exist "%LAUNCHER%" (
  start "" powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%LAUNCHER%"
) else (
  start "" "https://duiliomf.github.io/doinglio/?desktop=1"
)
exit /b 0
