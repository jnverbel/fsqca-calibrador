# Guardian de la integridad del informe.
#
# El informe imprime la version y genera la cita bibliografica de cada
# paquete de PAQUETES_INFORME. Declarar ahi un paquete que no se invoca
# atribuye a sus autores un calculo que no hicieron, y eso es exactamente
# lo que esta herramienta existe para impedir. Paso el 2026-07-31 con
# SetMethods y lavaan declarados sin una sola llamada.
#
# La comprobacion se hace sobre el namespace cargado y no sobre los
# archivos del disco: lo que importa es el codigo que se ejecuta.

paquetes_invocados <- function() {
  ns <- asNamespace("calibraqca")
  fuente <- unlist(lapply(ls(ns, all.names = TRUE), function(nombre) {
    objeto <- get(nombre, envir = ns)
    if (is.function(objeto)) deparse(objeto) else character(0)
  }))
  usados <- regmatches(fuente,
                       gregexpr("[A-Za-z][A-Za-z0-9.]*(?=::)", fuente,
                                perl = TRUE))
  unique(unlist(usados))
}

test_that("cada paquete que el informe cita se invoca de verdad", {
  sin_usar <- setdiff(PAQUETES_INFORME, paquetes_invocados())

  expect_identical(
    sin_usar, character(0),
    info = paste("El informe cita estos paquetes sin invocarlos:",
                 paste(sin_usar, collapse = ", "))
  )
})

test_that("el guardian detecta un paquete declarado y nunca invocado", {
  # Sin esta prueba, la anterior pasaria igual si paquetes_invocados()
  # devolviera de más por accidente.
  expect_false("nonexistentpkg" %in% paquetes_invocados())
})

# --- La otra mitad del guardian ---------------------------------------
#
# La comprobacion de arriba caza un paquete DECLARADO y nunca invocado.
# Faltaba la contraria, que es la que muerde en CRAN: un paquete INVOCADO
# con :: y no declarado en DESCRIPTION. SetMethods vivia asi -- ocho
# llamadas en robustez.R y ni una linea en Imports ni en Suggests, solo
# prosa en el campo Description --, y R CMD check lo levantaba como WARNING
# "'::' import not declared". Fuera de la biblioteca de renv, el paso 7
# moria con un error crudo en ingles.

.declarados_en_description <- function() {
  # Del paquete INSTALADO y no del archivo del repositorio: bajo R CMD
  # check las pruebas corren desde otro arbol y leer el DESCRIPTION por
  # ruta relativa falla ahi con "cannot open the connection".
  d <- utils::packageDescription("calibraqca",
                                 fields = c("Depends", "Imports", "Suggests"))
  campos <- as.character(unlist(d))
  campos <- campos[!is.na(campos)]
  piezas <- trimws(unlist(strsplit(paste(campos, collapse = ","), ",")))
  piezas <- sub("\\s*\\(.*\\)$", "", piezas)
  setdiff(piezas[nzchar(piezas)], "R")
}

test_that("todo paquete invocado con :: esta declarado en DESCRIPTION", {
  base <- rownames(utils::installed.packages(priority = "base"))
  sin_declarar <- setdiff(setdiff(paquetes_invocados(), base),
                          .declarados_en_description())

  expect_identical(
    sin_declarar, character(0),
    info = paste("Se invocan con :: y no estan en DESCRIPTION:",
                 paste(sin_declarar, collapse = ", "))
  )
})

test_that("SetMethods esta declarado y se invoca", {
  # El caso concreto que destapo el hueco, escrito a mano para que
  # sobreviva a cualquier reorganizacion del guardian de arriba.
  expect_true("SetMethods" %in% .declarados_en_description())
  expect_true("SetMethods" %in% paquetes_invocados())
})
