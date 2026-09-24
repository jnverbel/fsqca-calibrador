# Nombres de condicion y de resultado que no van en mayusculas.
#
# QCA 3.25 respeta como se escribio cada nombre: la solucion sale
# "Dev*Urb", no "DEV*URB". SetMethods, en cambio, pasa el resultado a
# mayusculas antes de buscarlo, y el motor comparaba en mayusculas contra
# nombres que no lo estaban. Nada obliga al investigador a escribir en
# mayusculas, y en los tres sitios el fallo era silencioso: cero casos, un
# ajuste NA, una alerta que no salta.

lf_minusculas <- function() {
  data("LF", package = "QCA", envir = environment())
  d <- LF
  names(d) <- c("Dev", "Urb", "Lit", "Ind", "Stb", "Surv")
  d
}

minimizar_lf <- function(d, resultado, consistencia = 0.8) {
  tt <- QCA::truthTable(d, outcome = resultado,
                        conditions = setdiff(names(d), resultado),
                        incl.cut = consistencia, n.cut = 1)
  QCA::minimize(tt, details = TRUE)
}

test_that("el estatus de los casos no depende de las mayusculas del resultado", {
  data("LF", package = "QCA", envir = environment())
  mayus <- estatus_de_casos(minimizar_lf(LF, "SURV"), "SURV")
  minus <- estatus_de_casos(minimizar_lf(lf_minusculas(), "Surv"), "Surv")

  # Sin la correccion, "Surv" daba cero filas y el paso 7 no reportaba
  # ningun cambio de estatus.
  expect_identical(nrow(mayus), 18L)
  expect_identical(minus$estatus, mayus$estatus)
})

test_that("rob.fit mide el ajuste con un resultado en minusculas", {
  d <- lf_minusculas()
  inicial <- .resultado_para_setmethods(minimizar_lf(d, "Surv"), "Surv")
  prueba <- .resultado_para_setmethods(minimizar_lf(d, "Surv", 0.75), "Surv")

  ajuste <- SetMethods::rob.fit(test_sol = prueba, initial_sol = inicial,
                                outcome = "Surv")
  expect_false(anyNA(as.numeric(ajuste)))
})

test_that("un resultado y una condicion que solo difieren en mayusculas se rechazan", {
  d <- lf_minusculas()
  d$SURV <- d$Dev
  sol <- minimizar_lf(d[, c("Dev", "Urb", "Lit", "SURV", "Surv")], "Surv")
  expect_error(estatus_de_casos(sol, "Surv"), "solo se distinguen")
})

test_that("A-33 salta con condiciones que no van en mayusculas", {
  semaforo <- list(resumen = data.frame(
    condicion = c("Dev", "Urb"), pct_sobre_050 = c(95, 50),
    stringsAsFactors = FALSE))
  soluciones <- list(conservadora = list(terminos = c("Dev*~Urb", "Dev*Lit")))

  a <- alertas_solucion_degenerada(soluciones, semaforo)

  expect_identical(a$codigo, "A-33")
  # El detalle nombra la condicion como la escribio el investigador.
  expect_match(a$detalle, "incluye Dev", fixed = TRUE)
  expect_false(grepl("Urb", a$detalle, fixed = TRUE))
})
