# Un CSV de items Likert exportado tal cual no tiene NINGUNA columna de
# texto. Es el caso mas comun de esta herramienta, y era justo el que se
# rompia: sugerir_columna_id() devolvia la primera columna del archivo, de
# modo que el primer item pasaba a identificar el caso.
#
# Medido con el S1 de Kim y Ko (2023), 225 respuestas x 35 items en siete
# constructos de cinco: FUN1 se gastaba como identificador, FUN se quedaba
# con cuatro items frente a cinco de los demas, y saltaban dos alertas
# falsas -- A-05, porque un item Likert repite valores, y A-07, porque el
# constructo perdia un item.
#
# El acuerdo que cierra el agujero: sin identificador, el caso ES la fila.

encuesta_likert <- function(n = 12, constructos = c("FUN", "AES", "EXP"),
                            por_constructo = 5) {
  set.seed(7)
  columnas <- list()
  for (con in constructos) {
    for (i in seq_len(por_constructo)) {
      columnas[[paste0(con, i)]] <- sample(1:5, n, replace = TRUE)
    }
  }
  as.data.frame(columnas, stringsAsFactors = FALSE)
}

mapeo_sin_id <- function(constructos = c("FUN", "AES", "EXP"),
                         por_constructo = 5) {
  definir_mapeo(
    columna_id = NULL, encuestados_por_caso = "uno",
    constructos = lapply(seq_along(constructos), function(i)
      list(nombre = constructos[i],
           rol = if (i == length(constructos)) "resultado" else "condicion",
           items = paste0(constructos[i], seq_len(por_constructo)))))
}

# --- La sugerencia ----------------------------------------------------

test_that("sin ninguna columna de texto no se propone identificador", {
  d <- encuesta_likert()

  expect_null(sugerir_columna_id(d))
})

test_that("con columna de texto se sigue proponiendo la que identifica", {
  # La pareja opuesta: sin ella, un detector que devolviera siempre NULL
  # pasaria la prueba de arriba.
  d <- data.frame(empresa = c("E1", "E2"), sector = c("X", "X"),
                  ABS1 = c(1, 2), stringsAsFactors = FALSE)

  expect_identical(sugerir_columna_id(d), "empresa")
})

test_that("sin identificador ningun item se gasta como columna de caso", {
  # El criterio de aceptacion medible: siete constructos de cinco items.
  d <- encuesta_likert(constructos = c("FUN", "AES", "EXP", "PU", "PEOU",
                                       "ATT", "PI"))

  s <- sugerir_mapeo(d, sugerir_columna_id(d))

  expect_length(s$constructos, 7L)
  expect_identical(unique(vapply(s$constructos, length, integer(1))), 5L)
  expect_true("FUN1" %in% s$constructos$FUN)
  expect_length(s$ignoradas, 0L)
})

# --- El mapeo ---------------------------------------------------------

test_that("definir_mapeo admite quedarse sin columna identificadora", {
  m <- mapeo_sin_id()

  expect_true("columna_id" %in% names(m))
  expect_null(m$columna_id)
  expect_identical(nombre_columna_id(m), "caso")
})

test_that("con identificador declarado, el nombre de la columna es el suyo", {
  m <- definir_mapeo("id_empresa", "uno",
                     list(list(nombre = "X", rol = "condicion",
                               items = c("A", "B"))))

  expect_identical(nombre_columna_id(m), "id_empresa")
})

test_that("definir_mapeo rechaza un identificador que no es un nombre", {
  expect_error(
    definir_mapeo(c("a", "b"), "uno",
                  list(list(nombre = "X", rol = "condicion",
                            items = c("A", "B")))),
    "columna_id")
})

test_that("sin identificador, un constructo llamado caso se rechaza en voz alta", {
  # La columna de numero de fila se llama 'caso'. Si un constructo se llama
  # igual, la tabla de casos tendria dos columnas con el mismo nombre y el
  # analisis saldria mal en silencio.
  expect_error(
    definir_mapeo(NULL, "uno",
                  list(list(nombre = "caso", rol = "condicion",
                            items = c("caso1", "caso2")))),
    "caso")
})

# --- Paso 1: A-05 no puede dispararse por filas distintas -------------

test_that("sin identificador no salta A-05 aunque haya filas identicas", {
  d <- encuesta_likert(n = 6)
  d[2, ] <- d[1, ]   # dos respuestas identicas: filas distintas, no duplicados
  m <- mapeo_sin_id()

  alertas <- diagnosticar_ingesta(d, m)

  expect_false("A-05" %in% alertas$codigo)
})

test_that("con identificador repetido A-05 sigue saltando", {
  # La pareja opuesta: donde lo correcto es HABLAR, un detector mudo
  # aprobaria la prueba de arriba.
  d <- encuesta_likert(n = 4)
  d$id_empresa <- c("E1", "E1", "E2", "E3")
  m <- definir_mapeo("id_empresa", "uno",
                     list(list(nombre = "FUN", rol = "condicion",
                               items = paste0("FUN", 1:5))))

  alertas <- diagnosticar_ingesta(d, m)

  expect_true("A-05" %in% alertas$codigo)
})

test_that("sin identificador, la columna de items no cuenta como sin mapear", {
  d <- encuesta_likert()
  m <- mapeo_sin_id()

  expect_false("A-02" %in% diagnosticar_ingesta(d, m)$codigo)
})

# --- Paso 3: el caso es la fila ---------------------------------------

test_that("sin identificador el caso se numera por su fila", {
  d <- encuesta_likert(n = 5)
  m <- mapeo_sin_id()

  promedios <- promediar_constructos(d, m)

  expect_identical(names(promedios)[1], "caso")
  expect_identical(promedios$caso, as.character(1:5))
  expect_setequal(names(promedios), c("caso", "FUN", "AES", "EXP"))
})

test_that("con identificador declarado el paso 3 no lo cambia", {
  d <- encuesta_likert(n = 3)
  d$id_empresa <- c("E1", "E2", "E3")
  m <- definir_mapeo("id_empresa", "uno",
                     list(list(nombre = "FUN", rol = "condicion",
                               items = paste0("FUN", 1:5))))

  promedios <- promediar_constructos(d, m)

  expect_identical(names(promedios)[1], "id_empresa")
  expect_identical(promedios$id_empresa, c("E1", "E2", "E3"))
})

# --- El flujo entero, sin identificador -------------------------------

test_that("el flujo llega hasta el semaforo sin columna identificadora", {
  d <- encuesta_likert(n = 40)
  m <- mapeo_sin_id()
  id <- nombre_columna_id(m)

  agr <- diagnosticar_agregacion(d, m)
  expect_identical(nrow(agr$casos), 40L)

  just <- paste("El umbral de 4 corresponde al punto en que la literatura",
                "sectorial situa la capacidad plena del constructo.")
  condiciones <- setdiff(names(agr$casos), id)
  anclas <- stats::setNames(
    lapply(condiciones, function(x) definir_anclas(4, 3, 2, "teoria", just)),
    condiciones)

  cal <- diagnosticar_calibracion(agr$casos, anclas, id)
  expect_identical(cal$membresias[[id]], as.character(1:40))
  expect_setequal(setdiff(names(cal$membresias), id), condiciones)

  sem <- diagnosticar_semaforo(cal$membresias, id)
  expect_setequal(sem$resumen$condicion, condiciones)
})

# --- Paso 8: el guion reproducible no puede escribir datos$NULL -------

test_that("el guion reproducible numera las filas cuando no hay identificador", {
  m <- mapeo_sin_id()
  just <- paste("El umbral de 4 corresponde al punto en que la literatura",
                "sectorial situa la capacidad plena del constructo.")
  anclas <- list(FUN = definir_anclas(4, 3, 2, "teoria", just),
                 AES = definir_anclas(4, 3, 2, "teoria", just),
                 EXP = definir_anclas(4, 3, 2, "teoria", just))

  guion <- guion_reproducible(
    ruta_datos = "encuesta.csv", mapeo = m, anclas = anclas, idm = 0.95,
    umbrales = list(consistencia = 0.8, frecuencia = 2, pri = 0.7),
    resultado = "EXP")

  expect_match(guion, "caso = seq_len(nrow(datos))", fixed = TRUE)
  expect_false(grepl("datos$NULL", guion, fixed = TRUE))
  expect_match(guion, 'setdiff(names(calibrado), "caso")', fixed = TRUE)
})

test_that("con identificador el guion sigue leyendolo del archivo", {
  m <- definir_mapeo("id_empresa", "uno",
                     list(list(nombre = "FUN", rol = "condicion",
                               items = paste0("FUN", 1:5)),
                          list(nombre = "EXP", rol = "resultado",
                               items = paste0("EXP", 1:5))))
  just <- paste("El umbral de 4 corresponde al punto en que la literatura",
                "sectorial situa la capacidad plena del constructo.")
  anclas <- list(FUN = definir_anclas(4, 3, 2, "teoria", just),
                 EXP = definir_anclas(4, 3, 2, "teoria", just))

  guion <- guion_reproducible(
    ruta_datos = "encuesta.csv", mapeo = m, anclas = anclas, idm = 0.95,
    umbrales = list(consistencia = 0.8, frecuencia = 2, pri = 0.7),
    resultado = "EXP")

  expect_match(guion, "id_empresa = datos$id_empresa", fixed = TRUE)
})

# --- El proyecto guarda que no habia identificador --------------------

test_that("el proyecto conserva que el archivo no traia identificador", {
  m <- mapeo_sin_id()
  just <- paste("El umbral de 4 corresponde al punto en que la literatura",
                "sectorial situa la capacidad plena del constructo.")
  anclas <- list(FUN = definir_anclas(4, 3, 2, "teoria", just),
                 AES = definir_anclas(4, 3, 2, "teoria", just),
                 EXP = definir_anclas(4, 3, 2, "teoria", just))

  p <- construir_proyecto(
    leido = list(nombre_archivo = "encuesta.csv", huella_sha256 = "abc",
                 n_filas = 40L, n_columnas = 15L,
                 nombres_columnas = names(encuesta_likert())),
    mapeo = m, anclas = anclas, bitacora = nueva_bitacora(),
    umbrales = list(consistencia = 0.8, frecuencia = 2, pri = 0.7),
    resultado = "EXP")

  expect_true("columna_id" %in% names(p$mapeo))
  expect_null(p$mapeo$columna_id)

  ruta <- tempfile(fileext = ".json")
  on.exit(unlink(ruta))
  guardar_proyecto(p, ruta)
  leido <- cargar_proyecto(ruta)

  expect_null(leido$mapeo$columna_id)
  # Y lo que se relee tiene que poder reconstruir el mapeo, que es lo que
  # hace informe.qmd antes de recomponer el informe.
  expect_null(definir_mapeo(leido$mapeo$columna_id, "uno",
                            list(list(nombre = "FUN", rol = "condicion",
                                      items = c("FUN1", "FUN2"))))$columna_id)
})
