proyecto_informe <- function() {
  ruta <- testthat::test_path("datos", "limpia.csv")
  leido <- leer_datos(ruta)
  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01","CAP02","CAP03")),
    list(nombre = "REDES",   rol = "condicion", items = c("RED01","RED02","RED03")),
    list(nombre = "INNOV",   rol = "resultado", items = c("INN01","INN02","INN03"))))
  just <- strrep("j", 60)
  anclas <- list(
    CAP_ABS = definir_anclas(4, 3, 2, "teoria", just),
    REDES   = definir_anclas(4, 3, 2, "teoria", just),
    INNOV   = definir_anclas(4, 3, 2, "teoria", just))

  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-07", "INNOV", "alfa = 0,710"), 2)
  bit <- cerrar_alerta(bit, "A-07", "INNOV",
                       nota = paste("La escala es corta y el constructo es",
                                    "exploratorio; se reporta la limitacion."),
                       fecha = "2026-07-30T12:00:00Z")

  list(datos = leido$datos, leido = leido, mapeo = m, anclas = anclas,
       bitacora = bit,
       umbrales = list(frecuencia = 2, consistencia = 0.80, pri = 0.70),
       resultado = "INNOV")
}

test_that("reunir_informe trae las once secciones de la especificacion", {
  p <- proyecto_informe()

  inf <- reunir_informe(p$datos, p$mapeo, p$anclas, p$bitacora, p$umbrales,
                        p$resultado, p$leido)

  esperadas <- c("ficha", "mapeo", "validacion", "agregacion", "calibracion",
                 "alertas", "necesidad", "tabla_verdad", "soluciones",
                 "robustez", "declaraciones")
  expect_true(all(esperadas %in% names(inf)))
})

test_that("la ficha declara el idm y la huella del archivo", {
  p <- proyecto_informe()

  inf <- reunir_informe(p$datos, p$mapeo, p$anclas, p$bitacora, p$umbrales,
                        p$resultado, p$leido)

  expect_equal(inf$ficha$idm, 0.95)
  expect_match(inf$ficha$huella, "^[0-9a-f]{64}$")
  expect_identical(inf$ficha$casos, 120L)
  expect_true(nzchar(inf$ficha$r_version))
  expect_true("QCA" %in% names(inf$ficha$paquetes))
})

test_that("la tabla de calibracion trae la justificacion integra", {
  p <- proyecto_informe()

  inf <- reunir_informe(p$datos, p$mapeo, p$anclas, p$bitacora, p$umbrales,
                        p$resultado, p$leido)

  expect_identical(nchar(inf$calibracion$tabla$justificacion[1]), 60L)
})

test_that("las alertas reconocidas llegan con su nota y su titulo", {
  p <- proyecto_informe()

  inf <- reunir_informe(p$datos, p$mapeo, p$anclas, p$bitacora, p$umbrales,
                        p$resultado, p$leido)

  fila <- inf$alertas[inf$alertas$codigo == "A-07", ]
  expect_identical(fila$estado, "reconocida")
  expect_match(fila$nota, "exploratorio")
  expect_identical(fila$titulo, "Fiabilidad dudosa")
})

test_that("las declaraciones obligatorias no se pueden omitir", {
  p <- proyecto_informe()

  inf <- reunir_informe(p$datos, p$mapeo, p$anclas, p$bitacora, p$umbrales,
                        p$resultado, p$leido)

  # El rho vale 1 por construccion: la calibracion es monotona.
  expect_true(all(abs(inf$declaraciones$rho - 1) < 1e-9))
  # El rho se declara por condicion, asi que tiene que venir con nombres:
  # cinco numeros seguidos sin decir de quien es cada uno no se pueden leer.
  expect_named(inf$declaraciones$rho)
  # casos_050 dejo de ser un vector plano: lleva condicion y caso.
  expect_s3_class(inf$declaraciones$casos_050, "data.frame")
  expect_identical(names(inf$declaraciones$casos_050), c("condicion", "caso"))
  expect_type(inf$declaraciones$sesgo_metodo_comun, "logical")
})

test_that("el informe reune los mismos numeros que el motor por separado", {
  # Si estos dos caminos divergieran, el informe estaria contando otra cosa
  # que el analisis. Es la razon de que esta funcion exista.
  p <- proyecto_informe()
  inf <- reunir_informe(p$datos, p$mapeo, p$anclas, p$bitacora, p$umbrales,
                        p$resultado, p$leido)

  agr <- diagnosticar_agregacion(p$datos, p$mapeo)
  cal <- diagnosticar_calibracion(agr$casos, p$anclas, p$mapeo$columna_id)
  nec <- analizar_necesidad(cal$membresias, "INNOV", c("CAP_ABS", "REDES"))

  expect_equal(inf$necesidad$consistencia, nec$consistencia, tolerance = 1e-12)
  expect_equal(inf$necesidad$ron, nec$ron, tolerance = 1e-12)
})

test_that("una condicion sin anclas no llega al informe: falla antes", {
  p <- proyecto_informe()

  expect_error(
    reunir_informe(p$datos, p$mapeo, p$anclas["CAP_ABS"], p$bitacora,
                   p$umbrales, p$resultado, p$leido),
    "REDES")
})

test_that("la declaracion del 0,50 conserva a que condicion pertenece cada caso", {
  # El motor devuelve la correccion como lista por condicion, pero el
  # informe la aplanaba con unlist(): el anexo terminaba enumerando
  # identificadores sueltos, con repeticiones y sin decir donde se
  # corrigio cada uno. El paso 4 promete ese listado como la garantia de
  # que la correccion no pase inadvertida, y asi no se podia leer.
  casos <- data.frame(
    id_empresa = c("E1", "E2", "E3", "E4"),
    CAP_ABS = c(2, 3, 4, 5),
    REDES = c(3, 4, 5, 2),
    INNOV = c(2, 3, 4, 5),
    stringsAsFactors = FALSE)
  just <- paste("Punto medio de la escala Likert de cinco puntos, declarado",
                "para la prueba.")
  anclas <- list(
    CAP_ABS = definir_anclas(4, 3, 2, "teoria", just),
    REDES = definir_anclas(4, 3, 2, "teoria", just),
    INNOV = definir_anclas(4, 3, 2, "teoria", just))

  cal <- diagnosticar_calibracion(casos, anclas, "id_empresa")

  # E2 cae en 0,50 en CAP_ABS; E1 cae en 0,50 en REDES.
  expect_identical(cal$correccion$CAP_ABS, "E2")
  expect_identical(cal$correccion$REDES, "E1")

  tabla <- casos_050_por_condicion(cal$correccion)

  expect_s3_class(tabla, "data.frame")
  expect_identical(names(tabla), c("condicion", "caso"))

  # E2 se corrige en DOS condiciones a la vez, y ese es justamente el caso
  # que aplanar hacia ilegible: aparecia dos veces, sin decir donde.
  expect_setequal(tabla$condicion[tabla$caso == "E2"], c("CAP_ABS", "INNOV"))
  expect_identical(tabla$condicion[tabla$caso == "E1"], "REDES")
})

test_that("sin casos en 0,50 la tabla sale vacia pero con sus columnas", {
  tabla <- casos_050_por_condicion(list(CAP_ABS = character(0),
                                        REDES = character(0)))

  expect_identical(nrow(tabla), 0L)
  expect_identical(names(tabla), c("condicion", "caso"))
})
