@echo off
setlocal EnableExtensions
title Instalar DoingLio local

set "TARGET=C:\Sistemas\doinglio"
set "REMOTE=https://github.com/DuilioMF/doinglio.git"

echo.
echo ============================================================
echo                 INSTALAR DOINGLIO LOCAL
echo ============================================================
echo.
echo Destino: %TARGET%
echo.

where git >nul 2>nul
if errorlevel 1 (
  echo ERROR: Git no esta instalado o no esta en PATH.
  echo Instala Git para Windows y volve a ejecutar este archivo.
  pause
  exit /b 1
)

if not exist "C:\Sistemas" mkdir "C:\Sistemas" >nul 2>nul
if not exist "C:\Sistemas" (
  echo Se necesitan permisos para crear C:\Sistemas.
  echo Windows va a pedir autorizacion...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

if exist "%TARGET%\.git" goto :update

if exist "%TARGET%" (
  dir /b "%TARGET%" 2>nul | findstr . >nul
  if not errorlevel 1 (
    echo.
    echo ERROR: %TARGET% ya existe pero no es un repositorio Git.
    echo No voy a borrar ni pisar tus archivos.
    echo Renombra esa carpeta y vuelve a ejecutar este instalador.
    pause
    exit /b 1
  )
)

echo [1/3] Clonando DoingLio...
git clone "%REMOTE%" "%TARGET%"
if errorlevel 1 goto :fatal
goto :run

:update
echo [1/3] Actualizando DoingLio...
git -C "%TARGET%" pull --ff-only
if errorlevel 1 (
  echo AVISO: no se pudo actualizar DoingLio.
  echo Se intentara abrir la copia local existente.
)

:run
echo [2/3] Preparando especialistas...
if not exist "%TARGET%\DOINGLIO.bat" goto :fatal

echo [3/3] Abriendo DoingLio local...
call "%TARGET%\DOINGLIO.bat"
exit /b %errorlevel%

:fatal
echo.
echo ============================================================
echo NO SE PUDO INSTALAR / ABRIR DOINGLIO
echo ============================================================
echo.
pause
exit /b 1
