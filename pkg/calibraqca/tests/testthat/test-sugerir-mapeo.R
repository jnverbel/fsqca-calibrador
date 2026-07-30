test_that("agrupa los items por su prefijo", {
  d <- data.frame(empresa = "E1", sector = "X",
                  ABS1 = 1, ABS2 = 2, ABS3 = 3,
                  RED1 = 1, RED2 = 2,
                  RES1 = 4, RES2 = 5,
                  stringsAsFactors = FALSE)

  s <- sugerir_mapeo(d, columna_id = "empresa")

  expect_identical(sort(names(s$constructos)), c("ABS", "RED", "RES"))
  expect_identical(s$constructos$ABS, c("ABS1", "ABS2", "ABS3"))
  expect_identical(s$constructos$RED, c("RED1", "RED2"))
})

test_that("deja fuera la columna de identificador y las de texto", {
  d <- data.frame(empresa = "E1", sector = "Textil", tamano = "Micro",
                  ABS1 = 1, ABS2 = 2, stringsAsFactors = FALSE)

  s <- sugerir_mapeo(d, columna_id = "empresa")

  expect_identical(names(s$constructos), "ABS")
  expect_false("sector" %in% unlist(s$constructos))
  expect_false("empresa" %in% unlist(s$constructos))
  expect_setequal(s$ignoradas, c("sector", "tamano"))
})

test_that("propone como identificador la primera columna de texto sin repetidos", {
  d <- data.frame(empresa = c("E1", "E2"), sector = c("X", "X"),
                  ABS1 = c(1, 2), stringsAsFactors = FALSE)

  expect_identical(sugerir_columna_id(d), "empresa")
})

test_that("si ninguna columna de texto identifica, propone la primera", {
  d <- data.frame(sector = c("X", "X"), ABS1 = c(1, 2),
                  stringsAsFactors = FALSE)

  expect_identical(sugerir_columna_id(d), "sector")
})

test_that("un item que no comparte prefijo queda en su propio grupo", {
  # Asi el paso 1 puede avisar de que ese constructo tendria un solo item,
  # que es justo lo que A-03 existe para impedir.
  d <- data.frame(id = "E1", ABS1 = 1, ABS2 = 2, SOLO = 3,
                  stringsAsFactors = FALSE)

  s <- sugerir_mapeo(d, "id")

  expect_true("SOLO" %in% names(s$constructos))
  expect_identical(length(s$constructos$SOLO), 1L)
})

test_that("los prefijos con separador tambien agrupan", {
  d <- data.frame(id = "E1",
                  `cap_1` = 1, `cap_2` = 2, `red_1` = 3, `red_2` = 4,
                  check.names = FALSE, stringsAsFactors = FALSE)

  s <- sugerir_mapeo(d, "id")

  expect_setequal(names(s$constructos), c("cap", "red"))
})

test_that("una sugerencia se puede convertir en mapeo sin tocarla", {
  # Es la prueba que importa: lo que propone tiene que ser utilizable tal
  # cual, no una lista que haya que traducir a mano.
  d <- data.frame(empresa = c("E1", "E2"),
                  ABS1 = c(1, 2), ABS2 = c(2, 3),
                  RES1 = c(4, 5), RES2 = c(5, 4),
                  stringsAsFactors = FALSE)
  s <- sugerir_mapeo(d, "empresa")

  m <- definir_mapeo(
    columna_id = "empresa", encuestados_por_caso = "uno",
    constructos = lapply(names(s$constructos), function(nom)
      list(nombre = nom, rol = if (nom == "RES") "resultado" else "condicion",
           items = s$constructos[[nom]])))

  expect_identical(length(m$constructos), 2L)
  expect_setequal(items_mapeados(m), c("ABS1", "ABS2", "RES1", "RES2"))
})
