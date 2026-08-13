# Condiciones binarias declaradas en el paso 1.
#
# Una condicion crisp (0/1) ya ES la pertenencia y no se calibra.
# definir_anclas_crisp() lo sabia desde que se replico E012, pero no habia
# forma de DECIRLO: el paso 1 solo ofrecia condicion, resultado o no usar,
# y el paso 4 le pedia tres anclas igual.
#
# La app propone; el investigador confirma. Una columna de ceros y unos
# puede ser una condicion crisp legitima o un item mal exportado, y esa
# diferencia solo la sabe quien recogio los datos.

test_that("una columna de ceros y unos se reconoce como binaria", {
  expect_true(es_columna_binaria(c(0, 1, 1, 0, 1)))
  expect_true(es_columna_binaria(c(0, 1, NA, 1)))
})

test_that("una columna que no es de ceros y unos no lo es", {
  # El caso opuesto del anterior: sin el, un detector que dijera TRUE
  # siempre pasaria la prueba de arriba.
  expect_false(es_columna_binaria(c(1, 2, 3, 4, 5)))
  expect_false(es_columna_binaria(c(0, 1, 0.5)))
  expect_false(es_columna_binaria(c(1, 2)))
  expect_false(es_columna_binaria(c("0", "1")))
})

test_that("una columna constante no se propone como binaria", {
  # Todos unos es 0/1 por su vocabulario, pero no separa ningun caso: no
  # es una condicion, y proponerla invitaria a declararla.
  expect_false(es_columna_binaria(rep(1, 20)))
  expect_false(es_columna_binaria(rep(0, 20)))
  expect_false(es_columna_binaria(c(NA_real_, NA_real_)))
})

test_that("el paso 1 propone como binarias las columnas de ceros y unos", {
  datos <- data.frame(pais = c("a", "b", "c", "d"),
                      EXP = c(0, 1, 1, 0),
                      DELAY = c(12, 40, 55, 3),
                      LIK1 = c(1, 2, 3, 4), LIK2 = c(5, 4, 3, 2),
                      stringsAsFactors = FALSE)

  s <- sugerir_mapeo(datos, "pais")

  expect_identical(s$binarias, "EXP")
})

test_that("un constructo de varios items no se propone como binario", {
  # Promediar varios items 0/1 NO devuelve un 0/1: la propuesta seria
  # falsa, y la app la ofreceria en el desplegable como si nada.
  datos <- data.frame(pais = c("a", "b", "c", "d"),
                      SI1 = c(0, 1, 1, 0), SI2 = c(1, 1, 0, 0),
                      stringsAsFactors = FALSE)

  expect_identical(sugerir_mapeo(datos, "pais")$binarias, character(0))
})

# --- El rol nuevo, de punta a punta -----------------------------------

mapeo_e012 <- function() {
  definir_mapeo(
    columna_id = "pais", encuestados_por_caso = "uno",
    constructos = list(
      list(nombre = "DELAY", rol = "condicion", items = "DELAY"),
      list(nombre = "EXP", rol = "condicion_binaria", items = "EXP"),
      list(nombre = "YLL", rol = "resultado", items = "YLL")))
}

test_that("el mapeo admite el rol de condicion binaria", {
  m <- mapeo_e012()

  expect_identical(condiciones_binarias(m), "EXP")
})

test_that("un rol inventado se sigue rechazando", {
  expect_error(
    definir_mapeo("pais", "uno",
                  list(list(nombre = "EXP", rol = "binaria", items = "EXP"))),
    "binaria")
})

test_that("sin condiciones binarias la lista es vacia, no NULL", {
  m <- definir_mapeo("pais", "uno",
                     list(list(nombre = "DELAY", rol = "condicion",
                               items = "DELAY")))

  expect_identical(condiciones_binarias(m), character(0))
})

test_that("una condicion binaria declarada no dispara A-03", {
  # A-03 existe porque calibrar un solo item Likert produce empates
  # masivos. Una condicion crisp no se calibra, asi que la alerta seria
  # falsa -- y bloqueante, con lo que obligaria a reconocer por escrito un
  # problema que no existe.
  datos <- data.frame(pais = c("a", "b", "c", "d"),
                      DELAY = c(12, 40, 55, 3),
                      EXP = c(0, 1, 1, 0),
                      YLL = c(3, 4, 5, 2), stringsAsFactors = FALSE)

  alertas <- diagnosticar_ingesta(datos, mapeo_e012())

  expect_false("EXP" %in% alertas$contexto[alertas$codigo == "A-03"])
})

test_that("una condicion de un solo item que NO es binaria si dispara A-03", {
  # El caso opuesto: sin el, silenciar A-03 para todo el mundo pasaria la
  # prueba de arriba.
  datos <- data.frame(pais = c("a", "b", "c", "d"),
                      DELAY = c(12, 40, 55, 3),
                      EXP = c(0, 1, 1, 0),
                      YLL = c(3, 4, 5, 2), stringsAsFactors = FALSE)

  alertas <- diagnosticar_ingesta(datos, mapeo_e012())

  expect_true("DELAY" %in% alertas$contexto[alertas$codigo == "A-03"])
})

test_that("el paso 2 no le pide fiabilidad a una condicion binaria", {
  datos <- data.frame(pais = letters[1:12],
                      DELAY = seq(1, 60, length.out = 12),
                      EXP = rep(c(0, 1), 6),
                      YLL = seq(2, 30, length.out = 12),
                      stringsAsFactors = FALSE)

  val <- diagnosticar_validacion(datos, mapeo_e012())

  expect_false("EXP" %in% names(val$resultados))
})

# --- La tabla del anexo tiene que decir que no se calibro -------------

test_that("la tabla de calibracion declara el tipo de cada condicion", {
  anclas <- list(
    DELAY = definir_anclas(60, 30, 5, "distribucion muestral",
                           paste("Percentiles 95 / 50 / 5 del retraso, tal",
                                 "como los declara el estudio replicado.")),
    EXP = definir_anclas_crisp(
      "conocimiento sustantivo",
      paste("Experiencia epidemica previa: el estudio la publica ya",
            "dicotomizada, 1 si el pais afronto una epidemia anterior.")))

  tabla <- tabla_calibracion(anclas, idm = 0.95)

  expect_identical(tabla$tipo, c("difusa", "crisp"))
})

test_that("el guion reproducible no calibra una condicion crisp", {
  # Es el artefacto que un tercero EJECUTA. Pasar una columna 0/1 por
  # QCA::calibrate() con anclas 0 / 0,5 / 1 devuelve 0,05 y 0,95: el guion
  # correria sin error y produciria otros numeros que el informe.
  anclas <- list(
    DELAY = definir_anclas(60, 30, 5, "distribucion muestral",
                           paste("Percentiles 95 / 50 / 5 del retraso, tal",
                                 "como los declara el estudio replicado.")),
    EXP = definir_anclas_crisp(
      "conocimiento sustantivo",
      paste("Experiencia epidemica previa: el estudio la publica ya",
            "dicotomizada, 1 si el pais afronto una epidemia anterior.")),
    YLL = definir_anclas(600, 160, 10, "distribucion muestral",
                         paste("Percentiles 95 / 50 / 5 de los anos de vida",
                               "perdidos, del estudio replicado.")))

  guion <- guion_reproducible(
    ruta_datos = "e012.csv", mapeo = mapeo_e012(), anclas = anclas,
    idm = 0.95,
    umbrales = list(consistencia = 0.80, frecuencia = 1, pri = 0),
    resultado = "YLL")

  expect_match(guion, "calibrado$EXP <- datos$EXP", fixed = TRUE)
  expect_false(grepl("calibrate(datos$EXP", guion, fixed = TRUE))
  # Y la difusa sigue calibrandose: sin esto, un guion que no calibrara
  # nada pasaria igual.
  expect_match(guion, "calibrate(datos$DELAY", fixed = TRUE)
})
