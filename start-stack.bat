@echo off
REM ---------------------------------------------------------------
REM  Arranca el stack OpenWA + proyecto basico de pruebas.
REM  Doble clic o ejecutar desde una consola.
REM ---------------------------------------------------------------

echo Arrancando gateway OpenWA (puerto 2785)...
cd /d C:\openwa
start "OpenWA Gateway" /min cmd /c "npm run start:dev > openwa.out.log 2>&1"

timeout /t 3 /nobreak >nul

echo Arrancando proyecto OpenWA Basico (puerto 8020)...
cd /d C:\xampp_82_12\htdocs\openwa_basico
start "OpenWA Basico" /min cmd /c "php artisan serve --port=8020 > storage\logs\serve.out.log 2>&1"

echo Arrancando worker de cola (envios en background)...
start "OpenWA Basico Queue" /min cmd /c "php artisan queue:work --tries=3 --timeout=120 --sleep=1 > storage\logs\queue.out.log 2>&1"

echo.
echo Listo. En unos segundos:
echo   Proyecto:  http://localhost:8020   (admin@basico.test / admin123)
echo   Gateway:   http://localhost:2785
echo.
echo Para detenerlos, cerra las ventanas minimizadas "OpenWA Gateway", "OpenWA Basico" y "OpenWA Basico Queue".
