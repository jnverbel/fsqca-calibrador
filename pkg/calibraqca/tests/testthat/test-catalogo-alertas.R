test_that("el catalogo tiene las 36 alertas de la especificacion", {
  cat_al <- catalogo_alertas()

  expect_s3_class(cat_al, "data.frame")
  expect_identical(nrow(cat_al), 36L)
  expect_identical(cat_al$codigo, sprintf("A-%02d", 1:36))
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
                `5` = 8L, `6` = 8L, `7` = 2L)
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

# --- El README no puede mentir sobre el tamano del catalogo -----------
#
# Los dos README anuncian cuantas alertas tiene la especificacion. Es un
# numero que se queda viejo en silencio en cuanto se agrega una alerta: la
# suite sigue verde, el catalogo crece y la portada del repositorio sigue
# prometiendo el numero anterior. Aqui queda atado al catalogo de verdad.

.raiz_repo <- function() testthat::test_path("..", "..", "..", "..")

test_that("los README anuncian tantas alertas como tiene el catalogo", {
  n <- nrow(catalogo_alertas())
  archivos <- c(es = file.path(.raiz_repo(), "README.es.md"),
                en = file.path(.raiz_repo(), "README.md"))
  # Los README viven en el repositorio y no dentro del paquete instalado.
  # Bajo test_local() -- que es lo que corre el CI -- estan siempre, asi
  # que esto no omite nada ahi; bajo R CMD check el arbol es otro y la
  # prueba no aplica.
  skip_if_not(all(file.exists(archivos)), "los README no son alcanzables")

  texto <- vapply(archivos, function(f)
    paste(readLines(f, warn = FALSE), collapse = "\n"), character(1))

  expect_true(grepl(sprintf("las %d alertas", n), texto[["es"]], fixed = TRUE))
  expect_true(grepl(sprintf("the %d alerts", n), texto[["en"]], fixed = TRUE))
})

test_that("la especificacion documenta la ultima alerta del catalogo", {
  ultima <- utils::tail(catalogo_alertas()$codigo, 1)
  spec <- file.path(.raiz_repo(), "docs", "especificacion.md")
  skip_if_not(file.exists(spec), "la especificacion no es alcanzable")

  texto <- paste(readLines(spec, warn = FALSE), collapse = "\n")

  expect_true(grepl(paste0("`", ultima, "`"), texto, fixed = TRUE))
})
