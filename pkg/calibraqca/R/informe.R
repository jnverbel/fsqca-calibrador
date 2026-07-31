# Reune todo lo que el informe necesita, en un solo sitio.
#
# Por que vive en el motor y no en el documento: hay DOS presentadores --
# el .qmd de Quarto (que produce HTML y Word) y la vista previa dentro de
# la aplicacion, que no puede usar Quarto porque el equipo del
# investigador no lo tiene. Si cada uno calculara lo suyo, acabarian
# diciendo cosas distintas del mismo analisis. Aqui se calcula una vez.
#
# Esta funcion NO da formato: no sabe de HTML, de tablas ni de negritas.
# Devuelve datos.

PAQUETES_INFORME <- c("QCA", "SetMethods", "psych", "multilevel", "lavaan",
                      "NCA")

#' Reune las once secciones del informe.
reunir_informe <- function(datos, mapeo, anclas, bitacora, umbrales,
                           resultado, leido = NULL,
                           idm = IDM_POR_DEFECTO, robustez = NULL) {
  condiciones <- setdiff(names(anclas), resultado)

  validacion <- diagnosticar_validacion(datos, mapeo)
  agregacion <- diagnosticar_agregacion(datos, mapeo)
  calibracion <- diagnosticar_calibracion(agregacion$casos, anclas,
                                          mapeo$columna_id, idm = idm)
  membresias <- calibracion$membresias
  semaforo <- diagnosticar_semaforo(membresias, mapeo$columna_id,
                                    isTRUE(mapeo$resultado_mismo_cuestionario))
  necesidad <- analizar_necesidad(membresias, resultado, condiciones)
  tt <- construir_tabla_verdad(membresias, resultado, condiciones,
                               consistencia = umbrales$consistencia,
                               pri = umbrales$pri,
                               frecuencia = umbrales$frecuencia)
  suficiencia <- diagnosticar_suficiencia(tt)

  catalogo <- catalogo_alertas()
  alertas <- bitacora
  if (nrow(alertas) > 0) {
    alertas$titulo <- catalogo$titulo[match(alertas$codigo, catalogo$codigo)]
    alertas <- alertas[order(match(alertas$severidad,
                                   c("bloqueante", "advertencia",
                                     "informativa"))), , drop = FALSE]
    rownames(alertas) <- NULL
  } else {
    alertas$titulo <- character(0)
  }

  versiones <- vapply(PAQUETES_INFORME, function(p)
    tryCatch(as.character(utils::packageVersion(p)),
             error = function(e) "no instalado"), character(1))

  list(
    ficha = list(
      r_version = R.version.string,
      archivo = if (is.null(leido)) NA_character_ else leido$nombre_archivo,
      huella = if (is.null(leido)) NA_character_ else leido$huella_sha256,
      casos = nrow(agregacion$casos),
      idm = idm,
      paquetes = versiones),

    mapeo = data.frame(
      constructo = vapply(mapeo$constructos, function(x) x$nombre, character(1)),
      rol = vapply(mapeo$constructos, function(x) x$rol, character(1)),
      items = vapply(mapeo$constructos,
                     function(x) paste(x$items, collapse = ", "), character(1)),
      n_items = vapply(mapeo$constructos, function(x) length(x$items),
                       integer(1)),
      stringsAsFactors = FALSE),

    validacion = list(resultados = validacion$resultados, cfa = validacion$cfa),

    agregacion = data.frame(
      constructo = condiciones,
      minimo = vapply(condiciones, function(c)
        min(agregacion$casos[[c]], na.rm = TRUE), numeric(1)),
      mediana = vapply(condiciones, function(c)
        stats::median(agregacion$casos[[c]], na.rm = TRUE), numeric(1)),
      maximo = vapply(condiciones, function(c)
        max(agregacion$casos[[c]], na.rm = TRUE), numeric(1)),
      sin_dato = vapply(condiciones, function(c)
        sum(is.na(agregacion$casos[[c]])), integer(1)),
      stringsAsFactors = FALSE, row.names = NULL),

    calibracion = list(tabla = tabla_calibracion(anclas, idm = idm),
                       membresias = membresias,
                       resumen = semaforo$resumen),

    alertas = alertas,
    necesidad = necesidad,
    tabla_verdad = leer_tabla_verdad(tt),
    umbrales = umbrales,
    soluciones = suficiencia$soluciones,

    robustez = if (is.null(robustez)) {
      list(ejecutado = FALSE, obligatorio = calibracion$obliga_robustez,
           escenarios = list(), rangos = data.frame())
    } else {
      utils::modifyList(robustez,
                        list(obligatorio = calibracion$obliga_robustez))
    },

    declaraciones = list(
      casos_050 = as.character(unlist(calibracion$correccion)),
      correccion = CORRECCION_050,
      rho = vapply(calibracion$orden, function(o) o$rho, numeric(1)),
      sesgo_metodo_comun = isTRUE(mapeo$resultado_mismo_cuestionario))
  )
}
