# Las dos piezas nuevas, conducidas en la aplicacion de verdad, sobre un
# estudio publicado.
#
# E012 (80 paises, mortalidad por COVID-19 en anos de vida perdidos) las
# ejercita a la vez: EXP -- experiencia epidemica previa -- es una condicion
# CRISP, y la solucion que sus autores publican es la INTERMEDIA, que solo
# existe si se declaran expectativas direccionales.
#
# El motor ya lo reproducia llamandolo a mano desde una prueba. Lo que aqui
# se comprueba es lo otro: que el investigador puede LLEGAR a esas dos
# cosas desde la pantalla, que es justo lo que no podia hacer.
#
# El fichero es el mismo que usa la replicacion del motor, y sus valores se
# contrastaron uno a uno contra la tabla S1 del articulo.

library(shinytest2)

DATOS_E012 <- desde_raiz("pkg", "calibraqca", "tests", "testthat", "datos",
                         "e012-covid-80-paises.csv")

# La solucion intermedia publicada, termino a termino (Tablas 3 y 4).
E012_INTERMEDIA <- c("~EXP*ELDERLY*DENSITY", "DELAY*EXP*INCOME",
                     "DENSITY*INCOME", "EXP*~ELDERLY*INCOME")

# Las condiciones cuya presencia espera la teoria del estudio.
E012_PRESENTES <- c("DELAY", "EXP", "ELDERLY")

# Justificaciones distintas de verdad, una por condicion: un mismo parrafo
# repetido dispara A-34, que es exactamente lo que A-34 existe para cazar.
JUSTIFICAR_ANCLA <- c(
  DELAY = paste("El retraso se mide en dias desde el primer caso hasta el",
                "cierre; las anclas son los percentiles 95 / 50 / 5 que",
                "declara el estudio replicado."),
  ELDERLY = paste("La proporcion de mayores de 65 anos se calibra por",
                  "percentiles 95 / 50 / 5, como en el articulo original,",
                  "por no haber umbral demografico establecido."),
  DENSITY = paste("La densidad de poblacion por kilometro cuadrado se",
                  "calibra sobre la distribucion de los 80 paises, tal como",
                  "hicieron los autores del estudio."),
  INCOME = paste("La renta nacional por habitante en dolares corrientes se",
                 "calibra por percentiles, que es el criterio comparativo",
                 "entre paises que usa la fuente."),
  YLL = paste("La tasa de anos de vida perdidos es el resultado, y sus",
              "anclas son los percentiles 95 / 50 / 5 de la muestra de 80",
              "paises del articulo."),
  EXP = paste("Experiencia epidemica previa: el estudio la publica ya",
              "dicotomizada, 1 si el pais afronto una epidemia anterior y 0",
              "si no. No hay nada que calibrar."))

JUSTIFICAR_EXPECTATIVA <- c(
  DELAY = paste("La literatura de respuesta a epidemias sostiene que",
                "retrasar el cierre agrava la mortalidad posterior."),
  EXP = paste("Los autores esperan que haber afrontado una epidemia previa",
              "contribuya al resultado por la via de la preparacion",
              "institucional."),
  ELDERLY = paste("La letalidad de la COVID-19 crece con la edad, de modo",
                  "que se espera que una poblacion envejecida contribuya a",
                  "los anos de vida perdidos."))

#' Deja la aplicacion en el paso 6 de E012, con las anclas ya confirmadas.
preparar_e012 <- function(app) {
  app$upload_file(archivo = DATOS_E012)
  app$wait_for_idle(timeout = 30 * 1000)
  app$click("confirmar_mapeo")
  app$wait_for_idle(timeout = 60 * 1000)

  avanzar_hasta(app, 4)

  for (cond in names(JUSTIFICAR_ANCLA)) {
    teclear(app, paste0("just_", cond), JUSTIFICAR_ANCLA[[cond]])
  }
  app$click("confirmar_calibracion")
  app$wait_for_idle(timeout = 120 * 1000)

  avanzar_hasta(app, 6)
  invisible(app)
}

#' Declara las expectativas y los umbrales del articulo, y minimiza.
minimizar_como_el_articulo <- function(app) {
  for (cond in E012_PRESENTES) {
    fijar_input(app, paste0("exp_", cond), "presente")
    teclear(app, paste0("just_exp_", cond), JUSTIFICAR_EXPECTATIVA[[cond]])
  }
  # Los del articulo: consistencia 0,80, frecuencia 1, PRI 0.
  app$set_inputs(umbral_consistencia = 0.80, umbral_frecuencia = 1,
                 umbral_pri = 0)
  app$click("correr_analisis")
  app$wait_for_idle(timeout = 180 * 1000)
  invisible(app)
}

#' El ajuste de una solucion, leido de la pantalla.
ajuste_en_pantalla <- function(app, solucion) {
  bruto <- app$get_js(sprintf(
    "Array.from(document.querySelectorAll('#panel_paso [data-solucion=%s] p'))
       .map(function(p){return p.textContent}).join(' ')", solucion))
  cifras <- as.numeric(regmatches(
    bruto, gregexpr("[0-9]+\\.[0-9]+", bruto))[[1]])
  if (length(cifras) < 3) {
    stop("No se pudo leer el ajuste de la solucion ", solucion, ": ", bruto)
  }
  list(consistencia = cifras[1], pri = cifras[2], cobertura = cifras[3])
}

#' Los terminos de una solucion, tal como los lee el investigador.
terminos_en_pantalla <- function(app, solucion) {
  bruto <- app$get_js(sprintf(
    "String(document.querySelector('#panel_paso [data-solucion=%s] .terminos')
              && document.querySelector('#panel_paso [data-solucion=%s] .terminos')
                   .textContent)", solucion, solucion))
  trimws(strsplit(bruto, "+", fixed = TRUE)[[1]])
}

# --- Pieza 2: la condicion binaria ------------------------------------

test_that("el paso 1 propone la columna 0/1 como condicion binaria", {
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)

  app$upload_file(archivo = DATOS_E012)
  app$wait_for_idle(timeout = 30 * 1000)

  # Lo que vale el desplegable, que es lo que viajara al motor.
  expect_identical(app$get_value(input = "rol_EXP"), "condicion_binaria")
  # Y las demas NO: una propuesta que marcara todo como binario pasaria la
  # asercion de arriba sin distinguir nada.
  expect_identical(app$get_value(input = "rol_DELAY"), "condicion")
  expect_identical(app$get_value(input = "rol_YLL"), "resultado")

  # Y se dice en pantalla, en vez de aplicarse en silencio.
  panel <- texto_de(app$get_html("#panel_paso"))
  expect_match(panel, "se proponen como condicion binaria: EXP")
})

test_that("el paso 4 no le pide anclas a la condicion binaria", {
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)

  app$upload_file(archivo = DATOS_E012)
  app$wait_for_idle(timeout = 30 * 1000)
  app$click("confirmar_mapeo")
  app$wait_for_idle(timeout = 60 * 1000)
  avanzar_hasta(app, 4)

  inputs <- names(app$get_values()$input)

  # Sin deslizadores: una condicion crisp ya es la pertenencia.
  expect_false("plena_EXP" %in% inputs)
  # Pero las difusas siguen teniendo los suyos: sin esto, un paso 4 que no
  # dibujara ningun deslizador pasaria la asercion anterior.
  expect_true("plena_DELAY" %in% inputs)
  # Y la justificacion se le sigue exigiendo: dicotomizar es una decision.
  expect_true("just_EXP" %in% inputs)

  panel <- texto_de(app$get_html("#panel_paso"))
  expect_match(panel, "Condicion binaria: no se calibra")
})

# --- Pieza 1: las expectativas direccionales --------------------------

test_that("sin expectativas declaradas el paso 6 no inventa una intermedia", {
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)
  preparar_e012(app)

  panel <- texto_de(app$get_html("#panel_paso"))

  # La conservadora si esta: es lo que distingue "no se declararon
  # expectativas" de "el paso 6 no calculo nada".
  expect_gt(length(terminos_en_pantalla(app, "conservadora")), 0)
  expect_match(panel, "exige expectativas")
})

test_that("declarar una direccion sin justificarla no minimiza", {
  # La sena de identidad de la herramienta, aplicada a la decision nueva:
  # una expectativa direccional es una afirmacion teorica y sale impresa.
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)
  preparar_e012(app)

  app$set_inputs(exp_DELAY = "presente")
  app$click("correr_analisis")
  app$wait_for_idle(timeout = 60 * 1000)

  expect_match(texto_de(app$get_html(".shiny-notification")),
               "DELAY.*justificacion de al menos 30")
  expect_match(texto_de(app$get_html("#panel_paso")), "exige expectativas")
})

test_that("escribir una justificacion del paso 6 no redibuja el panel", {
  # El defecto del paso 4, que costo dos justificaciones perdidas de siete,
  # esta a un descuido de volver en el paso 6: el mismo formulario largo,
  # las mismas justificaciones, el mismo renderUI. La marca en el DOM es la
  # prueba de que NO hubo re-render: un atributo puesto a mano no sobrevive
  # a que Shiny reemplace el nodo.
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)
  preparar_paso4(app)
  for (cond in c("FUN", "AES", "PI")) {
    teclear(app, paste0("just_", cond), paste(
      "El umbral de 4 en", cond, "corresponde al punto en que la literatura",
      "sectorial situa la presencia plena del constructo."))
  }
  app$click("confirmar_calibracion")
  app$wait_for_idle(timeout = 60 * 1000)
  avanzar_hasta(app, 6)

  app$run_js("document.querySelector('#panel_paso .condicion')
                .setAttribute('data-marca','SOBREVIVE');
              window.scrollTo(0, document.body.scrollHeight);")
  app$wait_for_idle(timeout = 15 * 1000)
  scroll_antes <- app$get_js("String(Math.round(window.scrollY))")
  expect_gt(as.numeric(scroll_antes), 0)

  for (cond in c("FUN", "AES")) {
    teclear(app, paste0("just_exp_", cond), paste(
      "La teoria espera que", cond, "contribuya al resultado por la via que",
      "describe la literatura sectorial del constructo."))
  }

  expect_identical(
    app$get_js("String(document.querySelector('#panel_paso .condicion') &&
                document.querySelector('#panel_paso .condicion')
                  .getAttribute('data-marca'))"),
    "SOBREVIVE")
  expect_identical(app$get_js("String(Math.round(window.scrollY))"),
                   scroll_antes)
  expect_identical(
    app$get_js("Array.from(document.querySelectorAll('#panel_paso textarea'))
                .filter(function(t){return t.value.length > 30}).length"),
    2L)
})

# --- El criterio de aceptacion ----------------------------------------

test_that("E012 recorrido en la aplicacion llega a la intermedia publicada", {
  # ESTA es la prueba. Del archivo de los 80 paises a la solucion que
  # publican sus autores, sin llamar al motor a mano ni una sola vez: el
  # investigador declara la condicion binaria en el paso 1, las anclas en
  # el 4 y las expectativas y los umbrales en el 6.
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)
  preparar_e012(app)
  minimizar_como_el_articulo(app)

  expect_setequal(terminos_en_pantalla(app, "intermedia"), E012_INTERMEDIA)

  # Las tres, no solo la que se reporta: presentar una sola es una de las
  # observaciones habituales de los evaluadores.
  expect_gt(length(terminos_en_pantalla(app, "conservadora")), 0)
  expect_gt(length(terminos_en_pantalla(app, "parsimoniosa")), 0)

  # El ajuste publicado es 0,79 / 0,63. Se comprueba redondeado a dos
  # decimales y no a tres a proposito: las anclas que confirma el
  # investigador son las del deslizador, es decir, los percentiles
  # redondeados a su paso, y eso mueve el tercer decimal sin mover ningun
  # termino. Exigir el tercero seria atar la prueba al paso del control.
  ajuste <- ajuste_en_pantalla(app, "intermedia")
  expect_equal(round(ajuste$consistencia, 2), 0.79)
  expect_equal(round(ajuste$cobertura, 2), 0.63)
})

test_that("el informe de E012 declara la intermedia y la condicion binaria", {
  app <- abrir_app()
  on.exit(app$stop(), add = TRUE)
  preparar_e012(app)
  minimizar_como_el_articulo(app)

  avanzar_hasta(app, 8)

  informe <- texto_de(app$get_html("#vista_informe"))

  # La solucion que se reporta, entera.
  for (termino in E012_INTERMEDIA) {
    expect_match(informe, termino, fixed = TRUE,
                 info = paste("falta en el informe:", termino))
  }
  # La condicion binaria, declarada como tal: sus tres anclas no son una
  # decision de calibracion.
  expect_match(informe, "binaria, sin calibrar")
  # Y la justificacion de la expectativa, integra.
  expect_match(informe, "preparacion institucional", fixed = TRUE)
})
