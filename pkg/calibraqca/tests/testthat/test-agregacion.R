mapeo_agr <- function(encuestados = "uno") {
  definir_mapeo("id_empresa", encuestados, list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01", "CAP02", "CAP03")),
    list(nombre = "REDES",   rol = "condicion", items = c("RED01", "RED02", "RED03")),
    list(nombre = "INNOV",   rol = "resultado", items = c("INN01", "INN02", "INN03"))
  ))
}

test_that("el promedio de un constructo es el promedio de sus items", {
  d <- data.frame(id_empresa = c("E1", "E2"),
                  CAP01 = c(1, 5), CAP02 = c(2, 4), CAP03 = c(3, 3),
                  RED01 = c(1, 1), RED02 = c(1, 1), RED03 = c(1, 1),
                  INN01 = c(5, 5), INN02 = c(5, 5), INN03 = c(5, 5))

  pro <- promediar_constructos(d, mapeo_agr())

  # Valores escritos a mano: (1+2+3)/3 = 2 y (5+4+3)/3 = 4.
  expect_identical(pro$CAP_ABS, c(2, 4))
  expect_identical(pro$INNOV, c(5, 5))
})

test_that("con NA promedia sobre los items presentes si conserva la mitad", {
  d <- data.frame(id_empresa = "E1",
                  CAP01 = 2, CAP02 = 4, CAP03 = NA,
                  RED01 = 1, RED02 = 1, RED03 = 1,
                  INN01 = 5, INN02 = 5, INN03 = 5)

  # 2 de 3 items presentes: 2/3 >= 0,5, promedia -> (2+4)/2 = 3.
  expect_identical(promediar_constructos(d, mapeo_agr())$CAP_ABS, 3)
})

test_that("con demasiados NA el constructo queda NA en vez de inventar un valor", {
  d <- data.frame(id_empresa = "E1",
                  CAP01 = 2, CAP02 = NA, CAP03 = NA,
                  RED01 = 1, RED02 = 1, RED03 = 1,
                  INN01 = 5, INN02 = 5, INN03 = 5)

  # 1 de 3 presentes: 1/3 < 0,5.
  expect_true(is.na(promediar_constructos(d, mapeo_agr())$CAP_ABS))
})

test_that("con un encuestado por caso la agregacion no cambia las filas", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  pro <- promediar_constructos(d, mapeo_agr())

  expect_identical(nrow(agregar_a_caso(pro, mapeo_agr())), nrow(pro))
})

test_that("con varios encuestados por caso se colapsa a un caso por fila", {
  pro <- data.frame(id_empresa = c("E1", "E1", "E2"),
                    CAP_ABS = c(2, 4, 5), REDES = c(1, 1, 1), INNOV = c(3, 3, 3))

  casos <- agregar_a_caso(pro, mapeo_agr("varios"))

  expect_identical(nrow(casos), 2L)
  expect_identical(casos$CAP_ABS[casos$id_empresa == "E1"], 3)  # (2+4)/2
  expect_identical(casos$CAP_ABS[casos$id_empresa == "E2"], 5)
})

test_that("el ICC1 y el ICC2 coinciden con los de multilevel", {
  set.seed(7)
  n_casos <- 30
  ids <- rep(sprintf("E%02d", 1:n_casos), each = 3)
  efecto <- rep(stats::rnorm(n_casos, 0, 1), each = 3)
  pro <- data.frame(id_empresa = ids,
                    CAP_ABS = 3 + efecto + stats::rnorm(length(ids), 0, 0.5),
                    REDES = 3, INNOV = 3)

  # Fuente independiente: multilevel, llamado aqui directamente.
  modelo <- stats::aov(pro$CAP_ABS ~ as.factor(pro$id_empresa))
  esperado1 <- multilevel::ICC1(modelo)
  esperado2 <- multilevel::ICC2(modelo)

  icc <- icc_agregacion(pro, mapeo_agr("varios"))

  expect_equal(icc$icc1[["CAP_ABS"]], esperado1, tolerance = 1e-10)
  expect_equal(icc$icc2[["CAP_ABS"]], esperado2, tolerance = 1e-10)
})

test_that("se reporta el reparto de encuestados por caso", {
  pro <- data.frame(id_empresa = c("E1", "E1", "E1", "E2", "E2", "E3"),
                    CAP_ABS = c(3, 4, 3, 5, 4, 2), REDES = 3, INNOV = 3)

  enc <- icc_agregacion(pro, mapeo_agr("varios"))$encuestados

  expect_identical(as.integer(enc[["min"]]), 1L)
  expect_identical(as.integer(enc[["max"]]), 3L)
  expect_equal(as.numeric(enc[["mediana"]]), 2)
})

test_that("cada umbral del ICC manda por separado", {
  # En datos reales los dos ICC fallan juntos, asi que la prueba con datos
  # no distingue cual mando y deja ambos umbrales sin cobertura efectiva.
  expect_true(icc_respalda(icc1 = 0.20, icc2 = 0.85))

  expect_false(icc_respalda(icc1 = 0.04, icc2 = 0.85))   # solo ICC1 falla
  expect_false(icc_respalda(icc1 = 0.20, icc2 = 0.69))   # solo ICC2 falla

  expect_true(icc_respalda(icc1 = 0.05, icc2 = 0.70))    # los limites entran
  expect_false(icc_respalda(icc1 = NA_real_, icc2 = 0.85))
  expect_false(icc_respalda(icc1 = 0.20, icc2 = NA_real_))
})

test_that("A-11 se dispara cuando el ICC no respalda la agregacion", {
  # Sin efecto de grupo: las respuestas dentro de una empresa no se parecen
  # mas entre si que las de empresas distintas.
  set.seed(99)
  ids <- rep(sprintf("E%02d", 1:30), each = 3)
  pro <- data.frame(id_empresa = ids,
                    CAP_ABS = stats::rnorm(length(ids), 3, 1),
                    REDES = stats::rnorm(length(ids), 3, 1),
                    INNOV = stats::rnorm(length(ids), 3, 1))

  expect_true("A-11" %in% alertas_agregacion(pro, mapeo_agr("varios"))$codigo)
})

test_that("A-11 no se dispara con un efecto de grupo claro", {
  set.seed(7)
  ids <- rep(sprintf("E%02d", 1:30), each = 5)
  efecto <- rep(stats::rnorm(30, 0, 1.5), each = 5)
  pro <- data.frame(id_empresa = ids,
                    CAP_ABS = 3 + efecto + stats::rnorm(length(ids), 0, 0.3),
                    REDES = 3 + efecto + stats::rnorm(length(ids), 0, 0.3),
                    INNOV = 3 + efecto + stats::rnorm(length(ids), 0, 0.3))

  expect_false("A-11" %in% alertas_agregacion(pro, mapeo_agr("varios"))$codigo)
})

test_that("A-12 se dispara si hay casos con un solo encuestado en diseno multinivel", {
  set.seed(7)
  ids <- c(rep(sprintf("E%02d", 1:29), each = 5), "E30")
  efecto <- rep(stats::rnorm(30, 0, 1.5), times = c(rep(5, 29), 1))
  pro <- data.frame(id_empresa = ids,
                    CAP_ABS = 3 + efecto + stats::rnorm(length(ids), 0, 0.3),
                    REDES = 3 + efecto + stats::rnorm(length(ids), 0, 0.3),
                    INNOV = 3 + efecto + stats::rnorm(length(ids), 0, 0.3))

  expect_true("A-12" %in% alertas_agregacion(pro, mapeo_agr("varios"))$codigo)
})

test_that("A-12 no se dispara si todos los casos tienen varios encuestados", {
  set.seed(7)
  ids <- rep(sprintf("E%02d", 1:30), each = 5)
  efecto <- rep(stats::rnorm(30, 0, 1.5), each = 5)
  pro <- data.frame(id_empresa = ids,
                    CAP_ABS = 3 + efecto + stats::rnorm(length(ids), 0, 0.3),
                    REDES = 3 + efecto + stats::rnorm(length(ids), 0, 0.3),
                    INNOV = 3 + efecto + stats::rnorm(length(ids), 0, 0.3))

  expect_false("A-12" %in% alertas_agregacion(pro, mapeo_agr("varios"))$codigo)
})

test_that("con un encuestado por caso no se calcula ICC ni se disparan A-11 ni A-12", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))
  pro <- promediar_constructos(d, mapeo_agr())

  codigos <- alertas_agregacion(pro, mapeo_agr())$codigo

  expect_false("A-11" %in% codigos)
  expect_false("A-12" %in% codigos)
  expect_null(diagnosticar_agregacion(d, mapeo_agr())$icc)
})

test_that("diagnosticar_agregacion devuelve promedios y casos coherentes", {
  d <- read.csv(testthat::test_path("datos", "limpia.csv"))

  res <- diagnosticar_agregacion(d, mapeo_agr())

  expect_identical(nrow(res$promedios), 120L)
  expect_identical(nrow(res$casos), 120L)
  expect_true(all(c("CAP_ABS", "REDES", "INNOV") %in% names(res$promedios)))
})
