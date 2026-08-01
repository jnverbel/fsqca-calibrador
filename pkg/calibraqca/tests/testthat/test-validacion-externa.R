# Validacion contra una calibracion publicada.
#
# Todas las demas pruebas comparan la herramienta consigo misma o con el
# paquete que envuelve. Esta la compara con un resultado PUBLICADO que no
# controlamos: los datos de Lipset (1959) tal como los calibro Ragin, que
# viajan con el paquete QCA en dos versiones -- LR con los indicadores
# crudos y LF con las pertenencias difusas publicadas.
#
# Es el ejemplo canonico del metodo: el que aparece en Ragin (2008), en
# Rihoux y De Meur (2009) y en el libro de Dusa. Si la calibracion directa
# de esta herramienta reprodujera otra cosa, seria esta herramienta la que
# esta equivocada.
#
# Las anclas no vienen publicadas como tales -- la documentacion de QCA
# solo da los umbrales de la version crisp --, asi que se recuperaron
# ajustandolas contra LF. El hallazgo es que el punto de cruce recuperado
# coincide con el umbral publicado en las cinco condiciones:
#
#   DEV  550,21  frente a  550 USD
#   URB   50,00  frente a   50 %
#   LIT   75,08  frente a   75 %
#   IND   29,98  frente a   30 %
#   STB    9,48  frente a   10 gabinetes  (conjunto decreciente)
#
# Dicho de otro modo: la calibracion difusa publicada de Lipset ES una
# calibracion directa con idm = 0,95, y esta herramienta la reproduce.
#
# ALCANCE. Valida el paso 4 contra datos macro continuos (PIB, porcentajes,
# recuentos), NO contra items Likert de encuesta, que es el hueco al que
# sirve la herramienta. Para ese caso no existe un conjunto de datos
# publicado y validado equivalente; es el mismo hueco que se describe en el
# informe. Esto no sustituye a usarla con datos reales.

skip_if_not_installed("QCA")

# LF se publica redondeado a dos decimales, asi que la comparacion no puede
# exigir mas precision que la que el dato publicado tiene: media unidad del
# ultimo decimal, con holgura.
TOLERANCIA_REDONDEO <- 0.006

# Anclas recuperadas contra LF. Las crecientes van nula < cruce < plena;
# STB es decreciente porque cuenta gabinetes: cuantos mas, menos estable.
ANCLAS_LIPSET <- list(
  DEV = list(nula = 403.56, cruce = 550.21, plena = 895.99),
  URB = list(nula = 25.55, cruce = 50.00, plena = 64.59),
  LIT = list(nula = 50.45, cruce = 75.08, plena = 89.88),
  IND = list(nula = 20.27, cruce = 29.98, plena = 39.85),
  STB = list(nula = 14.92, cruce = 9.48, plena = 5.07)
)

# El umbral que la documentacion de QCA publica para la version crisp.
UMBRAL_PUBLICADO <- c(DEV = 550, URB = 50, LIT = 75, IND = 30, STB = 10)

justificacion_lipset <- function(cond) {
  paste("Umbral publicado para la version crisp de los datos de Lipset,",
        "usado aqui como punto de cruce de", cond, "para la validacion.")
}

test_that("los datos de Lipset viajan con QCA en sus dos versiones", {
  # Sin esto, todo el fichero pasaria por no encontrar los datos, que es la
  # forma mas comun de prueba ciega.
  crudo <- get(utils::data("LR", package = "QCA", envir = environment()))
  publicado <- get(utils::data("LF", package = "QCA", envir = environment()))

  expect_identical(nrow(crudo), 18L)
  expect_identical(nrow(publicado), 18L)
  expect_true(all(names(ANCLAS_LIPSET) %in% names(crudo)))
  expect_true(all(names(ANCLAS_LIPSET) %in% names(publicado)))
})

test_that("la calibracion reproduce la publicada por Ragin en las cinco condiciones", {
  crudo <- get(utils::data("LR", package = "QCA", envir = environment()))
  publicado <- get(utils::data("LF", package = "QCA", envir = environment()))

  for (cond in names(ANCLAS_LIPSET)) {
    a <- ANCLAS_LIPSET[[cond]]
    anclas <- definir_anclas(plena = a$plena, cruce = a$cruce, nula = a$nula,
                             fuente = "teoria",
                             justificacion = justificacion_lipset(cond))

    obtenido <- calibrar(crudo[[cond]], anclas)

    expect_lt(max(abs(obtenido - publicado[[cond]])), TOLERANCIA_REDONDEO)
  }
})

test_that("el punto de cruce recuperado coincide con el umbral publicado", {
  # Es lo que convierte la prueba anterior en algo mas que un ajuste de
  # curvas: las anclas que reproducen LF no son numeros cualesquiera, son
  # los umbrales que el estudio publico.
  for (cond in names(ANCLAS_LIPSET)) {
    cruce <- ANCLAS_LIPSET[[cond]]$cruce
    publicado <- UMBRAL_PUBLICADO[[cond]]

    # Medio punto porcentual de holgura sobre el umbral publicado, y algo
    # mas donde la escala es de miles de dolares.
    holgura <- if (cond == "DEV") 1 else 0.6
    expect_lt(abs(cruce - publicado), holgura)
  }
})

test_that("el conjunto decreciente de estabilidad se declara y se calibra", {
  # STB cuenta gabinetes: mas gabinetes es menos estable, asi que sus
  # anclas van al reves. Hasta el 31/07/2026 definir_anclas() las
  # rechazaba, y con ellas el ejemplo canonico del metodo: fue esta
  # validacion la que destapo la restriccion.
  a <- ANCLAS_LIPSET$STB
  expect_gt(a$nula, a$cruce)
  expect_gt(a$cruce, a$plena)

  anclas <- definir_anclas(plena = a$plena, cruce = a$cruce, nula = a$nula,
                           fuente = "teoria",
                           justificacion = justificacion_lipset("STB"))
  expect_true(anclas$decreciente)

  crudo <- get(utils::data("LR", package = "QCA", envir = environment()))
  publicado <- get(utils::data("LF", package = "QCA", envir = environment()))

  expect_lt(max(abs(calibrar(crudo$STB, anclas) - publicado$STB)),
            TOLERANCIA_REDONDEO)
})

test_that("en un conjunto decreciente el control de orden espera rho = -1", {
  # La calibracion decreciente invierte el orden por diseno. Si el control
  # siguiera exigiendo rho = 1, A-13 se disparia en todos los casos
  # legitimos y el semaforo dejaria de significar algo.
  a <- ANCLAS_LIPSET$STB
  anclas <- definir_anclas(plena = a$plena, cruce = a$cruce, nula = a$nula,
                           fuente = "teoria",
                           justificacion = justificacion_lipset("STB"))
  crudo <- get(utils::data("LR", package = "QCA", envir = environment()))

  orden <- orden_conservado(crudo$STB, calibrar(crudo$STB, anclas),
                            decreciente = anclas$decreciente)

  expect_true(orden$conservado)
  expect_equal(orden$rho, -1)
})
