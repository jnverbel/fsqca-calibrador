# Reprex autocontenido: esa() produce una tabla que minimize() descarta en silencio.
#
# No usa datos propios ni ediciones manuales: corre el ejemplo publicado en el
# help de ?esa, verbatim, y le pasa a minimize() un argumento de construccion de
# tabla cuyo valor es identico al que ya se uso. Deberia ser un no-op.
#
# Verificado el 2026-08-02 con QCA 3.25, admisc 0.40, SetMethods 4.1, R 4.6.1.

library(QCA)
library(SetMethods)

sol <- function(x) paste(unlist(x$solution), collapse = " + ")

# --- El ejemplo tal como aparece en ?esa -------------------------------------
data(SCHF)

TT_y <- truthTable(SCHF, outcome = "EXPORT",
                   conditions = c("EMP", "BARGAIN", "UNI", "OCCUP", "STOCK", "MA"),
                   incl.cut = .9, complete = TRUE, PRI = TRUE,
                   sort.by = c("out", "incl", "n"))

newtt <- esa(oldtt = TT_y,
             nec_cond = c("STOCK+MA", "EMP"),
             untenable_LR = "BARGAIN*~OCCUP",
             contrad_rows = c("19", "14", "46", "51"))

sum(TT_y$tt$OUT == 0)   # 10
sum(newtt$tt$OUT == 0)  # 49  <- esa() excluyo 39 filas

# --- El fallo -----------------------------------------------------------------
sol(minimize(newtt, include = "?"))
#> "EMP*~BARGAIN*STOCK + EMP*UNI*OCCUP*STOCK + EMP*UNI*STOCK*MA"   <- la enhanced

sol(minimize(newtt, incl.cut = .9, include = "?"))
#> "~EMP*OCCUP + BARGAIN*UNI*STOCK + ~OCCUP*STOCK*~MA"             <- las 39 exclusiones, perdidas

# incl.cut = .9 es EL MISMO valor con el que se construyo TT_y. Pasarlo no
# deberia cambiar nada. QCA::minimize() lo lee como una peticion de reconstruir
# la tabla desde tt$initial.data (comportamiento documentado e intencional,
# confirmado por Adrian Dusa en dusadrian/QCA#4), y al reconstruirla borra la
# columna OUT que esa() acababa de escribir. Sin aviso.
#
# Lo mismo ocurre con n.cut, pri.cut, include, exclude y demas argumentos de
# truthTable(). El resultado es una solucion "enhanced" que no esta enhanced.

# --- Por que ocurre -----------------------------------------------------------
# esa() escribe directamente sobre la columna OUT del objeto:
#   TT$tt[filas, "OUT"] <- 0
# Esa via no deja rastro en tt$call, asi que no sobrevive a una reconstruccion.
# QCA ofrece desde hace anos el argumento `exclude`, que si queda registrado en
# la llamada y por tanto sobrevive:

data(LF)
tt <- truthTable(LF, outcome = "SURV", conditions = c("DEV","URB","LIT","IND","STB"),
                 incl.cut = 0.8, n.cut = 1)

tt_ok   <- change(tt, exclude = 22)              # via soportada
tt_hack <- tt; tt_hack$tt["22", "OUT"] <- 0      # via de esa()

sol(minimize(tt_ok,   n.cut = 1, include = "?")) #> "URB*STB"              <- aguanta
sol(minimize(tt_hack, n.cut = 1, include = "?")) #> "DEV*~IND + URB*STB"   <- se pierde
