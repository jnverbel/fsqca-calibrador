# Diagnostico de la interfaz bajo CI.
#
# No es una prueba: no afirma nada. Abre la aplicacion y describe que hay
# en la pagina antes y despues de esperar a que Shiny quede ocioso, para
# saber si un uiOutput vacio es un fallo del servidor o una carrera.
#
#   Rscript tests/diagnostico-interfaz.R

Sys.setenv(NOT_CRAN = "true")
library(shinytest2)

describir <- function(app, momento) {
  cat("\n===== ", momento, " =====\n", sep = "")
  for (sel in c("h1", "#regla_pasos", ".pasos", "#panel_paso")) {
    h <- tryCatch(app$get_html(sel), error = function(e) NULL)
    cat(sprintf("  %-14s %s\n", sel,
                if (is.null(h) || !length(h)) "<SIN NODO>"
                else paste0(nchar(h), " car: ",
                            substr(gsub("[[:space:]]+", " ",
                                        gsub("<[^>]+>", " ", h)), 1, 90))))
  }
  v <- tryCatch(app$get_values(), error = function(e) NULL)
  if (!is.null(v)) {
    cat("  inputs :", paste(names(v$input), collapse = ", "), "\n")
    cat("  outputs:", paste(names(v$output), collapse = ", "), "\n")
  }
}

cat("Chrome:", chromote::find_chrome(), "\n")
cat("CLAVE_APP definida:", nzchar(Sys.getenv("CLAVE_APP")), "\n")

app <- AppDriver$new(app_dir = ".", name = "diag",
                     width = 1400, height = 900,
                     load_timeout = 90 * 1000, timeout = 30 * 1000)

describir(app, "recien abierta")

app$wait_for_idle(timeout = 30 * 1000)
describir(app, "tras wait_for_idle")

Sys.sleep(5)
describir(app, "tras cinco segundos mas")

cat("\n===== registro del servidor =====\n")
print(utils::tail(app$get_logs(), 40))

app$stop()
