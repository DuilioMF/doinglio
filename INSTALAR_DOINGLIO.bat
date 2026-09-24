@echo off
setlocal EnableExtensions
title Instalar acceso DoingLio

set "ROOT=C:\Sistemas\DoingLioLauncher"
set "LAUNCHER=%ROOT%\doinglio_launcher.ps1"
set "RAW=https://raw.githubusercontent.com/DuilioMF/doinglio/main/launcher/doinglio_launcher.ps1"

if not exist "C:\Sistemas" mkdir "C:\Sistemas" >nul 2>nul
if not exist "%ROOT%" mkdir "%ROOT%" >nul 2>nul

echo.
echo ============================================================
echo              INSTALAR ACCESO DOINGLIO
echo ============================================================
echo.

echo [1/2] Instalando arrancador...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Invoke-WebRequest -UseBasicParsing '%RAW%?ts=' + [DateTime]::UtcNow.Ticks -OutFile '%LAUNCHER%'"
if errorlevel 1 goto :error

echo [2/2] Creando DoingLio.bat en el Escritorio...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$desktop=[Environment]::GetFolderPath('Desktop'); $p=Join-Path $desktop 'DoingLio.bat'; $lines=@('@echo off','setlocal','set ""ROOT=C:\Sistemas\DoingLioLauncher""','set ""LAUNCHER=%%ROOT%%\doinglio_launcher.ps1""','if not exist ""%%ROOT%%"" mkdir ""%%ROOT%%"" ^>nul 2^>nul','powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ""$ErrorActionPreference=''SilentlyContinue''; try { Invoke-WebRequest -UseBasicParsing ''https://raw.githubusercontent.com/DuilioMF/doinglio/main/launcher/doinglio_launcher.ps1?ts='' + [DateTime]::UtcNow.Ticks -OutFile ''C:\Sistemas\DoingLioLauncher\doinglio_launcher.ps1'' } catch {}""','if exist ""%%LAUNCHER%%"" start """""" powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""%%LAUNCHER%%""','if not exist ""%%LAUNCHER%%"" start """""" ""https://duiliomf.github.io/doinglio/?desktop=1""','exit /b 0'); [IO.File]::WriteAllLines($p,$lines,[Text.Encoding]::ASCII); Write-Host $p"
if errorlevel 1 goto :error

echo.
echo Listo. Usa DoingLio.bat del Escritorio.
start "" powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%LAUNCHER%"
timeout /t 1 >nul
exit /b 0

:error
echo.
echo No pude instalar el acceso. No se borro ninguna configuracion.
pause
exit /b 1
