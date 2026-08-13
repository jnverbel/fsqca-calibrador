leer <- function(ruta) {
  utils::read.csv(ruta, check.names = FALSE, stringsAsFactors = FALSE)
}

falla <- function(expr) {
  inherits(tryCatch(force(expr), error = identity), "error")
}

criterios_a <- c(
  "datos_brutos", "constructos_reconstruibles", "anclas_reconstruibles",
  "umbrales_reconstruibles", "resultado_comparable", "licencia_compatible"
)
criterios_b <- setdiff(criterios_a, "constructos_reconstruibles")
modulos <- c(
  "mod_calibracion", "mod_necesidad", "mod_tabla_verdad",
  "mod_minimizacion", "mod_ajuste", "mod_robustez"
)

validar_niveles <- function(estudios) {
  stopifnot(all(estudios$decision %in% c("incluir", "excluir")))
  incluidos <- estudios[estudios$decision == "incluir", , drop = FALSE]
  nivel_a <- incluidos[incluidos$nivel == "A", , drop = FALSE]
  nivel_b <- incluidos[incluidos$nivel == "B", , drop = FALSE]

  stopifnot(nrow(incluidos) == nrow(nivel_a) + nrow(nivel_b))
  stopifnot(all(estudios$nivel[estudios$decision == "excluir"] == "ninguno"))
  stopifnot(all(unlist(incluidos[criterios_b], use.names = FALSE) == "si"))

  if (nrow(nivel_a)) {
    stopifnot(all(nivel_a$tipo_datos %in% c("likert", "multiitem")))
    stopifnot(all(unlist(nivel_a[criterios_a], use.names = FALSE) == "si"))
    stopifnot(all(nivel_a$mod_calibracion == "si"))
    stopifnot(all(nivel_a$mod_tabla_verdad == "si"))
    stopifnot(all(nivel_a$mod_minimizacion == "si"))
  }

  if (nrow(nivel_b)) {
    stopifnot(all(unlist(nivel_b[criterios_b], use.names = FALSE) == "si"))
    stopifnot(all(unlist(nivel_b[modulos], use.names = FALSE) %in%
                  c("si", "no", "no_evaluable")))
    stopifnot(all(rowSums(nivel_b[modulos] == "si") >= 1L))
  }

  invisible(list(a = nivel_a, b = nivel_b))
}

validar_trazabilidad_texto_completo <- function(estudios, cribado) {
  pos_estudio <- match(cribado$doi_estudio, estudios$doi)
  reabiertos <- cribado[
    cribado$decision == "duplicado" &
      cribado$etapa == "texto_completo" &
      !is.na(pos_estudio) &
      cribado$ronda == estudios$ronda_inclusion[pos_estudio],
    , drop = FALSE
  ]
  completos <- cribado[cribado$decision == "evaluacion_completa", , drop = FALSE]
  evidencia <- rbind(completos, reabiertos)
  posicion <- match(evidencia$doi_estudio, estudios$doi)

  stopifnot(nrow(evidencia) == nrow(estudios))
  stopifnot(!anyDuplicated(evidencia$id_estudio_canonico))
  stopifnot(!anyNA(posicion))
  stopifnot(identical(evidencia$id_estudio_canonico,
                      estudios$id_estudio_canonico[posicion]))
  stopifnot(identical(as.integer(evidencia$ronda),
                      as.integer(estudios$ronda_inclusion[posicion])))
  stopifnot(identical(evidencia$nivel_candidato, estudios$nivel[posicion]))
  invisible(evidencia)
}

estudios <- leer("docs/validacion/estudios.csv")
cribado <- leer("docs/validacion/cribado-estudios.csv")
rondas <- leer("docs/validacion/rondas-busqueda.csv")
niveles <- validar_niveles(estudios)
evidencia <- validar_trazabilidad_texto_completo(estudios, cribado)

# Congelación explícita: los B cuentan como cobertura modular, no como A.
stopifnot(nrow(estudios) == 28L)
stopifnot(nrow(niveles$a) == 0L, nrow(niveles$b) == 9L)
stopifnot(sum(estudios$decision == "excluir") == 19L)
stopifnot(all(estudios$decision %in% c("incluir", "excluir")))
stopifnot(identical(as.integer(rondas$nivel_a_nuevos),
                    vapply(rondas$ronda, function(ronda) {
                      sum(estudios$ronda_inclusion == ronda &
                            estudios$decision == "incluir" &
                            estudios$nivel == "A")
                    }, integer(1))))
stopifnot(identical(as.integer(rondas$nivel_b_nuevos),
                    vapply(rondas$ronda, function(ronda) {
                      sum(estudios$ronda_inclusion == ronda &
                            estudios$decision == "incluir" &
                            estudios$nivel == "B")
                    }, integer(1))))

# La congelación no admite estados pendientes: no pueden ocultarse al filtrar
# los incluidos ni posponerse después de que la selección quedó saturada.
pendiente <- estudios
pendiente$decision[1L] <- "pendiente"
stopifnot(falla(validar_niveles(pendiente)))

# Cada B falla si se cambia únicamente su etiqueta a A. Esto cubre tanto los
# límites de tipo/constructo como los módulos A obligatorios.
for (id_b in niveles$b$id) {
  b_reetiquetado <- niveles$b[niveles$b$id == id_b, , drop = FALSE]
  stopifnot(nrow(b_reetiquetado) == 1L)
  b_reetiquetado$nivel <- "A"
  stopifnot(falla(validar_niveles(b_reetiquetado)))
}

# La matriz `id × mod_*` de los incluidos es tan parte de la congelación como el
# recuento 0/9/19, y hasta aquí no tenía guardián: apagar `E014 mod_ajuste` de
# `si` a `no_evaluable` dejaba las cinco pruebas en verde. `validar_niveles()`
# sólo exige que cada B tenga AL MENOS un módulo en `si`, así que las 44 celdas
# `si` podían encogerse hasta 9 sin que nada chillara. Se congela igual que las
# atribuciones por ronda: una firma SHA-256 sobre el volcado ordenado.
firma_matriz_modulos <- function(estudios) {
  inc <- estudios[estudios$decision == "incluir", , drop = FALSE]
  m <- inc[order(inc$id), c("id", modulos), drop = FALSE]
  archivo <- tempfile("matriz-modulos-", fileext = ".tsv")
  on.exit(unlink(archivo), add = TRUE)
  utils::write.table(
    m, file = archivo, sep = "\t", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "NA", qmethod = "double", fileEncoding = "UTF-8",
    eol = "\n"
  )
  unname(tools::sha256sum(archivo))
}

FIRMA_MATRIZ_MODULOS <-
  "b1430917907bd10f0baee655114621404a9dac07dc6f405bd2bb6f893b1f7d78"
stopifnot(identical(firma_matriz_modulos(estudios), FIRMA_MATRIZ_MODULOS))
stopifnot(sum(niveles$b[modulos] == "si") == 44L)

# Mutación en las dos direcciones: apagar CUALQUIER celda `si` de CUALQUIER
# incluido tiene que mover la firma. Se recorren las 44, no una de muestra.
for (id_incluido in niveles$b$id) {
  for (m in modulos) {
    if (!identical(estudios[[m]][estudios$id == id_incluido], "si")) next
    apagada <- estudios
    apagada[[m]][apagada$id == id_incluido] <- "no_evaluable"
    stopifnot(!identical(firma_matriz_modulos(apagada), FIRMA_MATRIZ_MODULOS))
  }
}

# El artefacto de auditoría es parte de la congelación de las evaluaciones.
stopifnot(file.exists("docs/validacion/busqueda-ampliada.md"))

cat(sprintf(paste0(
  "seleccion ampliada valida: %d texto completo; %d A; %d B; ",
  "matriz de modulos congelada en %d celdas `si` con firma %s\n"
), nrow(evidencia), nrow(niveles$a), nrow(niveles$b),
   sum(niveles$b[modulos] == "si"), substr(FIRMA_MATRIZ_MODULOS, 1L, 12L)))
