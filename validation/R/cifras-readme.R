# Las cifras de pruebas que publican los dos README, atadas al recuento REAL.
#
# Por qué existe. Los README anunciaban «660 pruebas, 18 de interfaz» mucho
# después de que fueran 891 y 81, y nadie se enteró: el flujo comprueba fallos
# y omisiones, no las cifras de la portada. Es el caso exacto de la única
# documentación que miente sin avisar, porque no se regenera de nada.
#
# Cómo se ata. Las frases NO se cotejan a ojo ni se buscan con una expresión
# regular permisiva: se GENERAN a partir del número que acaba de medir la
# suite y se exigen literales. El llamador de verdad es el flujo de CI —que
# pasa `sum(r$passed)` de la corrida que acaba de terminar— y `tests/interfaz.R`,
# que hace lo mismo con su propio recuento. Este archivo no cuenta nada: sólo
# sabe qué frase corresponde a un número.
#
# Se exige UNA sola aparición, no «al menos una». Con «al menos una» se puede
# publicar la cifra vieja y la nueva a la vez y pasar en verde, y después
# borrar la buena sin tocar nada que muerda.

.miles <- function(x, separador) {
  gsub("(\\d)(?=(\\d{3})+$)", paste0("\\1", separador),
       as.character(as.integer(x)), perl = TRUE)
}

# Las frases que cada README tiene que publicar para un recuento dado.
# Devuelve una lista de pares (archivo, literal).
frases_cifras_readme <- function(motor = NULL, interfaz = NULL) {
  f <- list()
  if (!is.null(motor)) {
    f[[length(f) + 1L]] <- list(archivo = "README.es.md",
                                literal = sprintf("**%s pruebas de motor**", .miles(motor, ".")))
    f[[length(f) + 1L]] <- list(archivo = "README.md",
                                literal = sprintf("**%s engine tests**", .miles(motor, ",")))
  }
  if (!is.null(interfaz)) {
    f[[length(f) + 1L]] <- list(archivo = "README.es.md",
                                literal = sprintf("**%s pruebas de interfaz**", .miles(interfaz, ".")))
    f[[length(f) + 1L]] <- list(archivo = "README.md",
                                literal = sprintf("**%s interface tests**", .miles(interfaz, ",")))
  }
  f
}

# Cuántas veces aparece un literal en un archivo, contando APARICIONES y no
# líneas: `grep(fixed = TRUE)` cuenta líneas y dos apariciones en la misma
# línea le parecen una.
.apariciones <- function(texto, literal) {
  sum(vapply(gregexpr(literal, texto, fixed = TRUE),
             function(m) if (m[1L] == -1L) 0L else length(m), integer(1)))
}

exigir_cifras_readme <- function(motor = NULL, interfaz = NULL, raiz = ".") {
  frases <- frases_cifras_readme(motor = motor, interfaz = interfaz)
  if (!length(frases)) {
    stop("exigir_cifras_readme() sin ninguna cifra que exigir.", call. = FALSE)
  }
  for (f in frases) {
    ruta <- file.path(raiz, f$archivo)
    if (!file.exists(ruta)) {
      stop("No se encuentra ", ruta, call. = FALSE)
    }
    texto <- readLines(ruta, warn = FALSE, encoding = "UTF-8")
    n <- .apariciones(texto, f$literal)
    if (n != 1L) {
      stop(f$archivo, " publica ", n, " veces la frase que sale del recuento ",
           "real de esta corrida, y tiene que publicarla exactamente una: ",
           f$literal, call. = FALSE)
    }
  }
  invisible(TRUE)
}

# La cifra que un README publica hoy, para poder comparar los dos entre sí sin
# haber corrido ninguna suite. Devuelve NA si no hay exactamente una.
cifra_publicada_readme <- function(archivo, patron, raiz = ".") {
  texto <- paste(readLines(file.path(raiz, archivo), warn = FALSE,
                           encoding = "UTF-8"), collapse = "\n")
  m <- regmatches(texto, gregexpr(patron, texto, perl = TRUE))[[1L]]
  if (length(m) != 1L) return(NA_integer_)
  as.integer(gsub("[^0-9]", "", m))
}
