source("renv/activate.R")

# Repositorio: un SNAPSHOT con fecha del Posit Package Manager, no CRAN.
#
# CRAN solo sirve como binario la ULTIMA version de cada paquete. En cuanto
# QCA pase de 3.25 a 3.26, un renv::restore() en Windows no encontraria el
# binario de la version clavada e intentaria compilar desde fuente, lo que
# exige instalar Rtools. Compilar lavaan, stringi o Matrix sin el falla.
#
# El snapshot con fecha congela el estado del repositorio: sirve binarios de
# Windows y Linux de las versiones exactas del lockfile, para siempre.
#
# En macOS el snapshot entrega fuente; los paquetes de R puro se instalan
# igual, y para los que llevan C hace falta Xcode Command Line Tools
# (xcode-select --install). El guion de arranque lo detecta y lo dice.
options(repos = c(
  CRAN = "https://packagemanager.posit.co/cran/2026-07-30"
))

# P3M entrega binarios solo si R se identifica; sin esto devuelve fuente
# incluso en Windows.
options(HTTPUserAgent = sprintf(
  "R/%s R (%s)", getRversion(),
  paste(getRversion(), R.version["platform"], R.version["arch"],
        R.version["os"])))

# Este R compila cuando toca. Hacerlo en paralelo ahorra bastante.
options(Ncpus = max(1L, parallel::detectCores() - 1L))
