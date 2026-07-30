FECHA <- "2026-07-30T12:00:00Z"

test_that("una bitacora nueva esta vacia y tiene las columnas del esquema", {
  bit <- nueva_bitacora()

  expect_identical(nrow(bit), 0L)
  expect_identical(names(bit),
                   c("codigo", "paso", "severidad", "contexto",
                     "detalle", "estado", "nota", "cerrada"))
})

test_that("registrar una alerta nueva la deja abierta y le pega su severidad", {
  bit <- registrar_alertas(
    nueva_bitacora(),
    alerta("A-06", contexto = "CAP_ABS", detalle = "alfa = 0,58"),
    paso = 2
  )

  expect_identical(nrow(bit), 1L)
  expect_identical(bit$estado, "abierta")
  expect_identical(bit$severidad, "bloqueante")  # viene del catalogo, no del que llama
  expect_identical(bit$paso, 2L)
  expect_identical(bit$nota, NA_character_)
})

test_that("una alerta que deja de dispararse pasa a resuelta", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-06", "CAP_ABS", "alfa = 0,58"), paso = 2)
  bit <- registrar_alertas(bit, alerta("A-07", "CAP_ABS", "alfa = 0,74"), paso = 2)

  expect_identical(bit$estado[bit$codigo == "A-06"], "resuelta")
  expect_identical(bit$estado[bit$codigo == "A-07"], "abierta")
})

test_that("una alerta reconocida conserva su nota al volver a dispararse", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-06", "CAP_ABS", "alfa = 0,58"), paso = 2)
  bit <- cerrar_alerta(bit, "A-06", "CAP_ABS",
                       nota = paste("La escala es corta y el constructo es",
                                    "exploratorio; se reporta la limitacion."),
                       fecha = FECHA)
  bit <- registrar_alertas(bit, alerta("A-06", "CAP_ABS", "alfa = 0,59"), paso = 2)

  expect_identical(bit$estado, "reconocida")
  expect_true(grepl("exploratorio", bit$nota))
  expect_identical(bit$cerrada, FECHA)
  expect_identical(bit$detalle, "alfa = 0,59")  # el detalle si se actualiza
})

test_that("las alertas de otros pasos no se tocan al registrar", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-03", "CAP_ABS", "1 item"), paso = 1)
  bit <- registrar_alertas(bit, alerta("A-06", "REDES", "alfa = 0,61"), paso = 2)

  expect_identical(nrow(bit), 2L)
  expect_identical(bit$estado[bit$codigo == "A-03"], "abierta")
})

test_that("un codigo fuera del catalogo es un error, no una alerta silenciosa", {
  expect_error(alerta("A-99"), "A-99")
})

test_that("dos contextos de la misma alerta son dos alertas distintas", {
  bit <- registrar_alertas(
    nueva_bitacora(),
    rbind(alerta("A-06", "CAP_ABS", "alfa = 0,58"),
          alerta("A-06", "REDES", "alfa = 0,62")),
    paso = 2
  )

  expect_identical(nrow(bit), 2L)
})

test_that("registrar en el paso equivocado es un error", {
  expect_error(
    registrar_alertas(nueva_bitacora(), alerta("A-06", "CAP_ABS"), paso = 1),
    "paso"
  )
})
