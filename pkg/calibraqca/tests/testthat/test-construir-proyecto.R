estado_de_prueba <- function() {
  ruta <- testthat::test_path("datos", "limpia.csv")
  leido <- leer_datos(ruta)
  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01","CAP02","CAP03")),
    list(nombre = "REDES",   rol = "condicion", items = c("RED01","RED02","RED03")),
    list(nombre = "INNOV",   rol = "resultado", items = c("INN01","INN02","INN03"))),
    resultado_mismo_cuestionario = TRUE)
  just <- strrep("j", 55)
  anclas <- list(
    CAP_ABS = definir_anclas(4, 3, 2, "teoria", just),
    REDES   = definir_anclas(4.5, 3.5, 2.5, "normativa sectorial", just),
    INNOV   = definir_anclas(4, 3, 2, "teoria", just))
  bit <- registrar_alertas(nueva_bitacora(),
                           alerta("A-07", "INNOV", "alfa = 0,710"), 2)
  bit <- cerrar_alerta(bit, "A-07", "INNOV", nota = strrep("n", 50),
                       fecha = "2026-07-30T12:00:00Z")

  list(leido = leido, mapeo = m, anclas = anclas, bitacora = bit,
       umbrales = list(frecuencia = 3, consistencia = 0.80, pri = 0.70),
       resultado = "INNOV")
}

test_that("el proyecto lleva mapeo, anclas, umbrales y bitacora", {
  e <- estado_de_prueba()

  p <- construir_proyecto(e$leido, e$mapeo, e$anclas, e$bitacora, e$umbrales,
                          e$resultado, fecha = "2026-07-30T12:00:00Z")

  expect_identical(p$version_esquema, "1.0")
  expect_identical(p$datos$huella_sha256, e$leido$huella_sha256)
  expect_identical(p$mapeo$columna_id, "id_empresa")
  expect_identical(nrow(p$mapeo$constructos), 3L)
  expect_equal(p$calibracion$condiciones$REDES$anclas$plena, 4.5)
  expect_identical(p$analisis$resultado, "INNOV")
  expect_identical(nrow(p$alertas), 1L)
})

test_that("el proyecto sobrevive la ida y vuelta por JSON", {
  # Es la prueba que importa: lo que se descarga tiene que poder volver a
  # cargarse. Si no, el investigador pierde su trabajo.
  e <- estado_de_prueba()
  ruta <- tempfile(fileext = ".json")
  on.exit(unlink(ruta))

  p <- construir_proyecto(e$leido, e$mapeo, e$anclas, e$bitacora, e$umbrales,
                          e$resultado, fecha = "2026-07-30T12:00:00Z")
  guardar_proyecto(p, ruta, fecha = "2026-07-30T12:00:00Z")
  r <- cargar_proyecto(ruta)

  expect_equal(r$calibracion$condiciones$REDES$anclas$cruce, 3.5)
  expect_identical(r$calibracion$condiciones$REDES$fuente, "normativa sectorial")
  expect_identical(nchar(r$calibracion$condiciones$CAP_ABS$justificacion), 55L)
  expect_identical(r$alertas$estado, "reconocida")
  expect_identical(unlist(r$mapeo$constructos$items[1]),
                   c("CAP01", "CAP02", "CAP03"))
})

test_that("el proyecto recuperado alimenta el informe sin tocarlo", {
  # Cierra el circulo: descargar, volver a cargar y generar el informe.
  e <- estado_de_prueba()
  ruta <- tempfile(fileext = ".json")
  on.exit(unlink(ruta))

  p <- construir_proyecto(e$leido, e$mapeo, e$anclas, e$bitacora, e$umbrales,
                          e$resultado, fecha = "2026-07-30T12:00:00Z")
  guardar_proyecto(p, ruta, fecha = "2026-07-30T12:00:00Z")
  r <- cargar_proyecto(ruta)

  mapeo <- definir_mapeo(
    r$mapeo$columna_id, r$mapeo$encuestados_por_caso,
    lapply(seq_len(nrow(r$mapeo$constructos)), function(i) {
      f <- r$mapeo$constructos[i, ]
      list(nombre = f$nombre, rol = f$rol, items = unlist(f$items))
    }))
  anclas <- lapply(r$calibracion$condiciones, function(a)
    definir_anclas(a$anclas$plena, a$anclas$cruce, a$anclas$nula, a$fuente,
                   a$justificacion))

  inf <- reunir_informe(e$leido$datos, mapeo, anclas, r$alertas,
                        r$analisis$umbrales, r$analisis$resultado, e$leido)

  expect_identical(nrow(inf$calibracion$tabla), 3L)
  expect_equal(inf$calibracion$tabla$plena[inf$calibracion$tabla$condicion == "REDES"],
               4.5)
})

test_that("el proyecto no guarda datos crudos", {
  e <- estado_de_prueba()
  ruta <- tempfile(fileext = ".json")
  on.exit(unlink(ruta))

  p <- construir_proyecto(e$leido, e$mapeo, e$anclas, e$bitacora, e$umbrales,
                          e$resultado, fecha = "2026-07-30T12:00:00Z")
  guardar_proyecto(p, ruta, fecha = "2026-07-30T12:00:00Z")

  texto <- paste(readLines(ruta, warn = FALSE), collapse = "\n")
  # Los nombres de columna SI van (hacen falta para retomar); los valores no.
  expect_false(grepl("E001", texto, fixed = TRUE))
  expect_true(grepl("CAP01", texto, fixed = TRUE))
})
