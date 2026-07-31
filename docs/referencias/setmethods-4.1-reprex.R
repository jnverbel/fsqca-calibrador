# Reproducible examples for two bugs in SetMethods 4.1
# Self-contained: uses only data shipped with the package.
#
#   R 4.6.1 (2026-06-24) / SetMethods 4.1 / QCA 3.25 / admisc 0.40

library(SetMethods)
library(QCA)

cat("R:", R.version.string, "\n")
for (p in c("SetMethods", "QCA", "admisc")) {
  cat(p, as.character(packageVersion(p)), "\n")
}

data(PAYF)
conds <- c("HE", "GG", "AH", "HI", "HW")


## ---------------------------------------------------------------------
## BUG 1 -- rob.cases() fails on the verbatim example from ?rob.cases
## ---------------------------------------------------------------------

IS <- minimize(data = PAYF, outcome = "HL", conditions = conds,
               incl.cut = 0.87, n.cut = 2, include = "?",
               details = TRUE, show.cases = TRUE)

TS1 <- minimize(data = PAYF, outcome = "HL", conditions = conds,
                incl.cut = 0.7, n.cut = 2, include = "?",
                details = TRUE, show.cases = TRUE)

TS2 <- minimize(data = PAYF, outcome = "HL", conditions = conds,
                incl.cut = 0.87, n.cut = 1, include = "?",
                details = TRUE, show.cases = TRUE)

TS <- list(TS1, TS2)

rob.cases(test_sol = TS, initial_sol = IS, outcome = "HL")
#> Error : Incorrect expression, some set names do not have brackets.

# Control: pimdata() works on the same solution object.
nrow(pimdata(results = IS, outcome = "HL"))
#> [1] 131


## ---------------------------------------------------------------------
## BUG 2 -- rob.ncutrange() aborts when the lower sweep exhausts max.runs
## ---------------------------------------------------------------------

# Documented example, max.runs = 10: works.
rob.ncutrange(data = PAYF, step = 1, max.runs = 10, outcome = "HL",
              conditions = conds, incl.cut = 0.87, n.cut = 2, include = "?")
#> N.Cut:  Lower bound  2 Threshold  2 Upper bound  2

# Same call, max.runs = 1: aborts.
rob.ncutrange(data = PAYF, step = 1, max.runs = 1, outcome = "HL",
              conditions = conds, incl.cut = 0.87, n.cut = 2, include = "?")
#> Error in if (n.cut.tl == nrow(data)) { :
#>   missing value where TRUE/FALSE needed

# Control: rob.inclrange() handles the same situation gracefully,
# reporting the bounds as NA instead of aborting.
rob.inclrange(data = PAYF, step = 0.05, max.runs = 1, outcome = "HL",
              conditions = conds, incl.cut = 0.87, n.cut = 2, include = "?")
#> Raw Consistency T.:  Lower bound  NA Threshold  0.87 Upper bound  NA
