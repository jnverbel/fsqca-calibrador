#!/bin/bash
# Calibrador fsQCA — arranque en macOS.
#
# Se abre con doble clic desde el Finder. La primera vez instala los
# paquetes de R que hagan falta (varios minutos); las siguientes arranca
# en segundos.
#
# Todo mensaje va en espanol y dice QUE hacer, no solo que algo fallo:
# quien usa esto trabaja solo y no escribe R.

cd "$(dirname "$0")" || exit 1

PUERTO="${PUERTO:-7788}"

echo ""
echo "  Calibrador fsQCA"
echo "  ================"
echo ""

# --- 1. ¿Esta R instalado? --------------------------------------------

if ! command -v Rscript >/dev/null 2>&1; then
  # R de CRAN se instala en el framework, que no siempre entra en el PATH
  # del Finder aunque funcione en la Terminal.
  for ruta in /Library/Frameworks/R.framework/Resources/bin /opt/homebrew/bin /usr/local/bin; do
    if [ -x "$ruta/Rscript" ]; then
      export PATH="$ruta:$PATH"
      break
    fi
  done
fi

if ! command -v Rscript >/dev/null 2>&1; then
  echo "  No encuentro R en este equipo."
  echo ""
  echo "  Que hacer:"
  echo "    1. Abra https://cran.r-project.org/bin/macosx/"
  echo "    2. Descargue el instalador que corresponda a su Mac"
  echo "       (Apple Silicon si su Mac es M1 o posterior)."
  echo "    3. Instalelo y vuelva a abrir este archivo."
  echo ""
  read -r -p "  Pulse Intro para cerrar."
  exit 1
fi

echo "  R encontrado: $(Rscript -e 'cat(R.version.string)' 2>/dev/null)"

# --- 2. Paquetes -------------------------------------------------------

if [ ! -d "renv/library" ]; then
  echo ""
  echo "  Primera vez: voy a instalar los paquetes de R que necesita la"
  echo "  herramienta. Esto tarda varios minutos y solo pasa una vez."
  echo "  Puede dejarlo trabajando."
  echo ""
fi

if ! Rscript -e 'quit(status = if (requireNamespace("shiny", quietly = TRUE)) 0 else 1)' 2>/dev/null; then
  echo "  Instalando paquetes..."
  if ! Rscript -e 'renv::restore(prompt = FALSE)'; then
    echo ""
    echo "  No pude instalar todos los paquetes."
    echo ""
    echo "  La causa mas frecuente en Mac es que falten las herramientas de"
    echo "  compilacion. Para instalarlas, abra la aplicacion Terminal y"
    echo "  escriba esta linea:"
    echo ""
    echo "      xcode-select --install"
    echo ""
    echo "  Acepte la instalacion, espere a que termine y vuelva a abrir"
    echo "  este archivo."
    echo ""
    read -r -p "  Pulse Intro para cerrar."
    exit 1
  fi
fi

# --- 3. Arrancar -------------------------------------------------------

echo ""
echo "  Abriendo la herramienta en el navegador..."
echo "  Direccion: http://127.0.0.1:$PUERTO"
echo ""
echo "  Para cerrarla: cierre esta ventana negra."
echo ""

# SIN_NAVEGADOR=1 arranca sin abrir nada, util cuando ya se tiene la
# pestana abierta o al probar el guion.
if [ -z "$SIN_NAVEGADOR" ]; then
  ( sleep 4; open "http://127.0.0.1:$PUERTO" ) &
fi

PUERTO="$PUERTO" Rscript app/app.R

echo ""
read -r -p "  La herramienta se cerro. Pulse Intro para salir."
