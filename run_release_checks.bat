@echo off
setlocal

set "ROOT=%~dp0"
cd /d "%ROOT%"

echo ==============================================
echo SaneApp - Release Checks
echo ==============================================

echo [1/4] Flutter pub get
call .\flutterw.bat pub get
if errorlevel 1 goto :fail

echo [2/4] Flutter analyze (codigo principal)
call .\flutterw.bat analyze lib test
if errorlevel 1 goto :fail

echo [3/4] Unit tests estables
call .\flutterw.bat test test\services\payment_service_test.dart
if errorlevel 1 goto :fail
call .\flutterw.bat test test\register_page_test.dart
if errorlevel 1 goto :fail
call .\flutterw.bat test test\provider_flow_test.dart
if errorlevel 1 goto :fail

echo [4/4] Integracion critica
call .\flutterw.bat test test\integration\onboarding_login_home_flow_test.dart
if errorlevel 1 goto :fail
call .\flutterw.bat test test\integration\app_startup_test.dart
if errorlevel 1 goto :fail
call .\flutterw.bat test test\integration\provider_registration_flow_test.dart
if errorlevel 1 goto :fail

echo.
echo ==============================================
echo Release checks OK
echo ==============================================
exit /b 0

:fail
echo.
echo ==============================================
echo Release checks FAILED
echo ==============================================
exit /b 1
