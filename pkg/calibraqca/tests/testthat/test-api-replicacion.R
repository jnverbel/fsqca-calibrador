# Los huecos de la API publica que obligaron a los replicadores a salirse
# del motor.
#
# Todos salieron de replicar ocho estudios por el camino publico, que es el
# del investigador: no son defectos de calculo sino cosas que el motor no
# sabia hacer y que quien replica necesita en cada estudio.

skip_if_not_installed("QCA")

lipset <- function() {
  e <- new.env()
  utils::data("LF", package = "QCA", envir = e)
  d <- e$LF
  cbind(data.frame(caso = rownames(d), stringsAsFactors = FALSE), d)
}

CONDS_REPLICA <- c("DEV", "URB", "LIT", "IND", "STB")

# --- 3.1 Evaluar el ajuste de una expresion dada ----------------------

test_that("ajuste_de_expresion evalua la expresion del articulo sobre tus membresias", {
  # El unico hueco que obligo a los tres replicadores a llamar a QCA::pof()
  # a mano: contrastar contra un articulo es evaluar SU expresion sobre TUS
  # membresias, y el motor solo sabia minimizar su propia tabla.
  d <- lipset()

  obs <- ajuste_de_expresion("DEV*URB + ~LIT", "SURV", d)

  # Fuente independiente: QCA, llamado aqui directamente.
  esperado <- QCA::pof("DEV*URB + ~LIT", "SURV", d,
                       relation = "sufficiency")$incl.cov

  expect_identical(obs$configuraciones$configuracion, c("DEV*URB", "~LIT"))
  expect_equal(obs$configuraciones$consistencia,
               as.numeric(esperado[c("DEV*URB", "~LIT"), "inclS"]),
               tolerance = 1e-9)
  expect_equal(obs$ajuste$consistencia,
               as.numeric(esperado["expression", "inclS"]), tolerance = 1e-9)
  expect_equal(obs$ajuste$cobertura,
               as.numeric(esperado["expression", "covS"]), tolerance = 1e-9)
})

test_that("ajuste_de_expresion evalua tambien el resultado NEGADO", {
  # La mitad de los analisis de QCA estudian la ausencia del resultado, y esta
  # es la unica via publica para contrastar una expresion publicada contra esa
  # mitad. Exigir el nombre desnudo dejaba fuera, por ejemplo, la Tabla 4 de
  # E012 y obligaba a salirse a QCA::pof().
  d <- lipset()

  obs <- ajuste_de_expresion("DEV*URB", "~SURV", d)

  # Fuente independiente, con el literal: QCA::pof evalua `outcome` de forma
  # NO ESTANDAR, asi que con el literal niega y con una variable no. Ese es el
  # motivo de que la funcion llame por do.call; si alguien lo revierte, este
  # valor deja de coincidir y la prueba se pone roja.
  esperado <- QCA::pof("DEV*URB", "~SURV", d, relation = "sufficiency")$incl.cov

  expect_equal(obs$ajuste$consistencia,
               as.numeric(esperado[1L, "inclS"]), tolerance = 1e-9)
  expect_equal(obs$ajuste$cobertura,
               as.numeric(esperado[1L, "covS"]), tolerance = 1e-9)

  # La pareja de casos opuestos: negar el resultado NO puede dar lo mismo que
  # no negarlo. Sin esto, una funcion que ignorara el ~ pasaria la mitad de
  # arriba por casualidad.
  sin_negar <- ajuste_de_expresion("DEV*URB", "SURV", d)
  expect_false(isTRUE(all.equal(obs$ajuste$consistencia,
                                sin_negar$ajuste$consistencia)))

  # Y un resultado que no existe sigue abortando, con ~ o sin el.
  expect_error(ajuste_de_expresion("DEV*URB", "~NO_EXISTE", d),
               "no esta en las membresias")
})

test_that("el ajuste de la expresion tiene las mismas columnas que el del paso 6", {
  # Existe para poner las dos tablas una al lado de la otra: la del
  # articulo y la que sale del motor.
  d <- lipset()

  obs <- ajuste_de_expresion("DEV*URB + ~LIT", "SURV", d)

  expect_named(obs$configuraciones,
               c("configuracion", "consistencia", "pri", "cobertura_bruta",
                 "cobertura_unica"))
  expect_named(obs$ajuste, c("consistencia", "pri", "cobertura"))
})

test_that("una expresion de un solo termino no deja el ajuste global en NA", {
  # QCA no anade la fila "expression" cuando hay un termino: la expresion
  # ES el termino, y un hueco donde el valor es conocido se lee como dato
  # que falta.
  d <- lipset()

  obs <- ajuste_de_expresion("DEV*URB", "SURV", d)

  expect_identical(nrow(obs$configuraciones), 1L)
  expect_false(is.na(obs$ajuste$consistencia))
  expect_equal(obs$ajuste$consistencia, obs$configuraciones$consistencia[1])
})

test_that("ajuste_de_expresion tambien evalua necesidad", {
  d <- lipset()

  obs <- ajuste_de_expresion("DEV + URB", "SURV", d, relacion = "necessity")
  esperado <- QCA::pof("DEV + URB", "SURV", d,
                       relation = "necessity")$incl.cov

  expect_identical(obs$relacion, "necessity")
  expect_equal(obs$ajuste$consistencia,
               as.numeric(esperado["expression", "inclN"]), tolerance = 1e-9)
})

test_that("la suficiencia y la necesidad de la misma expresion NO coinciden", {
  # La pareja de casos opuestos: si `relacion` se ignorara, las dos
  # llamadas darian el mismo numero y la prueba anterior pasaria igual.
  d <- lipset()

  suf <- ajuste_de_expresion("DEV + URB", "SURV", d)
  nec <- ajuste_de_expresion("DEV + URB", "SURV", d, relacion = "necessity")

  expect_false(isTRUE(all.equal(suf$ajuste$consistencia,
                                nec$ajuste$consistencia)))
})

test_that("una expresion que QCA no puede evaluar se explica en castellano", {
  d <- lipset()

  expect_error(ajuste_de_expresion("NOEXISTE*OTRA", "SURV", d), "columna")
  expect_error(ajuste_de_expresion("", "SURV", d), "notacion de QCA")
  expect_error(ajuste_de_expresion("DEV", "NOESTA", d), "no esta")
})

# --- 3.3 El techo de la solucion intermedia ---------------------------

test_that("los remanentes se cuentan sobre la tabla de verdad", {
  d <- lipset()
  tt <- construir_tabla_verdad(d, "SURV", CONDS_REPLICA,
                               consistencia = 0.8, frecuencia = 1, pri = 0.7)

  # 5 condiciones = 32 filas; Lipset difuso ocupa 9 configuraciones.
  expect_identical(nrow(tt$tt), 32L)
  expect_identical(sum(tt$tt$OUT != "?"), 9L)
  expect_identical(remanentes_de(tt), 23L)
  expect_identical(remanentes_de("no es una tabla"), NA_integer_)
})

test_that("el techo se prueba moviendo el UMBRAL, no el dato", {
  # 1.014 remanentes es lo medido en E014, donde minimize() con dir.exp no
  # retorno en 30 minutos; 31 es lo medido con 6 condiciones, donde sale en
  # segundos.
  expect_true(intermedia_inabordable(1014))
  expect_false(intermedia_inabordable(31))
  expect_false(intermedia_inabordable(1014, maximo = Inf))
  expect_true(intermedia_inabordable(32, maximo = 31))
  expect_false(intermedia_inabordable(31, maximo = 31))
  expect_false(intermedia_inabordable(NA_integer_))
})

test_that("por encima del techo la intermedia se omite y se avisa antes", {
  # Sin esto el investigador se queda colgado sin saber por que: el coste
  # esta dentro de QCA::minimize() y no hay nada que arreglar ahi, pero
  # diagnosticar_suficiencia() existe justo para que no le pase.
  d <- lipset()
  tt <- construir_tabla_verdad(d, "SURV", CONDS_REPLICA,
                               consistencia = 0.8, frecuencia = 1, pri = 0.7)

  expect_warning(
    res <- diagnosticar_suficiencia(tt, expectativas = "DEV + URB + LIT",
                                    max_remanentes = 5),
    "intermedia")

  expect_true(res$intermedia_omitida)
  expect_null(res$soluciones$intermedia)
  # Y las otras dos SI se entregan: el aviso ofrece seguir, no aborta.
  expect_false(is.null(res$soluciones$conservadora))
  expect_false(is.null(res$soluciones$parsimoniosa))
  expect_identical(res$remanentes, 23L)
})

test_that("por debajo del techo la intermedia se calcula como siempre", {
  # El otro lado de la pareja: un techo que omitiera siempre pasaria la
  # prueba anterior.
  d <- lipset()
  tt <- construir_tabla_verdad(d, "SURV", CONDS_REPLICA,
                               consistencia = 0.8, frecuencia = 1, pri = 0.7)

  res <- diagnosticar_suficiencia(tt, expectativas = "DEV + URB + LIT")

  expect_false(res$intermedia_omitida)
  expect_false(is.null(res$soluciones$intermedia))
})

test_that("sin expectativas el techo no interviene", {
  # No hay intermedia que omitir, asi que no hay nada que avisar.
  d <- lipset()
  tt <- construir_tabla_verdad(d, "SURV", CONDS_REPLICA,
                               consistencia = 0.8, frecuencia = 1, pri = 0.7)

  expect_no_warning(diagnosticar_suficiencia(tt, max_remanentes = 1))
})

# --- 3.4 Los casos salen NOMBRADOS -------------------------------------

test_that("las membresias llevan el identificador tambien en los rownames", {
  # QCA::truthTable(show.cases = TRUE) lee los ROWNAMES. Con los de
  # fabrica, la columna `casos` de la solucion salia "41; 22,44,50; ..." en
  # vez de "Israel; Czech Republic, Japan, Malta; ...", que es lo primero
  # que verifica un evaluador contra el articulo.
  d <- utils::read.csv(testthat::test_path("datos",
                                           "e012-covid-80-paises.csv"),
                       stringsAsFactors = FALSE)
  continuas <- c("DELAY", "ELDERLY", "DENSITY", "INCOME", "YLL")
  anclas <- lapply(continuas, function(cond) {
    q <- stats::quantile(d[[cond]], c(0.05, 0.50, 0.95), na.rm = TRUE)
    definir_anclas(nula = unname(q[1]), cruce = unname(q[2]),
                   plena = unname(q[3]), fuente = "distribucion muestral",
                   justificacion = paste("Percentiles 95 / 50 / 5 de", cond,
                                         "declarados en el estudio E012."))
  })
  names(anclas) <- continuas
  anclas$EXP <- definir_anclas_crisp(
    "conocimiento sustantivo",
    paste("Experiencia epidemica previa, publicada ya dicotomizada por el",
          "estudio E012."))

  cal <- diagnosticar_calibracion(d, anclas, "pais")

  expect_identical(rownames(cal$membresias), d$pais)

  tt <- construir_tabla_verdad(cal$membresias, "YLL",
                               c("DELAY", "EXP", "ELDERLY", "DENSITY",
                                 "INCOME"),
                               consistencia = 0.80, frecuencia = 1, pri = 0)
  casos <- leer_tabla_verdad(tt)$cases

  # Nombres de pais, no numeros de fila.
  expect_true(any(grepl("Israel", casos, fixed = TRUE)))
  expect_false(all(grepl("^[0-9, ]*$", casos)))
})

test_that("con identificadores repetidos no se rompe el paso 4", {
  # R exige rownames unicos. Un fichero con el id repetido tiene un
  # problema anterior a este, y abortar el paso 4 aqui lo escondería.
  j <- paste("Anclas declaradas para la prueba de identificadores",
             "repetidos del paso 4.")
  anclas <- list(CAP = definir_anclas(4, 3, 2, "teoria", j),
                 INN = definir_anclas(4, 3, 2, "teoria", j))
  crudo <- data.frame(id = c("a", "a", "b"), CAP = c(1, 4, 5),
                      INN = c(2, 4, 5), stringsAsFactors = FALSE)

  cal <- diagnosticar_calibracion(crudo, anclas, "id")

  expect_identical(cal$membresias$id, c("a", "a", "b"))
  expect_identical(nrow(cal$membresias), 3L)
})

# --- 3.5 Una binaria calibrada como difusa ----------------------------

test_that("calibrar una columna 0/1 como difusa se niega y remite a la crisp", {
  # Es la llamada que uno escribe por instinto para una dicotomica, y pasa
  # las tres validaciones de definir_anclas() porque 1 / 0,5 / 0 es
  # monotona. Lo que devolvia era 0,05 y 0,95, que no es la pertenencia
  # publicada.
  j <- paste("Anclas de instinto para una condicion dicotomica,",
             "declaradas para la prueba.")
  difusas <- definir_anclas(1, 0.5, 0, "conocimiento sustantivo", j)

  expect_error(calibrar(c(0, 1, 0, 1), difusas), "definir_anclas_crisp")
})

test_that("la crisp devuelve la pertenencia publicada y la difusa devolvia otra", {
  # La cifra del encargo: 0,05 y 0,95 donde el estudio publica 0 y 1.
  j <- paste("Anclas de instinto para una condicion dicotomica,",
             "declaradas para la prueba.")
  crisp <- definir_anclas_crisp("conocimiento sustantivo", j)

  expect_identical(calibrar(c(0, 1, 0, 1), crisp), c(0, 1, 0, 1))
})

test_that("una columna que no es 0/1 se sigue calibrando con 1 / 0,5 / 0", {
  # El caso opuesto. Esas tres anclas son legitimas para una proporcion que
  # no sea dicotomica, y negarlas por su valor -- y no por el dato --
  # cerraria la puerta a la mitad de los estudios.
  j <- paste("Anclas de una proporcion continua en [0, 1], declaradas",
             "para la prueba.")
  a <- definir_anclas(1, 0.5, 0, "conocimiento sustantivo", j)

  obs <- calibrar(c(0.1, 0.4, 0.5, 0.9), a)

  expect_length(obs, 4L)
  expect_false(anyNA(obs))
})

test_that("una columna de un solo valor no se confunde con una dicotomica", {
  # es_columna_binaria() exige que aparezcan LOS DOS valores: una columna
  # de unos cumple el vocabulario 0/1 y no separa ningun caso.
  j <- paste("Anclas de una proporcion continua en [0, 1], declaradas",
             "para la prueba.")
  a <- definir_anclas(1, 0.5, 0, "conocimiento sustantivo", j)

  expect_no_error(calibrar(c(1, 1, 1, 1), a))
})
