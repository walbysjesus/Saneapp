@echo off
setlocal enabledelayedexpansion

set "PROJECT_DIR=%~dp0"
set "LOCAL_PROPERTIES=%PROJECT_DIR%android\local.properties"
set "FLUTTER_BIN="

if exist "%LOCAL_PROPERTIES%" (
  for /f "usebackq tokens=1,* delims==" %%A in ("%LOCAL_PROPERTIES%") do (
    if /i "%%A"=="flutter.sdk" (
      set "FLUTTER_SDK=%%B"
    )
  )
)

if defined FLUTTER_SDK (
  set "FLUTTER_SDK=!FLUTTER_SDK:\\=\!"
  set "FLUTTER_BIN=!FLUTTER_SDK!\bin\flutter.bat"
)

if defined FLUTTER_BIN if exist "!FLUTTER_BIN!" (
  call "!FLUTTER_BIN!" %*
  exit /b %errorlevel%
)

echo [flutterw] No se encontro flutter.sdk en android\local.properties o la ruta no existe.
echo [flutterw] Intentando usar flutter del PATH...
call flutter %*
exit /b %errorlevel%
