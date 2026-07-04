@echo off
echo ============================================================
echo  COMPILANDO SANEAPP PRO - Debug APK
echo  Optimizado para 4GB RAM
echo ============================================================
echo.

cd /d C:\StudioProjects\saneapp_pro_nuevo\android

echo Deteniendo daemons previos...
call gradlew.bat --stop 2>nul

echo.
echo Compilando...
call gradlew.bat assembleDebug --no-daemon --max-workers=1 --console=plain --stacktrace > ..\build_output.log 2>&1

if %ERRORLEVEL%==0 (
    echo.
    echo ============================================================
    echo  BUILD EXITOSO
    echo  APK en: android\app\build\outputs\apk\debug\app-debug.apk
    echo ============================================================
) else (
    echo.
    echo ============================================================
    echo  BUILD FALLIDO - revisa build_output.log
    echo ============================================================
    echo.
    echo === ULTIMAS 60 LINEAS DEL ERROR: ===
    powershell -Command "Get-Content '..\build_output.log' | Select-String -Pattern 'FAILURE|error|Could not|Exception' | Select-Object -Last 30"
)

echo.
echo Log completo: C:\StudioProjects\saneapp_pro_nuevo\build_output.log
pause
