mapeo_limpio <- function() {
  definir_mapeo(
    columna_id = "id_empresa",
    encuestados_por_caso = "uno",
    constructos = list(
      list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP02", "CAP03")),
      list(nombre = "REDES",   rol = "condicion", items = c("RED01", "RED02", "RED03")),
      list(nombre = "INNOV",   rol = "resultado", items = c("INN01", "INN02", "INN03"))
    )
  )
}

test_that("leer_datos devuelve la huella y la forma del archivo", {
  ruta <- testthat::test_path("datos", "limpia.csv")
  leido <- leer_datos(ruta)

  expect_identical(leido$n_filas, 120L)
  expect_identical(leido$nombre_archivo, "limpia.csv")
  expect_match(leido$huella_sha256, "^[0-9a-f]{64}$")
  expect_true("id_empresa" %in% leido$nombres_columnas)
})

test_that("la huella coincide con la de digest y cambia si cambia el archivo", {
  # El valor esperado no se calcula con leer_datos: se calcula con digest,
  # que es la fuente independiente.
  ruta <- testthat::test_path("datos", "limpia.csv")
  expect_identical(leer_datos(ruta)$huella_sha256,
                   digest::digest(file = ruta, algo = "sha256"))

  temporal <- tempfile(fileext = ".csv")
  on.exit(unlink(temporal))
  d <- read.csv(ruta)
  d$CAP01[1] <- if (d$CAP01[1] == 5) 4 else 5
  write.csv(d, temporal, row.names = FALSE)

  expect_false(identical(leer_datos(ruta)$huella_sha256,
                         leer_datos(temporal)$huella_sha256))
})

test_that("leer_datos rechaza un formato que no soporta", {
  temporal <- tempfile(fileext = ".sav")
  on.exit(unlink(temporal))
  writeLines("no importa", temporal)

  expect_error(leer_datos(temporal), "sav")
})

test_that("definir_mapeo rechaza un rol invalido", {
  expect_error(
    definir_mapeo("id", "uno",
                  list(list(nombre = "X", rol = "moderador", items = c("A", "B")))),
    "moderador"
  )
})

test_that("definir_mapeo rechaza constructos con el mismo nombre", {
  expect_error(
    definir_mapeo("id", "uno", list(
      list(nombre = "X", rol = "condicion", items = c("A", "B")),
      list(nombre = "X", rol = "condicion", items = c("C", "D"))
    )),
    "X"
  )
})

test_that("diagnosticar_ingesta falla si el mapeo nombra items inexistentes", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "X", rol = "condicion", items = c("NO_EXISTE_1", "NO_EXISTE_2"))
  ))

  expect_error(diagnosticar_ingesta(d, m), "NO_EXISTE_1")
})

test_that("A-01 se dispara con un valor fuera de escala", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  d$CAP01[3] <- 7

  alertas <- diagnosticar_ingesta(d, mapeo_limpio())

  expect_true("A-01" %in% alertas$codigo)
  expect_match(alertas$detalle[alertas$codigo == "A-01"], "7")
})

test_that("A-01 no se dispara con datos dentro de escala", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))

  expect_false("A-01" %in% diagnosticar_ingesta(d, mapeo_limpio())$codigo)
})

test_that("A-02 se dispara con una columna numerica sin mapear", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  d$EXTRA <- 3L

  alertas <- diagnosticar_ingesta(d, mapeo_limpio())

  expect_true("A-02" %in% alertas$codigo)
  expect_match(alertas$detalle[alertas$codigo == "A-02"], "EXTRA")
})

test_that("A-02 no se dispara cuando todo esta mapeado", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))

  expect_false("A-02" %in% diagnosticar_ingesta(d, mapeo_limpio())$codigo)
})

test_that("A-03 se dispara con un constructo de un solo item", {
  d <- read.csv(testthat::test_path("datos", "degenerada.csv"))
  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP02", "CAP03")),
    list(nombre = "SOLO",    rol = "condicion", items = "SOLO01"),
    list(nombre = "REDES",   rol = "resultado", items = c("RED01", "RED02"))
  ))

  alertas <- diagnosticar_ingesta(d, m)

  expect_true("A-03" %in% alertas$codigo)
  expect_identical(alertas$contexto[alertas$codigo == "A-03"], "SOLO")
})

test_that("A-03 no se dispara con constructos de varios items", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))

  expect_false("A-03" %in% diagnosticar_ingesta(d, mapeo_limpio())$codigo)
})

test_that("A-04 se dispara con mas del 10 por ciento de no respuesta", {
  d <- read.csv(testthat::test_path("datos", "degenerada.csv"))
  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP02", "CAP03")),
    list(nombre = "REDES",   rol = "resultado", items = c("RED01", "RED02"))
  ))

  alertas <- diagnosticar_ingesta(d, m)

  expect_true("A-04" %in% alertas$codigo)          # 6 de 40 = 15 %
  expect_identical(alertas$contexto[alertas$codigo == "A-04"], "CAP02")
})

test_that("A-04 no se dispara justo en el umbral", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  d$CAP01[1:12] <- NA                              # 12 de 120 = 10 %, no lo supera

  expect_false("A-04" %in% diagnosticar_ingesta(d, mapeo_limpio())$codigo)
})

test_that("A-05 se dispara con identificadores repetidos y un encuestado por caso", {
  d <- read.csv(testthat::test_path("datos", "degenerada.csv"))
  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP03")),
    list(nombre = "REDES",   rol = "resultado", items = c("RED01", "RED02"))
  ))

  expect_true("A-05" %in% diagnosticar_ingesta(d, m)$codigo)
})

test_that("A-05 no se dispara si el diseno declara varios encuestados por caso", {
  d <- read.csv(testthat::test_path("datos", "degenerada.csv"))
  m <- definir_mapeo("id_empresa", "varios", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP03")),
    list(nombre = "REDES",   rol = "resultado", items = c("RED01", "RED02"))
  ))

  expect_false("A-05" %in% diagnosticar_ingesta(d, m)$codigo)
})

test_that("las alertas de ingesta entran en la bitacora con su severidad", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  d$CAP01[3] <- 7

  bit <- registrar_alertas(nueva_bitacora(),
                           diagnosticar_ingesta(d, mapeo_limpio()), paso = 1)

  expect_identical(bit$severidad[bit$codigo == "A-01"], "bloqueante")
  expect_false(puede_avanzar(bit, paso = 1))
})

test_that("una base sin problemas no dispara ninguna alerta de ingesta", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))

  alertas <- diagnosticar_ingesta(d, mapeo_limpio())

  expect_identical(nrow(alertas), 0L)
  expect_true(puede_avanzar(registrar_alertas(nueva_bitacora(), alertas, paso = 1),
                            paso = 1))
})
