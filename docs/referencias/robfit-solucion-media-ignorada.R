# El bucle defectuoso de helper_rob.R se manifiesta HOY en rob.fit(), sin abortar.
#
# A diferencia de seq-along-robcases-demo.R, que MODELA el bucle, este guion
# ejercita la funcion publica rob.fit() de SetMethods contra los datos que trae
# el propio paquete. No hace falta parchear nada ni entrar al namespace.
#
#   R 4.6.1 (2026-06-24) / SetMethods 4.1 / QCA 3.25 / admisc 0.40
#   Verificado 2026-08-06.
#
# Ruta del defecto:
#   rob.fit()  ->  rob.evaluation()  ->  for (i in length(test_sol))
#                                        (helper_rob.R, linea 26)
# La rama de lista de rob.evaluation() siembra P2 con test_sol[[1]] y luego hace
# pmin SOLO con test_sol[[length(test_sol)]]. Todo lo que este en medio se cae.
#
# Esto NO esta enmascarado por el fallo de rob.cases(): rob.fit() corre bien y
# devuelve cifras plausibles. El error es silencioso.

suppressMessages({library(SetMethods); library(QCA)})
cat("R:", R.version.string, "\n")
for (p in c("SetMethods", "QCA", "admisc")) cat(p, as.character(packageVersion(p)), "\n")

data(PAYF)
conds <- c("HE", "GG", "AH", "HI", "HW")
m <- function(ic, nc) minimize(PAYF, outcome = "HL", conditions = conds,
                               incl.cut = ic, n.cut = nc, include = "?",
                               details = TRUE, show.cases = TRUE)

IS <- m(0.87, 2)   # solucion inicial
A  <- m(0.70, 2)   # primera solucion de prueba  -> "HE + HW + AH*HI"
Z  <- m(0.87, 1)   # ultima  solucion de prueba  -> "HE*GG*AH + HE*~GG*HI*HW"
M1 <- m(0.80, 3)   # candidata al medio, variante 1 -> "HE"
M2 <- m(0.90, 2)   # candidata al medio, variante 2 -> "GG*AH"

cat("\nmedio variante 1:", paste(unlist(M1$solution), collapse = " + "), "\n")
cat("medio variante 2:", paste(unlist(M2$solution), collapse = " + "), "\n\n")

# Prueba de mutacion. Primera y ultima FIJAS; se cambia solo la del medio.
f_M1  <- rob.fit(test_sol = list(A, M1, Z), initial_sol = IS, outcome = "HL")
f_M2  <- rob.fit(test_sol = list(A, M2, Z), initial_sol = IS, outcome = "HL")
# Control: la MISMA solucion M2, ahora en la ultima posicion.
f_ult <- rob.fit(test_sol = list(A, Z, M2), initial_sol = IS, outcome = "HL")

tab <- rbind(as.numeric(f_M1), as.numeric(f_M2), as.numeric(f_ult))
dimnames(tab) <- list(c("medio = HE", "medio = GG*AH", "GG*AH movida al final"),
                      colnames(f_M1))
print(round(tab, 4))

cat("\n-- cambiar la solucion del MEDIO mueve cada columna? --\n")
print(setNames(as.numeric(f_M1) != as.numeric(f_M2), colnames(f_M1)))
cat("-- mover esa MISMA solucion al FINAL mueve cada columna? --\n")
print(setNames(as.numeric(f_M1) != as.numeric(f_ult), colnames(f_M1)))

# Salida verificada 2026-08-06:
#
#                       RF_cov RF_cons RF_SC_minTS RF_SC_maxTS
# medio = HE             0.987   0.973       0.960       0.724
# medio = GG*AH          0.887   0.963       0.960       0.724
# GG*AH movida al final  0.887   0.963       0.885       0.730
#
# -- cambiar la solucion del MEDIO mueve cada columna? --
#      RF_cov     RF_cons RF_SC_minTS RF_SC_maxTS
#        TRUE        TRUE       FALSE       FALSE
# -- mover esa MISMA solucion al FINAL mueve cada columna? --
#      RF_cov     RF_cons RF_SC_minTS RF_SC_maxTS
#        TRUE        TRUE        TRUE        TRUE
#
# Lectura: RF_cov y RF_cons pasan por rob.union(), que SI recorre la lista
# entera (linea 5, bien escrita), y por eso reaccionan. RF_SC_minTS y
# RF_SC_maxTS pasan por rob.evaluation(), y ahi la solucion del medio es
# invisible: da la misma cifra con "HE" que con "GG*AH", dos soluciones que no
# se parecen en nada. La misma solucion, movida al final, si mueve el numero.
