# Reporte de bug a QCA — borrador listo para abrir como issue

**Paquete:** `QCA` (Adrian Dușa)
**Canal:** issue en GitHub — el paquete declara `BugReports: https://github.com/dusadrian/QCA/issues`.
**Mantenedor:** Adrian Dușa <dusa.adrian@unibuc.ro>
**Adjunto:** `docs/referencias/qca-minimize-ncut-reprex.R` (script autocontenido, datos del paquete)

**Naturaleza:** fallo silencioso / robustez. No es un crash: `minimize()` devuelve una
solución distinta —y científicamente distinta— sin avisar de que ha descartado la tabla de
verdad que recibió. Es el mismo tipo de defecto que confunde a la comunidad sin dejar rastro:
dos usuarios independientes del grupo *QCA with R* tropezaron con él sin darse cuenta.

- https://groups.google.com/g/qcawithr/c/zyamnS1OQbM (Anna Görg — "Enhanced Standard Analysis")
- https://groups.google.com/g/qcawithr/c/UkJ5REO_VSo (Wuraola — "No intermediate solution")

---

## Título del issue

`minimize() silently rebuilds a truthTable object when passed a truth-table argument (e.g. n.cut), discarding esa()/manual modifications with no warning`

---

## Cuerpo del issue

Dear Dr. Dusa,

I have run into a silent behaviour in `minimize()` that has already misled at least two
users on the *QCA with R* group, and I would like to report it with a self-contained
reproducible example (attached, using only the `LF` data shipped with the package).

**Environment**

```
R 4.6.1 (2026-06-24), macOS
QCA 3.25
admisc 0.40
```

### What happens

When `minimize()` is given an object of class `"truthTable"` **and** any argument that
belongs to `truthTable()` (for example `n.cut`, `incl.cut`, `pri.cut`, `include`,
`exclude`), it rebuilds the truth table from `tt$initial.data` and **silently discards any
modification made to the truth table object**. No warning is emitted.

This matters because that is exactly how the Enhanced Standard Analysis works:
`SetMethods::esa()` (and hand-editing, as in many teaching examples) modifies the `OUT`
column of the truth table to exclude untenable simplifying assumptions. If the user then
calls `minimize(tt, n.cut = ...)`, the exclusions are reverted without any indication, and
the "enhanced" solution is quietly **not** enhanced.

### Reproduction (verbatim, package data)

```r
library(QCA)
data(LF)
conds <- c("DEV", "URB", "LIT", "IND", "STB")

tt <- truthTable(LF, outcome = "SURV", conditions = conds,
                 incl.cut = 0.8, n.cut = 1, show.cases = TRUE)

# Exclude one configuration, exactly as esa() would (OUT -> 0):
target <- rownames(tt$tt[tt$tt$OUT == 1, ])[1]     # row "22"
tt$tt[target, "OUT"] <- 0

minimize(tt, include = "?")$solution
#> [[1]] "URB*STB"

minimize(tt, n.cut = 1, include = "?")$solution    # same object, n.cut passed
#> [[1]] "DEV*~IND"  "URB*STB"                       # exclusion silently dropped
```

The two calls differ only in that the second passes `n.cut`, whose value (`1`) is identical
to the one already used to build `tt`. Passing it should be a no-op; instead it triggers a
full rebuild that overwrites the user's `OUT = 0`.

### Where it originates

In the deparsed source of `minimize()` (QCA 3.25, around lines 167–186):

```r
ttargs <- setdiff(names(formals(truthTable)), c("show.cases", ...))
if (any(is.element(ttargs, names(dots)))) {
    callist <- as.list(tt$call)
    ...
    callist$data <- tt$initial.data
    tt <- do.call("truthTable", callist[-1])   # <- rebuilt from raw data
    ...
}
```

The branch reconstructs the truth table from `tt$initial.data` whenever a
truthTable-construction argument is present in `...`. The reconstruction is correct on its
own terms, but it happens **unconditionally and silently**, so it also discards the `OUT`
column that `esa()` (or the user) had just modified on the passed object.

### Suggested resolution, offered tentatively

I do not think the rebuild itself is wrong — passing `truthTable` arguments to `minimize()`
is a documented convenience. The problem is that it silently overrides a *modified* truth
table object. A minimal, backward-compatible guard would be to warn when both conditions
hold — the input is already a `"truthTable"` object, **and** a truth-table argument is
supplied that would trigger a rebuild — for example:

```
Warning: 'n.cut' was supplied together with a pre-built truth table; the truth table
has been rebuilt from the original data and any manual modifications (e.g. from esa())
were discarded. Omit the argument to keep the supplied truth table.
```

That single line would have saved both users on the forum from publishing a solution that
was silently not the one they had constructed. Detecting that the object was actually
modified (comparing its `OUT` against a fresh rebuild) would be even better, but a warning on
the argument alone is already enough to remove the silent failure.

I would be glad to test a patched version, or to provide any further detail. Thank you for
the package.

With best regards,

Javier Núñez Verbel
[cargo/afiliación — completar]
[correo — completar]
