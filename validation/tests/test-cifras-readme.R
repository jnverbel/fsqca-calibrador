source("validation/R/cifras-readme.R")

falla <- function(expr) inherits(tryCatch(force(expr), error = identity), "error")

# --- 1. El detector, sobre un par de README sintéticos --------------------
#
# La pareja de casos opuestos va aquí y no sobre los README de verdad porque
# aquí se controla el dato: se sabe cuál es el recuento y se puede mover el
# PARÁMETRO —el número que se exige— sin tocar el documento.
raiz <- file.path(tempdir(), "cifras-readme")
dir.create(raiz, showWarnings = FALSE)
on.exit(unlink(raiz, recursive = TRUE), add = TRUE)
escribir <- function(es, en) {
  writeLines(es, file.path(raiz, "README.es.md"), useBytes = TRUE)
  writeLines(en, file.path(raiz, "README.md"), useBytes = TRUE)
}

escribir(c("Las suites suman **1.234 pruebas de motor** y **56 pruebas de interfaz**."),
         c("The suites hold **1,234 engine tests** and **56 interface tests**."))

# Donde toca aprobar, aprueba.
stopifnot(isTRUE(exigir_cifras_readme(motor = 1234L, interfaz = 56L, raiz = raiz)))
stopifnot(isTRUE(exigir_cifras_readme(motor = 1234L, raiz = raiz)))
stopifnot(isTRUE(exigir_cifras_readme(interfaz = 56L, raiz = raiz)))

# Donde toca rechazar, rechaza. Sin esta mitad un detector mudo pasaría igual.
stopifnot(falla(exigir_cifras_readme(motor = 1235L, interfaz = 56L, raiz = raiz)))
stopifnot(falla(exigir_cifras_readme(motor = 1234L, interfaz = 57L, raiz = raiz)))
stopifnot(falla(exigir_cifras_readme(motor = 123L, raiz = raiz)))
stopifnot(falla(exigir_cifras_readme(raiz = raiz)))

# El separador de miles es parte del literal: la cifra inglesa en el README
# español no vale, y al revés tampoco.
escribir(c("**1,234 pruebas de motor** y **56 pruebas de interfaz**."),
         c("**1,234 engine tests** and **56 interface tests**."))
stopifnot(falla(exigir_cifras_readme(motor = 1234L, raiz = raiz)))

# Publicar la cifra vieja y la nueva a la vez tiene que fallar: si bastara con
# «aparece al menos una vez», se podría precargar el documento con las dos y
# después borrar la buena sin que nada chillara.
escribir(c("**1.234 pruebas de motor**, antes **1.200 pruebas de motor**;",
           "**56 pruebas de interfaz**."),
         c("**1,234 engine tests**, previously **1,200 engine tests**;",
           "**56 interface tests**."))
stopifnot(isTRUE(exigir_cifras_readme(motor = 1234L, interfaz = 56L, raiz = raiz)))
stopifnot(isTRUE(exigir_cifras_readme(motor = 1200L, raiz = raiz)))
escribir(c("**1.234 pruebas de motor** y **1.234 pruebas de motor**;",
           "**56 pruebas de interfaz**."),
         c("**1,234 engine tests** and **1,234 engine tests**;",
           "**56 interface tests**."))
stopifnot(falla(exigir_cifras_readme(motor = 1234L, raiz = raiz)))

# Dos apariciones en la MISMA línea también son dos: contar líneas no basta.
escribir(c("**1.234 pruebas de motor** y otra vez **1.234 pruebas de motor**. **56 pruebas de interfaz**."),
         c("**1,234 engine tests** and again **1,234 engine tests**. **56 interface tests**."))
stopifnot(falla(exigir_cifras_readme(motor = 1234L, raiz = raiz)))

# --- 2. Los README de verdad ---------------------------------------------
#
# El anclaje al recuento REAL lo hacen quienes lo miden: el trabajo `testthat`
# del CI, que llama a `exigir_cifras_readme(motor = sum(r$passed))` con la
# corrida que acaba de terminar, y `tests/interfaz.R`, que hace lo propio con
# la suya. Aquí no se corre ninguna suite; lo que se comprueba es que los dos
# README publiquen la MISMA cifra, que es la mitad que el CI no ve —un cambio
# coordinado en un solo idioma pasa desapercibido hasta que alguien lo lee.
motor_es <- cifra_publicada_readme("README.es.md", "\\*\\*[0-9.]+ pruebas de motor\\*\\*")
motor_en <- cifra_publicada_readme("README.md", "\\*\\*[0-9,]+ engine tests\\*\\*")
int_es <- cifra_publicada_readme("README.es.md", "\\*\\*[0-9.]+ pruebas de interfaz\\*\\*")
int_en <- cifra_publicada_readme("README.md", "\\*\\*[0-9,]+ interface tests\\*\\*")
stopifnot(!is.na(motor_es), !is.na(motor_en), !is.na(int_es), !is.na(int_en))
if (!identical(motor_es, motor_en)) {
  stop("Los dos README publican cifras de motor distintas: ", motor_es, " y ",
       motor_en, call. = FALSE)
}
if (!identical(int_es, int_en)) {
  stop("Los dos README publican cifras de interfaz distintas: ", int_es, " y ",
       int_en, call. = FALSE)
}

# Y la pareja de casos opuestos sobre los archivos publicados: la cifra que
# publican los aprueba, y una unidad más los rechaza.
stopifnot(isTRUE(exigir_cifras_readme(motor = motor_es, interfaz = int_es)))
stopifnot(falla(exigir_cifras_readme(motor = motor_es + 1L)))
stopifnot(falla(exigir_cifras_readme(interfaz = int_es + 1L)))

cat(sprintf(paste0("cifras del readme validas: los dos README publican %d pruebas ",
                   "de motor y %d de interfaz; 12 mutaciones rechazadas\n"),
            motor_es, int_es))
