source("renv/activate.R")
# Repositorio de CRAN fijo: en modo no interactivo R no tiene de donde bajar
# paquetes si no se declara aqui.
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Este R es el de Homebrew y compila desde fuente. Compilar en paralelo
# ahorra bastante en lavaan, readr y testthat.
options(Ncpus = max(1L, parallel::detectCores() - 1L))
