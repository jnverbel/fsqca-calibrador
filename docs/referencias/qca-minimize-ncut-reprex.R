# Reproducible example: QCA::minimize() silently rebuilds a truthTable object
# when passed a truth-table-construction argument (e.g. n.cut), discarding any
# modification made to that object (as performed by SetMethods::esa(), i.e. the
# Enhanced Standard Analysis of Schneider & Wagemann 2012).
#
# Self-contained: uses only data shipped with QCA (Lipset 1959, `LF`).
#   R 4.6.1 / QCA 3.25 / admisc 0.40

library(QCA)

cat("QCA", as.character(packageVersion("QCA")),
    "admisc", as.character(packageVersion("admisc")), "\n\n")

data(LF)
conds <- c("DEV", "URB", "LIT", "IND", "STB")

# 1. Build a truth table.
tt <- truthTable(LF, outcome = "SURV", conditions = conds,
                 incl.cut = 0.8, n.cut = 1, show.cases = TRUE)

# 2. Modify the truth table object, exactly as esa() does: exclude one
#    configuration by setting its OUT to 0 (a simplifying assumption deemed
#    untenable). Here we pick the first positive row.
target <- rownames(tt$tt[tt$tt$OUT == 1, ])[1]
tt_mod <- tt
tt_mod$tt[target, "OUT"] <- 0
cat("Row", target, "manually set to OUT = 0 in the truthTable object.\n\n")

# 3a. minimize() on the modified object -> honours the modification.
s1 <- minimize(tt_mod, include = "?")
cat("minimize(tt_mod)            :", paste(s1$solution[[1]], collapse = " + "), "\n")

# 3b. SAME object, but now also passing n.cut (a truthTable argument).
#     minimize() rebuilds the truth table from tt$initial.data and SILENTLY
#     discards the OUT = 0 exclusion. No warning is emitted.
s2 <- minimize(tt_mod, n.cut = 1, include = "?")
cat("minimize(tt_mod, n.cut = 1) :", paste(s2$solution[[1]], collapse = " + "), "\n\n")

cat("Identical solutions? ", identical(s1$solution, s2$solution),
    "  <- FALSE: the exclusion was silently dropped.\n\n")

# 4. Confirm no warning is emitted about the rebuild / discarded modification.
warns <- character(0)
withCallingHandlers(
  invisible(minimize(tt_mod, n.cut = 1, include = "?")),
  warning = function(w) { warns[[length(warns) + 1]] <<- conditionMessage(w)
                          invokeRestart("muffleWarning") }
)
cat("Warnings emitted about the rebuild:", length(warns), "\n")

# Mechanism (deparsed minimize(), QCA 3.25, lines 167-186):
#   ttargs <- setdiff(names(formals(truthTable)), c("show.cases", ...))
#   if (any(is.element(ttargs, names(dots)))) {
#       callist <- as.list(tt$call)
#       callist$data <- tt$initial.data
#       tt <- do.call("truthTable", callist[-1])   # rebuilt from raw data
#   }
# The branch reconstructs the truth table from the original data whenever a
# truthTable-construction argument is present in `...`, overwriting the OUT
# column the user (or esa()) had modified, with no warning.
