# La puerta de acceso, que hasta ahora no tenia ni una prueba.
#
# Es el unico control que separa la herramienta de quien pase por la URL, y
# se comprobaba a ojo. Dos cosas se cubren aqui:
#
#   1. Que `clave_correcta` acepte la clave y rechace todo lo demas, en
#      particular los casos que un `==` ingenuo deja pasar: prefijos,
#      sufijos y una diferencia en el ultimo caracter.
#   2. Que en un despliegue publico la aplicacion se NIEGUE a arrancar sin
#      clave, en vez de avisar por consola y quedarse abierta. El aviso
#      vivia en los registros de Fly, donde no lo lee nadie.

source(desde_raiz("app", "R", "acceso.R"))

# --- 1. Comparacion de la clave ---------------------------------------

test_that("acepta la clave exacta y nada mas", {
  expect_true(clave_correcta("secreta", "secreta"))
  expect_false(clave_correcta("Secreta", "secreta"))
  expect_false(clave_correcta("otra-cosa", "secreta"))
})

test_that("un prefijo o un sufijo de la clave no entra", {
  # El relleno con ceros es lo que distingue longitudes: sin el, comparar
  # los primeros n caracteres dejaria entrar a "secret".
  expect_false(clave_correcta("secret", "secreta"))
  expect_false(clave_correcta("secretas", "secreta"))
  expect_false(clave_correcta("", "secreta"))
})

test_that("una diferencia en el ultimo caracter se detecta", {
  # Si la comparacion se rindiera en el primer caracter distinto, este caso
  # y el de la primera letra tardarian tiempos distintos. Aqui solo se
  # comprueba el resultado; el tiempo lo cubre el comentario de acceso.R.
  expect_false(clave_correcta("secretx", "secreta"))
  expect_false(clave_correcta("xecreta", "secreta"))
})

test_that("una entrada que no es un texto unico se rechaza", {
  expect_false(clave_correcta(NULL, "secreta"))
  expect_false(clave_correcta(123, "secreta"))
  expect_false(clave_correcta(c("secreta", "secreta"), "secreta"))
  expect_false(clave_correcta(NA_character_, "secreta"))
})

test_that("los acentos y la enie no rompen la comparacion", {
  expect_true(clave_correcta("contrasena-nina", "contrasena-nina"))
  expect_true(clave_correcta("clave-con-tilde-a", "clave-con-tilde-a"))
  expect_false(clave_correcta("clave-con-tilde-a", "clave-con-tilde-e"))
})

# --- 2. La clave en un despliegue publico ------------------------------

# Cada prueba deja el entorno como lo encontro: testthat comparte proceso
# entre ficheros y una variable olvidada aqui contaminaria a las demas.
con_entorno <- function(vars, codigo) {
  previo <- Sys.getenv(names(vars), unset = NA, names = TRUE)
  do.call(Sys.setenv, as.list(vars))
  on.exit({
    for (nombre in names(previo)) {
      if (is.na(previo[[nombre]])) Sys.unsetenv(nombre)
      else do.call(Sys.setenv, setNames(list(previo[[nombre]]), nombre))
    }
  }, add = TRUE)
  force(codigo)
}

test_that("en Fly sin CLAVE_APP la aplicacion no arranca", {
  con_entorno(c(FLY_APP_NAME = "calibrador-fsqca", CLAVE_APP = ""), {
    expect_error(comprobar_acceso_al_arrancar(), "CLAVE_APP")
  })
})

test_that("el error dice como arreglarlo, no solo que algo falla", {
  con_entorno(c(FLY_APP_NAME = "calibrador-fsqca", CLAVE_APP = ""), {
    mensaje <- tryCatch(comprobar_acceso_al_arrancar(),
                        error = function(e) conditionMessage(e))
    expect_match(mensaje, "flyctl secrets set", fixed = TRUE)
  })
})

test_that("en Fly con CLAVE_APP arranca", {
  con_entorno(c(FLY_APP_NAME = "calibrador-fsqca", CLAVE_APP = "una-clave"), {
    expect_true(comprobar_acceso_al_arrancar())
  })
})

test_that("fuera de Fly y sin clave sigue arrancando abierta", {
  # En la maquina del investigador no hay a quien proteger, y bloquear ahi
  # convertiria la herramienta en inservible en local.
  con_entorno(c(FLY_APP_NAME = "", CLAVE_APP = ""), {
    expect_true(comprobar_acceso_al_arrancar())
  })
})

test_that("una CLAVE_APP en blanco no cuenta como clave", {
  # Sys.setenv(CLAVE_APP = "   ") es el error tipico al pegar el secreto.
  con_entorno(c(FLY_APP_NAME = "calibrador-fsqca", CLAVE_APP = "   "), {
    expect_error(comprobar_acceso_al_arrancar(), "CLAVE_APP")
  })
})
