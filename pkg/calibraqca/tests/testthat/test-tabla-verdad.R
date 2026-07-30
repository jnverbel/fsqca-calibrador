datos_lf2 <- function() {
  e <- new.env()
  utils::data("LF", package = "QCA", envir = e)
  d <- e$LF
  cbind(data.frame(caso = rownames(d), stringsAsFactors = FALSE), d)
}

CONDS <- c("DEV", "URB", "LIT", "IND", "STB")

test_that("leer_tabla_verdad devuelve numeros y solo filas observadas", {
  # LA prueba antibug del paso 6. En QCA 3.25 las columnas incl y PRI de
  # tt$tt son character, y las filas no observadas traen "-". Como
  # "-" < "0.7" es TRUE, comparar sin convertir marca casi toda la tabla
  # como PRI bajo. Sobre LF: 30 de 32 filas en vez de 7.
  tt <- construir_tabla_verdad(datos_lf2(), "SURV", CONDS)
  leida <- leer_tabla_verdad(tt)

  expect_type(leida$incl, "double")
  expect_type(leida$PRI, "double")
  expect_false(any(is.na(leida$incl)))
  expect_false(any(is.na(leida$PRI)))
  expect_false("?" %in% leida$OUT)
  expect_identical(nrow(leida), sum(tt$tt$OUT != "?"))
})

test_that("la frecuencia minima cambia cuantas configuraciones se observan", {
  d <- datos_lf2()

  # Con n.cut = 1 QCA reporta 9 configuraciones sobre LF; con n.cut = 2,
  # que es el que corresponde a una muestra de 18 casos, quedan 6.
  con_1 <- leer_tabla_verdad(construir_tabla_verdad(d, "SURV", CONDS,
                                                    frecuencia = 1))
  por_defecto <- leer_tabla_verdad(construir_tabla_verdad(d, "SURV", CONDS))

  expect_identical(nrow(con_1), 9L)
  expect_identical(nrow(por_defecto), 6L)
  expect_identical(umbral_frecuencia(nrow(d)), 2L)   # 18 casos: muestra pequena
  expect_true(all(por_defecto$n >= 2))
})

test_that("umbral_frecuencia marca el limite exacto de muestra pequena", {
  expect_identical(umbral_frecuencia(50), 2L)
  expect_identical(umbral_frecuencia(51), 3L)
  expect_identical(umbral_frecuencia(10), 2L)
  expect_identical(umbral_frecuencia(500), 3L)
})

test_that("A-26 se dispara con consistencia suficiente pero PRI bajo", {
  expect_true(pri_insuficiente(incl = 0.85, pri = 0.65))
})

test_that("A-26 no se dispara con PRI suficiente ni con consistencia baja", {
  expect_false(pri_insuficiente(incl = 0.85, pri = 0.75))
  expect_false(pri_insuficiente(incl = 0.60, pri = 0.65))  # ya no es fila positiva
  expect_false(pri_insuficiente(incl = 0.80, pri = 0.70))  # los limites entran
})

test_that("A-26 se dispara sobre una tabla con una fila de PRI bajo", {
  tabla <- data.frame(fila = c(1L, 2L), OUT = c("1", "1"),
                      n = c(3L, 4L), incl = c(0.85, 0.92), PRI = c(0.65, 0.88),
                      stringsAsFactors = FALSE)

  expect_true("A-26" %in% alertas_tabla_verdad(tabla)$codigo)
})

test_that("A-26 no se dispara cuando todas las filas positivas tienen PRI alto", {
  tabla <- data.frame(fila = c(1L, 2L), OUT = c("1", "0"),
                      n = c(3L, 4L), incl = c(0.92, 0.30), PRI = c(0.88, 0.10),
                      stringsAsFactors = FALSE)

  expect_false("A-26" %in% alertas_tabla_verdad(tabla)$codigo)
})

test_that("A-28 se dispara con una tabla de verdad degenerada", {
  tabla <- data.frame(fila = 1:10, OUT = c(rep("1", 9), "0"),
                      n = rep(2L, 10), incl = rep(0.9, 10), PRI = rep(0.8, 10),
                      stringsAsFactors = FALSE)

  expect_true("A-28" %in% alertas_tabla_verdad(tabla)$codigo)
})

test_that("A-28 no se dispara con un reparto normal", {
  tabla <- data.frame(fila = 1:10, OUT = c(rep("1", 4), rep("0", 6)),
                      n = rep(2L, 10), incl = c(rep(0.9, 4), rep(0.3, 6)),
                      PRI = c(rep(0.8, 4), rep(0.1, 6)),
                      stringsAsFactors = FALSE)

  expect_false("A-28" %in% alertas_tabla_verdad(tabla)$codigo)
})

test_that("A-30 se dispara con filas contradictorias", {
  # Consistencia entre 0,50 y el umbral de 0,80: ni suficiente ni claramente
  # insuficiente.
  tabla <- data.frame(fila = 1:3, OUT = c("1", "0", "0"),
                      n = rep(2L, 3), incl = c(0.90, 0.65, 0.20),
                      PRI = c(0.85, 0.40, 0.05),
                      stringsAsFactors = FALSE)

  expect_true("A-30" %in% alertas_tabla_verdad(tabla)$codigo)
})

test_that("A-30 no se dispara cuando las filas estan claramente a un lado", {
  tabla <- data.frame(fila = 1:3, OUT = c("1", "0", "0"),
                      n = rep(2L, 3), incl = c(0.90, 0.30, 0.20),
                      PRI = c(0.85, 0.10, 0.05),
                      stringsAsFactors = FALSE)

  expect_false("A-30" %in% alertas_tabla_verdad(tabla)$codigo)
})

test_that("los umbrales usados quedan registrados", {
  tt <- construir_tabla_verdad(datos_lf2(), "SURV", CONDS,
                               consistencia = 0.85, pri = 0.75)

  expect_equal(tt$options$incl.cut[[1]], 0.85)
})

test_that("leer_tabla_verdad evita el bug del guion en las filas no observadas", {
  # Contraste directo entre la lectura correcta y la ingenua. Si alguien
  # quita el as.numeric o el filtro de observadas, este numero se dispara.
  tt <- construir_tabla_verdad(datos_lf2(), "SURV", CONDS, frecuencia = 1)

  ingenua <- sum(tt$tt$PRI < as.character(PRI_MINIMO))
  correcta <- sum(mapply(pri_insuficiente,
                         leer_tabla_verdad(tt)$incl,
                         leer_tabla_verdad(tt)$PRI))

  expect_gt(ingenua, 20)     # el "-" de las no observadas se cuela
  expect_lte(correcta, 2)
})

test_that("A-28 se dispara tambien cuando NINGUNA configuracion es suficiente", {
  # El extremo contrario al de arriba, y el que aparece de verdad con
  # efecto techo fuerte: la tabla no tiene ni una fila con resultado 1.
  # QCA::minimize() aborta ahi con "None of the values in OUT is explained",
  # asi que sin esta alerta el investigador solo ve un error en ingles.
  tabla <- data.frame(fila = 1:5, OUT = rep("0", 5),
                      n = rep(3L, 5), incl = c(0.70, 0.65, 0.60, 0.40, 0.30),
                      PRI = c(0.5, 0.4, 0.3, 0.2, 0.1),
                      stringsAsFactors = FALSE)

  alertas <- alertas_tabla_verdad(tabla)

  expect_true("A-28" %in% alertas$codigo)
  expect_match(alertas$detalle[alertas$codigo == "A-28"], "ninguna|Ninguna")
})

test_that("A-28 no se dispara con al menos una configuracion suficiente", {
  tabla <- data.frame(fila = 1:5, OUT = c("1", rep("0", 4)),
                      n = rep(3L, 5), incl = c(0.90, 0.40, 0.35, 0.30, 0.20),
                      PRI = c(0.85, 0.2, 0.15, 0.1, 0.05),
                      stringsAsFactors = FALSE)

  expect_false("A-28" %in% alertas_tabla_verdad(tabla)$codigo)
})
