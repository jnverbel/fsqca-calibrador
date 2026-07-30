FECHA_FIJA <- "2026-07-30T12:00:00Z"

proyecto_de_prueba <- function() {
  p <- nuevo_proyecto(fecha = FECHA_FIJA)
  p$datos$nombre_archivo <- "limpia.csv"
  p$datos$huella_sha256 <- strrep("a", 64)
  p$datos$n_filas <- 120L
  p$calibracion$condiciones$CAP_ABS <- list(
    anclas = list(plena = 4.0, cruce = 3.0, nula = 2.0),
    fuente = "teoria",
    justificacion = "El umbral de 4 corresponde a la definicion operativa del constructo."
  )
  p$alertas <- registrar_alertas(nueva_bitacora(),
                                 alerta("A-06", "CAP_ABS", "alfa = 0,58"), paso = 2)
  p
}

test_that("un proyecto nuevo declara la version del esquema", {
  p <- nuevo_proyecto(fecha = FECHA_FIJA)

  expect_identical(p$version_esquema, "1.0")
  expect_identical(p$creado, FECHA_FIJA)
  expect_identical(p$modificado, FECHA_FIJA)
})

test_that("guardar y volver a cargar devuelve el mismo proyecto", {
  ruta <- tempfile(fileext = ".json")
  on.exit(unlink(ruta))
  original <- proyecto_de_prueba()

  guardar_proyecto(original, ruta, fecha = FECHA_FIJA)
  recuperado <- cargar_proyecto(ruta)

  expect_identical(recuperado$version_esquema, original$version_esquema)
  expect_identical(recuperado$datos$huella_sha256, original$datos$huella_sha256)
  expect_equal(recuperado$calibracion$condiciones$CAP_ABS$anclas$plena, 4.0)
  expect_identical(recuperado$calibracion$condiciones$CAP_ABS$fuente, "teoria")
  expect_identical(recuperado$alertas$codigo, "A-06")
  expect_identical(recuperado$alertas$estado, "abierta")
  expect_identical(recuperado$alertas$severidad, "bloqueante")
})

test_that("la bitacora recuperada sirve para decidir si se puede avanzar", {
  ruta <- tempfile(fileext = ".json")
  on.exit(unlink(ruta))
  guardar_proyecto(proyecto_de_prueba(), ruta, fecha = FECHA_FIJA)

  recuperado <- cargar_proyecto(ruta)

  expect_s3_class(recuperado$alertas, "data.frame")
  expect_false(puede_avanzar(recuperado$alertas, paso = 2))
})

test_that("una bitacora con varias alertas sobrevive la ida y vuelta", {
  ruta <- tempfile(fileext = ".json")
  on.exit(unlink(ruta))
  p <- proyecto_de_prueba()
  p$alertas <- registrar_alertas(p$alertas,
                                 alerta("A-03", "SOLO", "1 item"), paso = 1)
  p$alertas <- cerrar_alerta(p$alertas, "A-06", "CAP_ABS",
                             nota = paste("La escala es corta y el constructo",
                                          "es exploratorio; se reporta."),
                             fecha = FECHA_FIJA)

  guardar_proyecto(p, ruta, fecha = FECHA_FIJA)
  recuperado <- cargar_proyecto(ruta)

  expect_identical(nrow(recuperado$alertas), 2L)
  expect_identical(recuperado$alertas$estado[recuperado$alertas$codigo == "A-06"],
                   "reconocida")
  expect_match(recuperado$alertas$nota[recuperado$alertas$codigo == "A-06"],
               "exploratorio")
})

test_that("el archivo guardado es JSON legible por un humano", {
  ruta <- tempfile(fileext = ".json")
  on.exit(unlink(ruta))
  guardar_proyecto(proyecto_de_prueba(), ruta, fecha = FECHA_FIJA)

  lineas <- readLines(ruta, warn = FALSE)
  texto <- paste(lineas, collapse = "\n")

  expect_match(texto, "version_esquema")
  expect_match(texto, "justificacion")
  expect_gt(length(lineas), 10)  # indentado, no una sola linea
})

test_that("el proyecto no guarda datos crudos", {
  ruta <- tempfile(fileext = ".json")
  on.exit(unlink(ruta))
  p <- proyecto_de_prueba()
  guardar_proyecto(p, ruta, fecha = FECHA_FIJA)

  texto <- paste(readLines(ruta, warn = FALSE), collapse = "\n")

  expect_false(grepl("CAP01", texto))
  expect_false("datos_crudos" %in% names(p))
})

test_that("una huella distinta advierte sin bloquear", {
  p <- proyecto_de_prueba()

  igual <- comparar_huella(p, strrep("a", 64))
  distinta <- comparar_huella(p, strrep("b", 64))

  expect_true(igual$coincide)
  expect_false(distinta$coincide)
  expect_match(distinta$mensaje, "distinta")
})

test_that("un proyecto sin huella guardada no advierte", {
  p <- nuevo_proyecto(fecha = FECHA_FIJA)

  expect_true(comparar_huella(p, strrep("b", 64))$coincide)
})

test_that("una version de esquema desconocida es un error claro", {
  ruta <- tempfile(fileext = ".json")
  on.exit(unlink(ruta))
  p <- proyecto_de_prueba()
  p$version_esquema <- "9.9"
  jsonlite::write_json(p, ruta, auto_unbox = TRUE, pretty = TRUE)

  expect_error(cargar_proyecto(ruta), "9.9")
})

test_that("cambiar un ancla en el JSON cambia lo que lee el proyecto", {
  # Prueba de mutacion del propio archivo: si un numero del informe no
  # viniera de aqui, esta prueba no lo detectaria y habria que ir a
  # buscar de donde sale.
  ruta <- tempfile(fileext = ".json")
  on.exit(unlink(ruta))
  guardar_proyecto(proyecto_de_prueba(), ruta, fecha = FECHA_FIJA)

  texto <- readLines(ruta, warn = FALSE)
  cambiado <- sub('"plena": 4', '"plena": 4.5', texto, fixed = TRUE)
  expect_false(identical(texto, cambiado))   # el sub tiene que haber acertado
  writeLines(cambiado, ruta)

  expect_equal(cargar_proyecto(ruta)$calibracion$condiciones$CAP_ABS$anclas$plena, 4.5)
})

test_that("cargar un archivo inexistente es un error claro", {
  expect_error(cargar_proyecto(tempfile(fileext = ".json")), "No existe")
})
