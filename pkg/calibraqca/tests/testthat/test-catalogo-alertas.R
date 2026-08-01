test_that("el catalogo tiene las 35 alertas de la especificacion", {
  cat_al <- catalogo_alertas()

  expect_s3_class(cat_al, "data.frame")
  expect_identical(nrow(cat_al), 35L)
  expect_identical(cat_al$codigo, sprintf("A-%02d", 1:35))
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
  esperado <- c(`1` = 5L, `2` = 5L, `3` = 2L, `4` = 6L,
                `5` = 8L, `6` = 7L, `7` = 2L)
  observado <- table(catalogo_alertas()$paso)

  expect_identical(as.integer(observado[names(esperado)]), unname(esperado))
})

test_that("toda alerta del catalogo tiene un caso que la dispara y uno que no", {
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
