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
stopifnot(nrow(niveles$a) == 0L, nrow(niveles$b) == 9L)
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

# E025 satisface los criterios comunes y es Likert, pero no publica una
# minimización reproducible; cambiar sólo la etiqueta no puede contarlo como A.
b_reetiquetado <- niveles$b[niveles$b$id == "E025", , drop = FALSE]
stopifnot(nrow(b_reetiquetado) == 1L)
b_reetiquetado$nivel <- "A"
stopifnot(falla(validar_niveles(b_reetiquetado)))

# El artefacto de auditoría es parte de la congelación de las evaluaciones.
stopifnot(file.exists("docs/validacion/busqueda-ampliada.md"))

cat(sprintf("seleccion ampliada valida: %d texto completo; %d A; %d B\n",
            nrow(evidencia), nrow(niveles$a), nrow(niveles$b)))
