test_that("el catalogo tiene las 32 alertas de la especificacion", {
  cat_al <- catalogo_alertas()

  expect_s3_class(cat_al, "data.frame")
  expect_identical(nrow(cat_al), 32L)
  expect_identical(cat_al$codigo, sprintf("A-%02d", 1:32))
  expect_false(any(duplicated(cat_al$codigo)))
})

test_that("cada alerta declara paso y severidad validos", {
  cat_al <- catalogo_alertas()

  expect_true(all(cat_al$paso %in% 1:7))
  expect_true(all(cat_al$severidad %in%
                    c("bloqueante", "advertencia", "informativa")))
  expect_true(all(nchar(cat_al$titulo) > 0))
})

test_that("el reparto por paso coincide con la especificacion", {
  # Valores escritos a mano desde docs/especificacion.md, no contados por codigo.
  esperado <- c(`1` = 5L, `2` = 5L, `3` = 2L, `4` = 5L,
                `5` = 8L, `6` = 5L, `7` = 2L)
  observado <- table(catalogo_alertas()$paso)

  expect_identical(as.integer(observado[names(esperado)]), unname(esperado))
})

test_that("toda alerta del catalogo tiene un caso que la dispara y uno que no", {
  skip("las alertas de los pasos 4-7 llegan en los planes 02 y 03")

  archivos <- list.files(testthat::test_path("."), pattern = "^test-.*\\.R$",
                         full.names = TRUE)
  expect_gt(length(archivos), 1)

  texto <- unlist(lapply(archivos, readLines, warn = FALSE))

  sin_positivo <- character()
  sin_negativo <- character()
  for (codigo in catalogo_alertas()$codigo) {
    if (!any(grepl(paste0(codigo, " se dispara"), texto, fixed = TRUE))) {
      sin_positivo <- c(sin_positivo, codigo)
    }
    if (!any(grepl(paste0(codigo, " no se dispara"), texto, fixed = TRUE))) {
      sin_negativo <- c(sin_negativo, codigo)
    }
  }

  # Este mensaje es el que aparecera cuando alguien agregue una alerta
  # y se olvide de probarla.
  expect_identical(sin_positivo, character())
  expect_identical(sin_negativo, character())
})

test_that("las alertas de los pasos 1 a 3 ya tienen sus dos casos", {
  # Version acotada de la prueba anterior: cubre lo que implementa el plan 01.
  # Aqui NO hay skip: A-01..A-12 estan todas implementadas y probadas.
  archivos <- list.files(testthat::test_path("."), pattern = "^test-.*\\.R$",
                         full.names = TRUE)
  expect_gt(length(archivos), 1)

  texto <- unlist(lapply(archivos, readLines, warn = FALSE))
  cat_al <- catalogo_alertas()
  codigos <- cat_al$codigo[cat_al$paso <= 3]

  sin_positivo <- character()
  sin_negativo <- character()
  for (codigo in codigos) {
    if (!any(grepl(paste0(codigo, " se dispara"), texto, fixed = TRUE))) {
      sin_positivo <- c(sin_positivo, codigo)
    }
    if (!any(grepl(paste0(codigo, " no se dispara"), texto, fixed = TRUE))) {
      sin_negativo <- c(sin_negativo, codigo)
    }
  }

  expect_identical(sin_positivo, character())
  expect_identical(sin_negativo, character())
})
