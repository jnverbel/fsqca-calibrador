# Auditoria tecnica completa de SetMethods 4.1 y admisc 0.40
#
# Script autocontenido: usa exclusivamente datos integrados en los paquetes
# (PAYF, SCHF) y los valores publicados en la Tabla 13 de Verdugo Rojas (2026)
# y Tablas 1/7 de Stengl (2026).
#
# Verificado el 2026-11-24 con:
#   R 4.6.1 / SetMethods 4.1 / QCA 3.25 / admisc 0.40
#
# Demuestra cinco puntos:
#   1. Escaneo del namespace completo de SetMethods: 9 bucles `in length(` en
#      5 funciones (rob.fit, rob.xyplot, rob.evaluation, robust.intersections,
#      robust.rank) + typo `P[, 1] > -P[, 2]` en robust.rank (linea 52).
#   2. Prueba de mutacion sobre rob.fit(), rob.xyplot() y rob.case.ratio() con
#      3 soluciones en PAYF: la del medio se ignora en silencio.
#   3. Teorema detector `RF_SC_minTS <= RF_cov * RF_cons` (identidad algebraica
#      exacta salvo redondeo de QCAfit a 3 decimales) y comprobacion sobre PAYF
#      y la Tabla 13 de la tesis doctoral Verdugo Rojas (2026, Comillas).
#   4. Causa raiz exacta del fallo de rob.cases(): regresion de scoping en
#      admisc::negate() (wrapper de invert() desde admisc 0.38).
#   5. Typo de variable en rob.ncutrange() linea 57 (`n.cut.tl == nrow(data)`
#      en el barrido superior).

suppressMessages({
  library(SetMethods)
  library(QCA)
  library(admisc)
})

cat("=== ENTORNO ===\n")
cat("R:", R.version.string, "\n")
for (p in c("SetMethods", "QCA", "admisc")) {
  cat(sprintf("%s %s\n", p, as.character(packageVersion(p))))
}

## ---------------------------------------------------------------------
## 1. ESCANEO DEL NAMESPACE DE SetMethods: 9 BUCLES EN 5 FUNCIONES
## ---------------------------------------------------------------------
cat("\n=== 1. ESCANEO DE 'in length(' EN NAMESPACE SetMethods ===\n")
ns <- asNamespace("SetMethods")
total_loops <- 0L
for (nm in sort(ls(ns, all.names = TRUE))) {
  obj <- get(nm, envir = ns)
  if (is.function(obj)) {
    src <- deparse(obj)
    hits <- grep("in\\s+length\\(", src)
    if (length(hits) > 0) {
      cat(sprintf("SetMethods:::%s (%d bucle(s)):\n", nm, length(hits)))
      for (h in hits) cat(sprintf("  L%d: %s\n", h, trimws(src[h])))
      total_loops <- total_loops + length(hits)
    }
  }
}
cat(sprintf("Total bucles defectuosos: %d\n", total_loops))

# Typo adicional en robust.rank() linea 52
rr_src <- deparse(get("robust.rank", envir = ns))
cat("\nTypo en robust.rank():\n")
rr_hit <- grep("> -P\\[, 2\\]", rr_src)
for (h in rr_hit) cat(sprintf("  L%d: %s\n", h, trimws(rr_src[h])))

## ---------------------------------------------------------------------
## 2. MUTACION EN rob.fit(), rob.xyplot() Y rob.case.ratio() (PAYF)
## ---------------------------------------------------------------------
cat("\n=== 2. MUTACION CON 3 SOLUCIONES EN PAYF ===\n")
data(PAYF)
conds <- c("HE", "GG", "AH", "HI", "HW")
m <- function(ic, nc) {
  minimize(PAYF, outcome = "HL", conditions = conds,
           incl.cut = ic, n.cut = nc, include = "?",
           details = TRUE, show.cases = TRUE)
}
IS <- m(0.87, 2)
A  <- m(0.70, 2)
Z  <- m(0.87, 1)
M1 <- m(0.80, 3) # HE
M2 <- m(0.90, 2) # GG*AH

f_M1  <- rob.fit(list(A, M1, Z), IS, "HL")
f_M2  <- rob.fit(list(A, M2, Z), IS, "HL")
f_ult <- rob.fit(list(A, Z, M2), IS, "HL")
f_2   <- rob.fit(list(A, Z),     IS, "HL")

tab_rf <- rbind(
  "list(A, M1, Z)" = as.numeric(f_M1),
  "list(A, M2, Z)" = as.numeric(f_M2),
  "list(A, Z)    " = as.numeric(f_2),
  "list(A, Z, M2)" = as.numeric(f_ult)
)
colnames(tab_rf) <- colnames(f_M1)
print(round(tab_rf, 3))

r_M1  <- SetMethods:::rob.case.ratio(list(A, M1, Z), IS, "HL")
r_M2  <- SetMethods:::rob.case.ratio(list(A, M2, Z), IS, "HL")
r_ult <- SetMethods:::rob.case.ratio(list(A, Z, M2), IS, "HL")
cat("\nrob.case.ratio() (RCR_typ, RCR_dev, RCC_Rank):\n")
tab_rcr <- rbind(
  "list(A, M1, Z)" = as.numeric(r_M1),
  "list(A, M2, Z)" = as.numeric(r_M2),
  "list(A, Z, M2)" = as.numeric(r_ult)
)
colnames(tab_rcr) <- colnames(r_M1)
print(tab_rcr)

p_M1  <- rob.xyplot(list(A, M1, Z), IS, "HL")
p_M2  <- rob.xyplot(list(A, M2, Z), IS, "HL")
p_ult <- rob.xyplot(list(A, Z, M2), IS, "HL")
cat("\nrob.xyplot()$data identico al cambiar el del medio (M1 vs M2)?:",
    identical(p_M1$data, p_M2$data), "\n")
cat("rob.xyplot()$data identico al mover M2 al final?              :",
    identical(p_M1$data, p_ult$data), "\n")

## ---------------------------------------------------------------------
## 3. TEOREMA DETECTOR: RF_SC_minTS <= RF_cov * RF_cons
## ---------------------------------------------------------------------
cat("\n=== 3. TEOREMA DETECTOR RF_SC_minTS <= RF_cov * RF_cons ===\n")
P1 <- pimdata(IS, "HL")$solution_formula
PA <- pimdata(A,  "HL")$solution_formula
PM <- pimdata(M2, "HL")$solution_formula
PZ <- pimdata(Z,  "HL")$solution_formula
minTS_true  <- pmin(PA, PM, PZ)
sc_min_true <- sum(pmin(P1, minTS_true)) / sum(pmax(P1, minTS_true))
ceil_exact  <- sum(pmin(P1, minTS_true)) / sum(P1)
ceil_rf     <- f_M2[, "RF_cov"] * f_M2[, "RF_cons"]

cat(sprintf("PAYF list(A, M2, Z) — techo exacto sum(RC)/sum(IS) : %.4f\n", ceil_exact))
cat(sprintf("PAYF list(A, M2, Z) — RF_cov * RF_cons             : %.4f\n", ceil_rf))
cat(sprintf("PAYF list(A, M2, Z) — RF_SC_minTS REAL (parcheado) : %.4f (<= techo: %s)\n",
            sc_min_true, sc_min_true <= ceil_exact + 1e-12))
cat(sprintf("PAYF list(A, M2, Z) — RF_SC_minTS SetMethods 4.1   : %.3f  (VIOLA techo: %s)\n",
            f_M2[, "RF_SC_minTS"], f_M2[, "RF_SC_minTS"] > ceil_rf + 0.003))

# Verificacion sobre Tabla 13 de Verdugo Rojas (2026, ICADE Comillas, p. 90)
vr_cov <- 0.488
vr_cons <- 0.952
vr_sc_min_rep <- 0.548
vr_ceil <- vr_cov * vr_cons
cat(sprintf("\nVerdugo Rojas (2026, Tabla 13) — RF_cov * RF_cons  : %.4f\n", vr_ceil))
cat(sprintf("Verdugo Rojas (2026, Tabla 13) — RF_SC_minTS pub.  : %.3f\n", vr_sc_min_rep))
cat(sprintf("Inflacion minima demostrada                        : +%.4f (+%.1f%% relativo)\n",
            vr_sc_min_rep - vr_ceil, 100 * (vr_sc_min_rep - vr_ceil) / vr_ceil))

## ---------------------------------------------------------------------
## 4. CAUSA RAIZ EXACTA DE rob.cases(): admisc::negate() vs invert()
## ---------------------------------------------------------------------
cat("\n=== 4. CAUSA RAIZ DE rob.cases(): admisc::negate() ===\n")
cat("Definicion de admisc::negate:\n")
print(admisc::negate)

prueba_scoping <- function() {
  x_local  <- "GG*AH+HE*~GG*HI*HW"
  y_local  <- "HE*GG*AH + HE*~GG*HI*HW"
  cn_local <- c("HE", "GG", "AH", "HI", "HW", "HL")

  r_inv <- tryCatch(
    intersection(invert(x_local, snames = cn_local, simplify = FALSE)[[1]][1], y_local)[[1]][1],
    error = function(e) paste("ERROR:", conditionMessage(e))
  )
  r_neg <- tryCatch(
    intersection(negate(x_local, snames = cn_local, simplify = FALSE)[[1]][1], y_local)[[1]][1],
    error = function(e) paste("ERROR:", conditionMessage(e))
  )
  list(con_invert = r_inv, con_negate = r_neg)
}
res_scoping <- prueba_scoping()
cat("Dentro de funcion local con invert():", res_scoping$con_invert, "\n")
cat("Dentro de funcion local con negate():", res_scoping$con_negate, "\n")

## ---------------------------------------------------------------------
## 5. TYPO DE VARIABLE EN rob.ncutrange() LINEA 57
## ---------------------------------------------------------------------
cat("\n=== 5. TYPO EN rob.ncutrange() LINEA 57 ===\n")
nc_src <- deparse(SetMethods::rob.ncutrange)
cat(paste(sprintf("%3d: %s", 53:60, nc_src[53:60]), collapse = "\n"), "\n")
err_nc <- tryCatch(
  rob.ncutrange(data = PAYF, step = 1, max.runs = 1, outcome = "HL",
                conditions = conds, incl.cut = 0.87, n.cut = 2, include = "?"),
  error = function(e) conditionMessage(e)
)
cat("rob.ncutrange(..., max.runs = 1) -> ERROR:", err_nc, "\n")
