# El factorial confirmatorio del paso 2. El calculo lo hace lavaan.
#
# cfa_viable() ya decidia si la muestra lo sostiene, pero nadie ejecutaba
# el modelo: el informe imprimia la version de lavaan y su cita sin que
# lavaan hubiera calculado nada. Corregido el 2026-07-31.

datos_encuesta <- function() {
  utils::read.csv(test_path("datos/limpia.csv"), stringsAsFactors = FALSE)
}

constructos_encuesta <- function() {
  list(
    list(nombre = "CAP", items = c("CAP01", "CAP02", "CAP03")),
    list(nombre = "RED", items = c("RED01", "RED02", "RED03")),
    list(nombre = "INN", items = c("INN01", "INN02", "INN03"))
  )
}

test_that("el modelo se escribe en la sintaxis de lavaan, un factor por constructo", {
  obs <- modelo_cfa(constructos_encuesta())

  expect_match(obs, "CAP =~ CAP01 + CAP02 + CAP03", fixed = TRUE)
  expect_match(obs, "RED =~ RED01 + RED02 + RED03", fixed = TRUE)
  expect_match(obs, "INN =~ INN01 + INN02 + INN03", fixed = TRUE)
})

test_that("el ajuste del CFA coincide con lavaan llamado directamente", {
  datos <- datos_encuesta()

  obs <- ajustar_cfa(datos, constructos_encuesta())

  # Fuente independiente: lavaan, con el mismo modelo y los mismos datos.
  esperado <- lavaan::fitMeasures(
    lavaan::cfa(modelo_cfa(constructos_encuesta()), data = datos,
                std.lv = TRUE),
    c("chisq", "df", "cfi", "tli", "rmsea", "srmr"))

  expect_true(obs$ejecutado)
  expect_equal(obs$chi2, unname(esperado["chisq"]))
  expect_equal(obs$gl, unname(esperado["df"]))
  expect_equal(obs$cfi, unname(esperado["cfi"]))
  expect_equal(obs$tli, unname(esperado["tli"]))
  expect_equal(obs$rmsea, unname(esperado["rmsea"]))
  expect_equal(obs$srmr, unname(esperado["srmr"]))
})

test_that("un modelo que no converge se declara en vez de abortar el paso 2", {
  datos <- datos_encuesta()
  # Un constructo cuyos items no existen hace fallar a lavaan.
  inventado <- list(list(nombre = "X", items = c("NO01", "NO02", "NO03")))

  obs <- ajustar_cfa(datos, inventado)

  expect_false(obs$ejecutado)
  expect_true(nchar(obs$motivo) > 0)
  expect_true(is.na(obs$cfi))
})

test_that("el paso 2 ejecuta el CFA cuando la muestra lo sostiene", {
  datos <- datos_encuesta()
  mapeo <- list(constructos = constructos_encuesta())

  obs <- diagnosticar_validacion(datos, mapeo)

  # 120 casos para 21 parametros libres: 5 por parametro exige 105.
  expect_true(obs$cfa$viable)
  expect_true(obs$cfa$ajuste$ejecutado)
  expect_true(obs$cfa$ajuste$cfi >= 0 && obs$cfa$ajuste$cfi <= 1)
})

test_that("el paso 2 no ejecuta el CFA si la muestra no lo sostiene", {
  datos <- datos_encuesta()[1:40, ]
  mapeo <- list(constructos = constructos_encuesta())

  obs <- diagnosticar_validacion(datos, mapeo)

  expect_false(obs$cfa$viable)
  expect_false(obs$cfa$ajuste$ejecutado)
  expect_match(obs$cfa$ajuste$motivo, "omite")
  expect_true("A-10" %in% obs$alertas$codigo)
})
