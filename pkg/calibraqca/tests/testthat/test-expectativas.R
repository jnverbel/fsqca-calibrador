# Expectativas direccionales: la decision teorica que produce la
# solucion intermedia.
#
# El motor ya sabia recibirlas -- minimizar(tt, expectativas) --, pero solo
# en notacion SOP, que es la del paquete QCA y no la del investigador. Lo
# que falta es la declaracion: por condicion, si la teoria espera su
# presencia, su ausencia o nada, y por que.

test_that("una expectativa se declara con su direccion y su justificacion", {
  e <- definir_expectativa("presente", paste(
    "La literatura sobre respuesta a epidemias sostiene que el retraso en",
    "cerrar fronteras agrava la mortalidad."))

  expect_identical(e$direccion, "presente")
  expect_match(e$justificacion, "retraso")
})

test_that("solo se admiten las tres direcciones del catalogo", {
  expect_error(definir_expectativa("quiza", paste(
    "Un texto suficientemente largo para pasar el minimo de caracteres.")),
    "quiza")
  # El mensaje tiene que decir cuales SI se admiten, no solo cual no.
  expect_error(definir_expectativa("presencia", "texto largo de sobra aqui va"),
               "presente")
})

test_that("declarar presencia o ausencia exige justificacion escrita", {
  # Es la sena de identidad de la herramienta: la decision metodologica
  # sale impresa en el informe, asi que hay que escribirla.
  expect_error(definir_expectativa("presente", "poco"), "30")
  expect_error(definir_expectativa("ausente", "poco"), "30")
})

test_that("'indiferente' no exige justificacion: no afirma nada", {
  # No es un descuido: "no importa" es la AUSENCIA de una afirmacion
  # teorica, y no hay nada que defender ante un jurado.
  e <- definir_expectativa("indiferente")

  expect_identical(e$direccion, "indiferente")
  expect_identical(e$justificacion, "")
})

test_that("indiferente admite texto si el investigador quiere explicarse", {
  e <- definir_expectativa("indiferente", paste(
    "La teoria no se pronuncia sobre la densidad, asi que no se declara",
    "ninguna direccion."))

  expect_match(e$justificacion, "densidad")
})

test_that("la notacion SOP sale de las expectativas, no del investigador", {
  # QCA 3.25 quiere "DELAY + EXP + ~ELDERLY". Pedirle eso a quien usa la
  # herramienta seria pedirle que aprenda la sintaxis del paquete que la
  # herramienta existe para envolver.
  larga <- paste("Justificacion teorica suficientemente larga para el",
                 "minimo exigido.")
  sop <- expectativas_sop(list(
    DELAY = definir_expectativa("presente", larga),
    EXP = definir_expectativa("presente", larga),
    ELDERLY = definir_expectativa("ausente", larga),
    DENSITY = definir_expectativa("indiferente")))

  expect_identical(sop, "DELAY + EXP + ~ELDERLY")
})

test_that("una expectativa por condicion basta escrita como texto", {
  # El archivo de proyecto guarda "presente", no el objeto entero.
  expect_identical(
    expectativas_sop(list(A = "presente", B = "ausente", C = "indiferente")),
    "A + ~B")
})

test_that("sin ninguna direccion declarada no hay notacion que construir", {
  # NULL y no "": QCA aborta con una cadena vacia, y minimizar() ya sabe
  # que NULL significa "no se produce la intermedia".
  expect_null(expectativas_sop(list(A = definir_expectativa("indiferente"),
                                    B = definir_expectativa("indiferente"))))
  expect_null(expectativas_sop(list()))
  expect_null(expectativas_sop(NULL))
})

test_that("una expectativa sin condicion a la que pertenecer se rechaza", {
  larga <- paste("Justificacion teorica suficientemente larga para el",
                 "minimo exigido.")
  expect_error(expectativas_sop(list(definir_expectativa("presente", larga))),
               "nombre")
})

test_that("la tabla de expectativas lleva la justificacion integra al informe", {
  larga <- paste("El retraso en cerrar fronteras agrava la mortalidad segun",
                 "la literatura sobre respuesta a epidemias previas.")
  tabla <- tabla_expectativas(list(
    DELAY = definir_expectativa("presente", larga),
    DENSITY = definir_expectativa("indiferente")))

  expect_identical(tabla$condicion, c("DELAY", "DENSITY"))
  expect_identical(tabla$direccion, c("presente", "indiferente"))
  expect_identical(tabla$justificacion[1], larga)
  expect_identical(tabla$justificacion[2], "")
})

test_that("la tabla de expectativas existe aunque no haya ninguna", {
  tabla <- tabla_expectativas(NULL)

  expect_identical(nrow(tabla), 0L)
  expect_true(all(c("condicion", "direccion", "justificacion") %in%
                    names(tabla)))
})

# --- De la declaracion a la solucion publicada -----------------------

test_that("las expectativas declaradas de E012 producen su intermedia", {
  # La prueba que ata las dos mitades: lo que el investigador declara en
  # la pantalla y lo que QCA necesita recibir. Si expectativas_sop()
  # tradujera mal, aqui saldria otra solucion.
  skip_if_not_installed("QCA")

  d <- utils::read.csv(testthat::test_path("datos",
                                           "e012-covid-80-paises.csv"),
                       stringsAsFactors = FALSE)
  continuas <- c("DELAY", "ELDERLY", "DENSITY", "INCOME", "YLL")
  anclas <- lapply(continuas, function(cond) {
    q <- stats::quantile(d[[cond]], c(0.05, 0.50, 0.95), na.rm = TRUE)
    definir_anclas(nula = unname(q[1]), cruce = unname(q[2]),
                   plena = unname(q[3]), fuente = "distribucion muestral",
                   justificacion = paste("Percentiles 95 / 50 / 5 de", cond,
                                         "declarados en el estudio publicado."))
  })
  names(anclas) <- continuas
  anclas$EXP <- definir_anclas_crisp(
    "conocimiento sustantivo",
    "Experiencia epidemica previa, publicada ya dicotomizada por los autores.")

  larga <- paste("La literatura de respuesta a epidemias espera que esta",
                 "condicion contribuya a la mortalidad observada.")
  sop <- expectativas_sop(list(
    DELAY = definir_expectativa("presente", larga),
    EXP = definir_expectativa("presente", larga),
    ELDERLY = definir_expectativa("presente", larga),
    DENSITY = definir_expectativa("indiferente"),
    INCOME = definir_expectativa("indiferente")))

  membresias <- diagnosticar_calibracion(d, anclas, "pais")$membresias
  tt <- construir_tabla_verdad(membresias, "YLL",
                               c("DELAY", "EXP", "ELDERLY", "DENSITY",
                                 "INCOME"),
                               consistencia = 0.80, frecuencia = 1, pri = 0)

  expect_identical(sop, "DELAY + EXP + ELDERLY")
  expect_setequal(minimizar(tt, expectativas = sop)$intermedia$terminos,
                  c("DENSITY*INCOME", "~EXP*ELDERLY*DENSITY",
                    "EXP*~ELDERLY*INCOME", "DELAY*EXP*INCOME"))
})

# --- Del formulario al informe y al archivo de proyecto ---------------

proyecto_con_expectativas <- function() {
  ruta <- testthat::test_path("datos", "limpia.csv")
  leido <- leer_datos(ruta)
  m <- definir_mapeo("id_empresa", "uno", list(
    list(nombre = "CAP_ABS", rol = "condicion",
         items = c("CAP01", "CAP02", "CAP03")),
    list(nombre = "REDES", rol = "condicion",
         items = c("RED01", "RED02", "RED03")),
    list(nombre = "INNOV", rol = "resultado",
         items = c("INN01", "INN02", "INN03"))))
  just <- strrep("j", 60)
  anclas <- list(CAP_ABS = definir_anclas(4, 3, 2, "teoria", just),
                 REDES = definir_anclas(4, 3, 2, "teoria", just),
                 INNOV = definir_anclas(4, 3, 2, "teoria", just))
  list(datos = leido$datos, leido = leido, mapeo = m, anclas = anclas,
       bitacora = nueva_bitacora(),
       umbrales = list(frecuencia = 2, consistencia = 0.80, pri = 0.70),
       resultado = "INNOV",
       expectativas = list(
         CAP_ABS = definir_expectativa("presente", paste(
           "La capacidad de absorcion habilita la innovacion segun Zahra y",
           "George (2002).")),
         REDES = definir_expectativa("indiferente")))
}

test_that("las expectativas declaradas producen la intermedia del informe", {
  # El informe llamaba a diagnosticar_suficiencia() sin expectativas, asi
  # que la intermedia salia SIEMPRE como no producida -- tambien cuando el
  # investigador las habia declarado.
  skip_if_not_installed("QCA")
  p <- proyecto_con_expectativas()

  inf <- reunir_informe(p$datos, p$mapeo, p$anclas, p$bitacora, p$umbrales,
                        p$resultado, p$leido, expectativas = p$expectativas)

  expect_false(is.null(inf$soluciones$intermedia))
  expect_gt(length(inf$soluciones$intermedia$terminos), 0)
})

test_that("sin expectativas el informe sigue diciendo que no se produjo", {
  # El caso opuesto: sin el, pasar siempre unas expectativas inventadas
  # aprobaria la prueba de arriba.
  skip_if_not_installed("QCA")
  p <- proyecto_con_expectativas()

  inf <- reunir_informe(p$datos, p$mapeo, p$anclas, p$bitacora, p$umbrales,
                        p$resultado, p$leido)

  expect_null(inf$soluciones$intermedia)
  expect_identical(nrow(inf$expectativas), 0L)
})

test_that("el informe lleva la justificacion de cada expectativa, integra", {
  skip_if_not_installed("QCA")
  p <- proyecto_con_expectativas()

  inf <- reunir_informe(p$datos, p$mapeo, p$anclas, p$bitacora, p$umbrales,
                        p$resultado, p$leido, expectativas = p$expectativas)

  expect_identical(inf$expectativas$condicion, c("CAP_ABS", "REDES"))
  expect_match(inf$expectativas$justificacion[1], "Zahra y George")
})

test_that("el archivo de proyecto guarda las expectativas direccionales", {
  # Sin esto, reabrir el proyecto perderia la decision teorica que produjo
  # la solucion que se reporta.
  p <- proyecto_con_expectativas()

  proyecto <- construir_proyecto(
    leido = p$leido, mapeo = p$mapeo, anclas = p$anclas,
    bitacora = p$bitacora, umbrales = p$umbrales, resultado = p$resultado,
    expectativas = p$expectativas)

  expect_identical(proyecto$analisis$expectativas_direccionales$CAP_ABS,
                   "presente")
  expect_identical(proyecto$analisis$expectativas_direccionales$REDES,
                   "indiferente")
  expect_match(
    proyecto$analisis$justificacion_expectativas$CAP_ABS, "Zahra y George")
})

test_that("el guion reproducible pide la intermedia por su bloque i.sol", {
  # El primer nivel del objeto que devuelve minimize() con dir.exp es la
  # PARSIMONIOSA. Un guion que imprimiera sol$solution reproduciria otra
  # solucion que la del informe, sin error y con la etiqueta correcta.
  p <- proyecto_con_expectativas()

  guion <- guion_reproducible(
    ruta_datos = "limpia.csv", mapeo = p$mapeo, anclas = p$anclas, idm = 0.95,
    umbrales = p$umbrales, resultado = p$resultado,
    expectativas = expectativas_sop(p$expectativas))

  expect_match(guion, 'dir.exp = "CAP_ABS"', fixed = TRUE)
  expect_match(guion, "i.sol$C1P1", fixed = TRUE)
})

test_that("sin expectativas el guion no finge una intermedia", {
  p <- proyecto_con_expectativas()

  guion <- guion_reproducible(
    ruta_datos = "limpia.csv", mapeo = p$mapeo, anclas = p$anclas, idm = 0.95,
    umbrales = p$umbrales, resultado = p$resultado)

  expect_false(grepl("dir.exp", guion, fixed = TRUE))
  expect_match(guion, "No se declararon expectativas direccionales")
})
