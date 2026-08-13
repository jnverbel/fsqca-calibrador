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
    "nombre_columna_id",
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
    "guion_reproducible",
    # Paso 1 y paso 4: la condicion binaria, que no se calibra.
    "definir_anclas_crisp", "condiciones_binarias", "es_condicion_binaria",
    "anclas_sugeridas",
    # Paso 6: las expectativas direccionales que producen la intermedia.
    "definir_expectativa", "expectativas_sop", "DIRECCIONES_EXPECTATIVA")

  exportados <- getNamespaceExports(asNamespace("calibraqca"))

  expect_identical(setdiff(necesarias, exportados), character(0))
})

# --- La huella no puede imprimirse a medias --------------------------

raiz <- function() testthat::test_path("..", "..", "..", "..")

test_that("la huella SHA-256 se imprime entera donde se presenta", {
  # Paso de verdad el 31/07/2026: el anexo rotulaba "Huella SHA-256" y
  # debajo ponia 32 caracteres de los 64. El prefijo era correcto, pero
  # quien intentara verificarlo con `shasum -a 256` no obtenia una
  # igualdad, y toda la ficha de reproducibilidad existe justamente para
  # que un tercero pueda comprobar que analizo el mismo archivo.
  presentadores <- c(file.path(raiz(), "app", "R", "informe_html.R"),
                     file.path(raiz(), "informe", "informe.qmd"))

  # Sin esto la prueba pasaria por no encontrar los archivos.
  expect_true(all(file.exists(presentadores)))

  for (archivo in presentadores) {
    codigo <- sub("#.*$", "", readLines(archivo, warn = FALSE))
    truncados <- grep("substr\\([^)]*huella", codigo, value = TRUE)
    expect_identical(
      truncados, character(0),
      info = paste("La huella se trunca en", basename(archivo), ":",
                   paste(trimws(truncados), collapse = " | "))
    )
  }
})

# --- Ninguna tabla del anexo puede perderse en silencio ---------------

test_that("kb() imprime la tabla en vez de devolverla", {
  # Paso de verdad el 31/07/2026: el bloque de robustez llama cuatro veces
  # a kb() dentro de un chunk `results: asis`, y solo la ultima se
  # imprimia -- el valor de las otras tres se descartaba. El anexo
  # anunciaba con su parrafo los rangos de las anclas, los rangos de los
  # umbrales y los escenarios, y luego no mostraba ninguno: el paso 7
  # quedaba sin una sola cifra.
  #
  # kb() tiene que imprimir siempre, no devolver. Asi el numero de tablas
  # por chunk deja de importar.
  qmd <- readLines(file.path(raiz(), "informe", "informe.qmd"), warn = FALSE)

  definicion <- grep("^kb <- function", qmd, value = TRUE)

  expect_length(definicion, 1L)
  expect_match(definicion, "print(", fixed = TRUE)
})

test_that("el chunk de robustez sigue pidiendo mas de una tabla", {
  # Si alguien reduce el chunk a una sola tabla, la prueba anterior deja de
  # proteger nada y conviene enterarse.
  qmd <- paste(readLines(file.path(raiz(), "informe", "informe.qmd"),
                         warn = FALSE), collapse = "\n")
  bloque <- regmatches(qmd, regexpr("label: robustez.*?\n```", qmd))

  expect_gt(length(gregexpr("kb(", bloque, fixed = TRUE)[[1]]), 1)
})
