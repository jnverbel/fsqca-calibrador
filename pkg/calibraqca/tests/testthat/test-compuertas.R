NOTA_VALIDA <- paste("El efecto techo refleja un rasgo real del sector y no",
                     "un defecto de la medida; se reporta en el capitulo.")

test_that("una nota valida de la prueba supera el minimo exigido", {
  # Si alguien acorta NOTA_VALIDA, esta prueba avisa antes de que fallen
  # las de abajo por una razon que no es la que se esta probando.
  expect_gte(nchar(NOTA_VALIDA), 40)
})

test_that("una alerta bloqueante abierta impide avanzar", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-06", "CAP_ABS", "alfa = 0,58"), paso = 2)

  expect_false(puede_avanzar(bit, paso = 2))
})

test_that("una advertencia abierta tambien impide avanzar", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-07", "CAP_ABS", "alfa = 0,74"), paso = 2)

  expect_false(puede_avanzar(bit, paso = 2))
})

test_that("una alerta informativa no impide avanzar", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-09", "CAP_ABS", "alfa = 0,96"), paso = 2)

  expect_true(puede_avanzar(bit, paso = 2))
})

test_that("reconocer por escrito deja avanzar", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-06", "CAP_ABS", "alfa = 0,58"), paso = 2)
  bit <- cerrar_alerta(bit, "A-06", "CAP_ABS", nota = NOTA_VALIDA)

  expect_true(puede_avanzar(bit, paso = 2))
})

test_that("una nota corta o vacia es rechazada", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-06", "CAP_ABS", "alfa = 0,58"), paso = 2)

  expect_error(cerrar_alerta(bit, "A-06", "CAP_ABS", nota = "ok"), "40")
  expect_error(cerrar_alerta(bit, "A-06", "CAP_ABS", nota = ""), "40")
  expect_error(cerrar_alerta(bit, "A-06", "CAP_ABS", nota = strrep(" ", 60)), "40")
})

test_that("una alerta resuelta deja avanzar y sigue en la bitacora", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-06", "CAP_ABS", "alfa = 0,58"), paso = 2)
  bit <- registrar_alertas(bit, NULL, paso = 2)

  expect_true(puede_avanzar(bit, paso = 2))
  expect_identical(nrow(bit), 1L)          # no desaparece: sale en el informe
  expect_identical(bit$estado, "resuelta")
})

test_that("una alerta abierta de otro paso no bloquea el paso actual", {
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-03", "CAP_ABS", "1 item"), paso = 1)

  expect_false(puede_avanzar(bit, paso = 1))
  expect_true(puede_avanzar(bit, paso = 2))
})

test_that("cerrar una alerta que no esta en la bitacora es un error", {
  expect_error(cerrar_alerta(nueva_bitacora(), "A-06", "CAP_ABS",
                             nota = NOTA_VALIDA), "A-06")
})
