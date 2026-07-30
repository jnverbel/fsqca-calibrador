@echo off
REM Calibrador fsQCA - arranque en Windows.
REM
REM Se abre con doble clic. La primera vez instala los paquetes de R que
REM hagan falta (varios minutos); las siguientes arranca en segundos.
REM
REM Los paquetes vienen como binarios ya compilados desde un snapshot con
REM fecha del Posit Package Manager, asi que NO hace falta Rtools.

setlocal enabledelayedexpansion
cd /d "%~dp0"

if "%PUERTO%"=="" set PUERTO=7788

echo.
echo   Calibrador fsQCA
echo   ================
echo.

REM --- 1. Buscar R ------------------------------------------------------

set RSCRIPT=
where Rscript.exe >nul 2>&1 && set RSCRIPT=Rscript.exe

if "!RSCRIPT!"=="" (
  for /d %%D in ("C:\Program Files\R\R-*") do (
    if exist "%%D\bin\Rscript.exe" set RSCRIPT="%%D\bin\Rscript.exe"
  )
)
if "!RSCRIPT!"=="" (
  for /d %%D in ("%LOCALAPPDATA%\Programs\R\R-*") do (
    if exist "%%D\bin\Rscript.exe" set RSCRIPT="%%D\bin\Rscript.exe"
  )
)

if "!RSCRIPT!"=="" (
  echo   No encuentro R en este equipo.
  echo.
  echo   Que hacer:
  echo     1. Abra https://cran.r-project.org/bin/windows/base/
  echo     2. Descargue "Download R for Windows" e instalelo.
  echo        Acepte todas las opciones por defecto.
  echo     3. Vuelva a abrir este archivo.
  echo.
  pause
  exit /b 1
)

echo   R encontrado.

REM --- 2. Paquetes ------------------------------------------------------

if not exist "renv\library" (
  echo.
  echo   Primera vez: voy a instalar los paquetes de R que necesita la
  echo   herramienta. Esto tarda varios minutos y solo pasa una vez.
  echo   Puede dejarlo trabajando.
  echo.
)

!RSCRIPT! -e "quit(status = if (requireNamespace('shiny', quietly = TRUE)) 0 else 1)" >nul 2>&1
if errorlevel 1 (
  echo   Instalando paquetes...
  !RSCRIPT! -e "renv::restore(prompt = FALSE)"
  if errorlevel 1 (
    echo.
    echo   No pude instalar todos los paquetes.
    echo.
    echo   Compruebe que el equipo tiene conexion a internet y que ningun
    echo   antivirus o cortafuegos corporativo esta bloqueando la descarga.
    echo   Si el problema sigue, avise a quien le entrego esta herramienta
    echo   y adjunte lo que aparece en esta ventana.
    echo.
    pause
    exit /b 1
  )
)

REM --- 3. Arrancar ------------------------------------------------------

echo.
echo   Abriendo la herramienta en el navegador...
echo   Direccion: http://127.0.0.1:%PUERTO%
echo.
echo   Para cerrarla: cierre esta ventana negra.
echo.

start "" /b cmd /c "timeout /t 5 >nul & start http://127.0.0.1:%PUERTO%"

!RSCRIPT! app/app.R

echo.
echo   La herramienta se cerro.
pause
