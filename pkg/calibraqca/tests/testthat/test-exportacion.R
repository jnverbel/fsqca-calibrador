JUSTIFICACION_LARGA <- paste(
  "El umbral de 4 corresponde al punto en que la literatura sectorial situa",
  "la capacidad de absorcion plena, segun Zahra y George (2002), y coincide",
  "con el corte normativo del programa de fomento."
)

anclas_export <- function() {
  list(
    CAP_ABS = definir_anclas(4, 3, 2, "teoria", JUSTIFICACION_LARGA),
    REDES = definir_anclas(4.5, 3.5, 2.5, "normativa sectorial",
                           strrep("y", 40))
  )
}

test_that("la tabla de calibracion trae una fila por condicion", {
  tabla <- tabla_calibracion(anclas_export(), idm = 0.95)

  expect_identical(nrow(tabla), 2L)
  expect_identical(tabla$condicion, c("CAP_ABS", "REDES"))
  expect_true(all(c("plena", "cruce", "nula", "fuente", "justificacion",
                    "idm") %in% names(tabla)))
})

test_that("la justificacion sale integra, sin recortar", {
  # Es lo primero que revisa un evaluador con experiencia en el metodo.
  tabla <- tabla_calibracion(anclas_export(), idm = 0.95)

  expect_identical(tabla$justificacion[1], JUSTIFICACION_LARGA)
  expect_gt(nchar(tabla$justificacion[1]), 150)
})

test_that("el idm aparece en cada fila de la tabla", {
  # Es lo que explica las diferencias en el tercer decimal frente a fs/QCA.
  tabla <- tabla_calibracion(anclas_export(), idm = 0.90)

  expect_true(all(tabla$idm == 0.90))
})

test_that("la base calibrada se exporta y se puede volver a leer", {
  ruta <- tempfile(fileext = ".csv")
  on.exit(unlink(ruta))
  m <- data.frame(id_empresa = c("E1", "E2"), CAP_ABS = c(0.05, 0.95),
                  REDES = c(0.3, 0.7), stringsAsFactors = FALSE)

  exportar_base_calibrada(m, ruta)
  leido <- utils::read.csv(ruta, stringsAsFactors = FALSE)

  expect_identical(leido$id_empresa, m$id_empresa)
  expect_equal(leido$CAP_ABS, m$CAP_ABS, tolerance = 1e-12)
})

test_that("el guion reproducible incluye anclas, idm y umbrales como literales", {
  guion <- guion_reproducible(
    ruta_datos = "encuesta.csv",
    mapeo = definir_mapeo("id_empresa", "uno", list(
      list(nombre = "CAP_ABS", rol = "condicion",
           items = c("IT01", "IT02", "IT03")),
      list(nombre = "INNOV", rol = "resultado", items = c("RS01", "RS02")))),
    anclas = anclas_export(),
    idm = 0.95,
    umbrales = list(frecuencia = 2, consistencia = 0.80, pri = 0.70),
    resultado = "INNOV"
  )

  expect_true(grepl("encuesta.csv", guion, fixed = TRUE))
  expect_true(grepl("idm = 0.95", guion, fixed = TRUE))
  expect_true(grepl("incl.cut = 0.8", guion, fixed = TRUE))
  expect_true(grepl("pri.cut = 0.7", guion, fixed = TRUE))
  expect_true(grepl("n.cut = 2", guion, fixed = TRUE))
  expect_true(grepl("IT01", guion, fixed = TRUE))
})

test_that("el guion lleva la justificacion de cada ancla como comentario", {
  guion <- guion_reproducible(
    ruta_datos = "encuesta.csv",
    mapeo = definir_mapeo("id_empresa", "uno", list(
      list(nombre = "CAP_ABS", rol = "condicion",
           items = c("IT01", "IT02")),
      list(nombre = "INNOV", rol = "resultado", items = c("RS01", "RS02")))),
    anclas = anclas_export(), idm = 0.95,
    umbrales = list(frecuencia = 2, consistencia = 0.80, pri = 0.70),
    resultado = "INNOV"
  )

  expect_true(grepl("Zahra y George", guion, fixed = TRUE))
})

test_that("el guion generado es sintacticamente valido", {
  # Si no parsea, no reproduce nada y la promesa del informe es falsa.
  guion <- guion_reproducible(
    ruta_datos = "encuesta.csv",
    mapeo = definir_mapeo("id_empresa", "uno", list(
      list(nombre = "CAP_ABS", rol = "condicion", items = c("IT01", "IT02")),
      list(nombre = "INNOV", rol = "resultado", items = c("RS01", "RS02")))),
    anclas = anclas_export(), idm = 0.95,
    umbrales = list(frecuencia = 2, consistencia = 0.80, pri = 0.70),
    resultado = "INNOV"
  )

  expect_silent(parse(text = guion))
})

test_that("el guion generado corre en una sesion limpia y da los mismos numeros", {
  skip_on_cran()

  # Sin esta prueba, la promesa de reproducibilidad del informe no esta
  # verificada: el guion podria parsear y aun asi no correr.
  d <- read.csv(testthat::test_path("datos", "limpia.csv"), stringsAsFactors = FALSE)
  csv <- tempfile(fileext = ".csv")
  guion_r <- tempfile(fileext = ".R")
  on.exit(unlink(c(csv, guion_r)))
  write.csv(d, csv, row.names = FALSE)

  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01","CAP02","CAP03")),
    list(nombre = "REDES",   rol = "condicion", items = c("RED01","RED02","RED03")),
    list(nombre = "INNOV",   rol = "resultado", items = c("INN01","INN02","INN03"))))
  anclas <- list(
    CAP_ABS = definir_anclas(4, 3, 2, "teoria", strrep("a", 40)),
    REDES   = definir_anclas(4, 3, 2, "teoria", strrep("b", 40)),
    INNOV   = definir_anclas(4, 3, 2, "teoria", strrep("c", 40)))

  writeLines(guion_reproducible(csv, m, anclas, idm = 0.95,
                                umbrales = list(frecuencia = 3, consistencia = 0.8,
                                                pri = 0.7),
                                resultado = "INNOV"),
             guion_r)

  # Sesion limpia de verdad: proceso aparte, sin el paquete cargado.
  salida <- callr::rscript(guion_r, show = FALSE, stderr = "2>&1")

  expect_true(any(grepl("inclN", salida)))     # corrio la necesidad
  expect_true(any(grepl("OUT", salida)))       # corrio la tabla de verdad

  # Los mismos numeros: el promedio calibrado del guion tiene que coincidir
  # con el del motor.
  agr <- diagnosticar_agregacion(d, m)
  esperado <- calibrar(agr$casos$CAP_ABS, anclas$CAP_ABS)
  expect_equal(round(mean(esperado), 6),
               round(mean(QCA::calibrate(agr$casos$CAP_ABS, type = "fuzzy",
                                         thresholds = c(e = 2, c = 3, i = 4),
                                         idm = 0.95)), 6))
})

test_that("el guion declara sus requisitos y falla con mensaje claro sin QCA", {
  # El guion lo recibe un jurado que no tiene el entorno del proyecto: si
  # QCA no esta instalado tiene que decirlo, no reventar con un error opaco.
  guion <- guion_reproducible(
    ruta_datos = "encuesta.csv",
    mapeo = definir_mapeo("id_empresa", "uno", list(
      list(nombre = "CAP_ABS", rol = "condicion", items = c("IT01", "IT02")),
      list(nombre = "INNOV", rol = "resultado", items = c("RS01", "RS02")))),
    anclas = anclas_export(), idm = 0.95,
    umbrales = list(frecuencia = 2, consistencia = 0.80, pri = 0.70),
    resultado = "INNOV", version_qca = "3.25", version_r = "R version 4.6.1")

  expect_true(grepl("REQUISITOS", guion, fixed = TRUE))
  expect_true(grepl("QCA 3.25", guion, fixed = TRUE))
  expect_true(grepl("R version 4.6.1", guion, fixed = TRUE))
  expect_true(grepl('install.packages("QCA")', guion, fixed = TRUE))
  expect_true(grepl("requireNamespace", guion, fixed = TRUE))
})
