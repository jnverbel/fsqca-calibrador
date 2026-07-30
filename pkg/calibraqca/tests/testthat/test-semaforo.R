# Construye una matriz de membresias con la columna de id. Cada argumento
# con nombre es una condicion.
matriz <- function(...) {
  cols <- list(...)
  n <- length(cols[[1]])
  cbind(data.frame(id_empresa = sprintf("E%03d", seq_len(n)),
                   stringsAsFactors = FALSE),
        as.data.frame(cols))
}

# Una condicion repartida por todo el rango: el contraste sano.
sana <- function(n = 100) seq(0.02, 0.98, length.out = n)

# Segunda condicion, independiente de la primera. NO vale rev(sana()):
# correlaciona exactamente -1 y dispara A-24 en todos los escenarios que
# pretenden estar sanos.
otra <- function(n = 100) {
  set.seed(42)
  stats::runif(n, 0.02, 0.98)
}

# Par con correlacion intermedia (r = 0,861). NO vale una transformacion
# lineal del tipo a * 0,99: da r = 1 exactamente, y entonces subir
# CORRELACION_MAXIMA a 0,999 sigue disparando la alerta y la constante se
# queda sin prueba.
par_correlacionado <- function(w = 0.62, n = 100) {
  set.seed(101); a <- stats::runif(n, 0.02, 0.98)
  set.seed(202); b <- w * a + (1 - w) * stats::runif(n, 0.02, 0.98)
  list(a = a, b = b)
}

test_that("cada predicado del semaforo marca su limite exacto", {
  # Los umbrales viven dentro de condiciones compuestas en el diagnostico;
  # aislados aqui, cada constante tiene su propia prueba.
  expect_true(hay_techo(c(rep(0.9, 86), rep(0.1, 14))))
  expect_false(hay_techo(c(rep(0.9, 85), rep(0.1, 15))))   # 85 % no lo supera

  expect_true(hay_piso(c(rep(0.1, 86), rep(0.9, 14))))
  expect_false(hay_piso(c(rep(0.1, 85), rep(0.9, 15))))

  expect_false(discrimina(c(rep(0.49, 50), rep(0.51, 50))))
  expect_true(discrimina(sana()))

  expect_true(muy_asimetrica(c(rep(0.02, 95), rep(0.98, 5))))
  expect_false(muy_asimetrica(sana()))

  alto <- par_correlacionado(0.62)    # r = 0,861, entre el umbral y 1
  bajo <- par_correlacionado(0.50)    # r = 0,718, por debajo del umbral
  expect_gt(stats::cor(alto$a, alto$b), 0.80)   # el escenario es el que se cree
  expect_lt(stats::cor(bajo$a, bajo$b), 0.80)
  expect_true(muy_correlacionadas(alto$a, alto$b))
  expect_false(muy_correlacionadas(bajo$a, bajo$b))

  expect_true(diversidad_limitada(n_casos = 3, n_condiciones = 4))   # 16/4 = 4
  expect_false(diversidad_limitada(n_casos = 50, n_condiciones = 3)) # 8/4 = 2
})

test_that("A-18 se dispara con efecto techo", {
  m <- matriz(CAP_ABS = c(rep(0.9, 90), rep(0.2, 10)), REDES = sana())

  res <- diagnosticar_semaforo(m, columna_id = "id_empresa")

  expect_true("A-18" %in% res$alertas$codigo)
  expect_identical(res$alertas$contexto[res$alertas$codigo == "A-18"], "CAP_ABS")
})

test_that("A-18 no se dispara con las membresias repartidas", {
  m <- matriz(CAP_ABS = sana(), REDES = otra())

  expect_false("A-18" %in% diagnosticar_semaforo(m, "id_empresa")$alertas$codigo)
})

test_that("A-19 se dispara con efecto piso", {
  m <- matriz(CAP_ABS = c(rep(0.1, 90), rep(0.8, 10)), REDES = sana())

  expect_true("A-19" %in% diagnosticar_semaforo(m, "id_empresa")$alertas$codigo)
})

test_that("A-19 no se dispara con las membresias repartidas", {
  m <- matriz(CAP_ABS = sana(), REDES = otra())

  expect_false("A-19" %in% diagnosticar_semaforo(m, "id_empresa")$alertas$codigo)
})

test_that("A-20 se dispara con una condicion que no discrimina", {
  m <- matriz(CAP_ABS = c(rep(0.49, 50), rep(0.51, 50)), REDES = sana())

  expect_true("A-20" %in% diagnosticar_semaforo(m, "id_empresa")$alertas$codigo)
})

test_that("A-20 no se dispara con variacion suficiente", {
  m <- matriz(CAP_ABS = sana(), REDES = otra())

  expect_false("A-20" %in% diagnosticar_semaforo(m, "id_empresa")$alertas$codigo)
})

test_that("A-21 se dispara con asimetria fuerte", {
  m <- matriz(CAP_ABS = c(rep(0.02, 95), rep(0.98, 5)), REDES = sana())

  expect_true("A-21" %in% diagnosticar_semaforo(m, "id_empresa")$alertas$codigo)
})

test_that("A-21 no se dispara con una distribucion simetrica", {
  m <- matriz(CAP_ABS = sana(), REDES = otra())

  expect_false("A-21" %in% diagnosticar_semaforo(m, "id_empresa")$alertas$codigo)
})

test_that("A-22 se dispara con membresias identicas entre casos", {
  m <- matriz(CAP_ABS = c(0.1, 0.5, 0.9, 0.1), REDES = c(0.2, 0.6, 0.8, 0.2))

  res <- diagnosticar_semaforo(m, "id_empresa")

  expect_true("A-22" %in% res$alertas$codigo)
  expect_match(res$alertas$detalle[res$alertas$codigo == "A-22"], "E001")
})

test_that("A-22 no se dispara si todos los casos son distintos", {
  m <- matriz(CAP_ABS = c(0.1, 0.5, 0.9), REDES = c(0.2, 0.6, 0.8))

  expect_false("A-22" %in% diagnosticar_semaforo(m, "id_empresa")$alertas$codigo)
})

test_that("A-23 se dispara con diversidad limitada", {
  m <- matriz(A = c(0.1, 0.5, 0.9), B = c(0.2, 0.6, 0.8),
              C = c(0.3, 0.7, 0.1), D = c(0.4, 0.8, 0.2))

  expect_true("A-23" %in% diagnosticar_semaforo(m, "id_empresa")$alertas$codigo)
})

test_that("A-23 no se dispara con casos suficientes", {
  m <- matriz(CAP_ABS = sana(50), REDES = otra(50))

  expect_false("A-23" %in% diagnosticar_semaforo(m, "id_empresa")$alertas$codigo)
})

test_that("A-24 se dispara con dos condiciones muy correlacionadas", {
  par <- par_correlacionado(0.62)
  m <- matriz(CAP_ABS = par$a, REDES = par$b)

  res <- diagnosticar_semaforo(m, "id_empresa")

  expect_true("A-24" %in% res$alertas$codigo)
  expect_match(res$alertas$detalle[res$alertas$codigo == "A-24"], "REDES")
})

test_that("A-24 no se dispara con condiciones independientes", {
  set.seed(3)
  m <- matriz(CAP_ABS = stats::runif(100), REDES = stats::runif(100))

  expect_false("A-24" %in% diagnosticar_semaforo(m, "id_empresa")$alertas$codigo)
})

test_that("A-25 se dispara si el resultado sale del mismo cuestionario", {
  m <- matriz(CAP_ABS = sana(), REDES = otra())

  res <- diagnosticar_semaforo(m, "id_empresa",
                               resultado_mismo_cuestionario = TRUE)

  expect_true("A-25" %in% res$alertas$codigo)
})

test_that("A-25 no se dispara si el resultado viene de otra fuente", {
  m <- matriz(CAP_ABS = sana(), REDES = otra())

  res <- diagnosticar_semaforo(m, "id_empresa",
                               resultado_mismo_cuestionario = FALSE)

  expect_false("A-25" %in% res$alertas$codigo)
})

test_that("el resumen trae una fila por condicion con sus estadisticos", {
  m <- matriz(CAP_ABS = sana(), REDES = otra())

  res <- diagnosticar_semaforo(m, "id_empresa")

  expect_identical(nrow(res$resumen), 2L)
  expect_identical(res$resumen$condicion, c("CAP_ABS", "REDES"))
  expect_true(all(c("pct_sobre_050", "sd", "asimetria") %in% names(res$resumen)))
})

test_that("una matriz sin problemas no dispara nada y deja avanzar", {
  m <- matriz(CAP_ABS = sana(), REDES = otra())

  res <- diagnosticar_semaforo(m, "id_empresa")
  bit <- registrar_alertas(nueva_bitacora(), res$alertas, paso = 5)

  expect_identical(nrow(res$alertas), 0L)
  expect_true(puede_avanzar(bit, paso = 5))
})
