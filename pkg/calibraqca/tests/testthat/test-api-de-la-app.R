# La aplicacion solo puede usar lo que el paquete EXPORTA.
#
# pkgload::load_all(export_all = FALSE) expone unicamente el NAMESPACE, asi
# que una constante interna usada desde app/ compila sin queja y revienta
# en tiempo de ejecucion -- y solo cuando el usuario llega a esa pantalla.
# Paso de verdad: RON_MINIMO tumbaba la descarga del informe con
# "object 'RON_MINIMO' not found", y ninguna prueba lo vio.

ruta_app <- function() testthat::test_path("..", "..", "..", "..", "app")

test_that("el directorio de la aplicacion esta donde se cree", {
  # Sin esto la prueba pasaria por no encontrar archivos, que es la forma
  # mas comun de prueba ciega.
  expect_true(dir.exists(ruta_app()))
  expect_gt(length(list.files(ruta_app(), pattern = "\\.R$",
                              recursive = TRUE)), 3)
})

test_that("la aplicacion no usa simbolos internos del paquete", {
  archivos <- list.files(ruta_app(), pattern = "\\.R$", recursive = TRUE,
                         full.names = TRUE)
  codigo <- unlist(lapply(archivos, readLines, warn = FALSE))
  # Fuera los comentarios: ahi se nombran constantes al explicarlas.
  codigo <- sub("#.*$", "", codigo)

  ns <- asNamespace("calibraqca")
  internos <- setdiff(ls(ns, all.names = FALSE), getNamespaceExports(ns))
  # Los que empiezan por punto son privados por convencion y nadie los
  # escribe fuera; el resto es lo que puede colarse.
  internos <- internos[!startsWith(internos, ".")]

  usados <- Filter(function(sim) {
    any(grepl(paste0("(^|[^A-Za-z0-9._])", sim, "([^A-Za-z0-9._]|$)"), codigo))
  }, internos)

  expect_identical(usados, character(0))
})

test_that("las funciones que la aplicacion necesita estan exportadas", {
  # La lista es explicita a proposito: si alguien deja de exportar una, la
  # prueba lo dice aqui y no en la pantalla del investigador.
  necesarias <- c(
    "leer_datos", "definir_mapeo", "diagnosticar_ingesta",
    "sugerir_mapeo", "sugerir_columna_id", "items_mapeados",
    "diagnosticar_validacion", "diagnosticar_agregacion",
    "definir_anclas", "calibrar", "FUENTES_ANCLA",
    "diagnosticar_calibracion", "diagnosticar_semaforo",
    "diagnosticar_necesidad", "necesidad_trivial",
    "construir_tabla_verdad", "leer_tabla_verdad", "alertas_tabla_verdad",
    "pri_insuficiente", "diagnosticar_suficiencia", "umbral_frecuencia",
    "catalogo_alertas", "nueva_bitacora", "alerta", "registrar_alertas",
    "cerrar_alerta", "puede_avanzar", "alertas_pendientes",
    "barrido_robustez", "diagnosticar_robustez",
    "nuevo_proyecto", "guardar_proyecto", "cargar_proyecto",
    "construir_proyecto", "comparar_huella",
    "reunir_informe", "tabla_calibracion", "exportar_base_calibrada",
    "guion_reproducible")

  exportados <- getNamespaceExports(asNamespace("calibraqca"))

  expect_identical(setdiff(necesarias, exportados), character(0))
})
