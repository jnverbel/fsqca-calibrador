# Genera un archivo de proyecto de ejemplo para poder renderizar el informe
# sin datos reales del investigador.
#
#   Rscript informe/generar-ejemplo.R
#
# El proyecto que produce es el mismo que dejaria la aplicacion tras
# recorrer los ocho pasos sobre limpia.csv, incluida una alerta reconocida
# por escrito, para que el informe tenga que imprimir esa nota.

if (!dir.exists(file.path("pkg", "calibraqca"))) {
  stop("Ejecute desde la raiz del repositorio.", call. = FALSE)
}
pkgload::load_all(file.path("pkg", "calibraqca"), quiet = TRUE,
                  export_all = FALSE)

FECHA <- "2026-07-30T12:00:00Z"
ruta_datos <- file.path("pkg", "calibraqca", "tests", "testthat", "datos",
                        "limpia.csv")
leido <- leer_datos(ruta_datos)

mapeo <- definir_mapeo("id_empresa", "uno", list(
  list(nombre = "CAP_ABS", rol = "condicion", items = c("CAP01","CAP02","CAP03")),
  list(nombre = "REDES",   rol = "condicion", items = c("RED01","RED02","RED03")),
  list(nombre = "INNOV",   rol = "resultado", items = c("INN01","INN02","INN03"))))

justificaciones <- list(
  CAP_ABS = paste("El umbral de 4 corresponde al punto en que la literatura",
                  "sectorial situa la capacidad de absorcion plena (Zahra y",
                  "George, 2002), y coincide con el corte del programa",
                  "nacional de fomento a la innovacion empresarial."),
  REDES = paste("El umbral de 4 se toma de la definicion operativa de",
                "vinculacion efectiva del manual sectorial: una empresa se",
                "considera vinculada cuando sostiene al menos tres relaciones",
                "activas con actores del sistema."),
  INNOV = paste("El umbral de 4 corresponde al nivel a partir del cual la",
                "encuesta nacional clasifica a una empresa como innovadora",
                "en sentido estricto."))

anclas <- lapply(names(justificaciones), function(nom)
  definir_anclas(4, 3, 2, "teoria", justificaciones[[nom]]))
names(anclas) <- names(justificaciones)

# --- Recorrido de los ocho pasos --------------------------------------

bit <- registrar_alertas(nueva_bitacora(),
                         diagnosticar_ingesta(leido$datos, mapeo), 1)
val <- diagnosticar_validacion(leido$datos, mapeo)
bit <- registrar_alertas(bit, val$alertas, 2)
agr <- diagnosticar_agregacion(leido$datos, mapeo)
bit <- registrar_alertas(bit, agr$alertas, 3)
cal <- diagnosticar_calibracion(agr$casos, anclas, mapeo$columna_id)
bit <- registrar_alertas(bit, cal$alertas, 4)
sem <- diagnosticar_semaforo(cal$membresias, mapeo$columna_id)
bit <- registrar_alertas(bit, sem$alertas, 5)

condiciones <- c("CAP_ABS", "REDES")
nec <- diagnosticar_necesidad(cal$membresias, "INNOV", condiciones)
tt <- construir_tabla_verdad(cal$membresias, "INNOV", condiciones)
suf <- diagnosticar_suficiencia(tt)
bit <- registrar_alertas(bit, rbind(nec$alertas,
                                    alertas_tabla_verdad(leer_tabla_verdad(tt)),
                                    suf$alertas), 6)

# Se reconocen por escrito las alertas que frenan, como haria el
# investigador. El informe tiene que imprimir estas notas integras.
notas <- list(
  "A-07" = paste("La escala de resultado es corta y el constructo es",
                 "exploratorio; se reporta la limitacion en el apartado de",
                 "medida y se contrasta con el indicador objetivo de patentes."),
  "A-22" = paste("Los casos con membresias identicas corresponden a empresas",
                 "del mismo subsector y tamano; se conservan porque su",
                 "coincidencia es sustantiva y no un artefacto de la medida."),
  "A-29" = paste("La cobertura moderada era esperable: el modelo explica una",
                 "via de innovacion entre varias posibles, y no se pretende",
                 "cobertura exhaustiva del resultado."))

for (i in seq_len(nrow(bit))) {
  if (bit$estado[i] != "abierta") next
  if (bit$severidad[i] == "informativa") next
  nota <- notas[[bit$codigo[i]]]
  if (is.null(nota)) next
  bit <- cerrar_alerta(bit, bit$codigo[i], bit$contexto[i], nota = nota,
                       fecha = FECHA)
}

# --- Archivo de proyecto ----------------------------------------------

p <- nuevo_proyecto(fecha = FECHA)
p$datos$nombre_archivo <- leido$nombre_archivo
p$datos$huella_sha256 <- leido$huella_sha256
p$datos$n_filas <- leido$n_filas
p$datos$n_columnas <- leido$n_columnas
p$datos$nombres_columnas <- leido$nombres_columnas
p$mapeo <- list(
  columna_id = mapeo$columna_id,
  encuestados_por_caso = mapeo$encuestados_por_caso,
  constructos = data.frame(
    nombre = vapply(mapeo$constructos, function(x) x$nombre, character(1)),
    rol = vapply(mapeo$constructos, function(x) x$rol, character(1)),
    stringsAsFactors = FALSE))
p$mapeo$constructos$items <- lapply(mapeo$constructos, function(x) x$items)

p$calibracion$idm <- cal$idm
p$calibracion$correccion_050 <- list(aplicada = length(unlist(cal$correccion)) > 0,
                                     casos = unlist(cal$correccion))
p$calibracion$condiciones <- lapply(anclas, function(a)
  list(anclas = list(plena = a$plena, cruce = a$cruce, nula = a$nula),
       fuente = a$fuente, justificacion = a$justificacion))
p$analisis <- list(
  resultado = "INNOV",
  umbrales = list(frecuencia = umbral_frecuencia(nrow(agr$casos)),
                  consistencia = CONSISTENCIA_MINIMA, pri = PRI_MINIMO))
p$alertas <- bit
p$entorno$paquetes <- list(QCA = as.character(utils::packageVersion("QCA")))

dir.create(file.path("informe", "ejemplo"), showWarnings = FALSE,
           recursive = TRUE)
destino <- file.path("informe", "ejemplo", "proyecto.json")
guardar_proyecto(p, destino, fecha = FECHA)

cat("escrito:", destino, "\n")
cat("alertas:", nrow(bit), "· reconocidas:", sum(bit$estado == "reconocida"),
    "· abiertas:", sum(bit$estado == "abierta"), "\n")
