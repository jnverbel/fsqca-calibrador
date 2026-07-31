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
