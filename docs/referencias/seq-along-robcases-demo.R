suppressMessages(library(admisc))
cat("admisc", as.character(packageVersion("admisc")), "\n\n")
sn <- "A,B,C,D"

# Reproduccion fiel del bucle de robust.intersections (lineas 41-45).
# Modelamos cada test_sol[[i]] por su expresion-solucion (string), y sembramos
# test_int con la PRIMERA, igual que s2 <- test_sol[[1]]$solution[[1]].
buggy_fold <- function(sols) {          # tal como esta escrito: for (i in length(sols))
  test_int <- sols[[1]]
  for (i in length(sols)) {
    test_int <- intersection(test_int, sols[[i]], snames = sn)[[1]][1]
  }
  test_int
}
fixed_fold <- function(sols) {          # lo que se pretendia: for (i in seq_along(sols))
  test_int <- sols[[1]]
  for (i in seq_along(sols)) {
    test_int <- intersection(test_int, sols[[i]], snames = sn)[[1]][1]
  }
  test_int
}

cat("=== 3 soluciones de prueba, variando SOLO la del medio ===\n")
solsA <- list("A*B*C", "A*B*D", "A*C")   # medio = A*B*D
solsB <- list("A*B*C", "A",     "A*C")   # medio = A  (mucho mas amplio)

cat("buggy(A) :", buggy_fold(solsA), "\n")
cat("buggy(B) :", buggy_fold(solsB), "   <- cambio el del medio y NO cambia nada\n")
cat("  -> ¿la del medio es ignorada por el bug?:", identical(buggy_fold(solsA), buggy_fold(solsB)), "\n\n")

cat("fixed(A) :", fixed_fold(solsA), "\n")
cat("fixed(B) :", fixed_fold(solsB), "   <- con seq_along, el del medio SI influye\n")
cat("  -> ¿el fold correcto distingue?:", !identical(fixed_fold(solsA), fixed_fold(solsB)), "\n\n")

cat("=== control: con 2 soluciones el bug queda enmascarado ===\n")
s2sols <- list("A*B*C", "A*C")
cat("buggy(2):", buggy_fold(s2sols), " | fixed(2):", fixed_fold(s2sols),
    " | iguales?:", identical(buggy_fold(s2sols), fixed_fold(s2sols)), "\n")
cat("(el ejemplo de ?rob.cases usa 2 -> por eso nunca se vio)\n")
