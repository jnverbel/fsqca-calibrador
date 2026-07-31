# Reporte de bugs a SetMethods — borrador listo para enviar

**Destinataria:** Ioana-Elena Oana <ioana.oana@eui.eu> (mantenedora declarada en el DESCRIPTION)
**Copia sugerida:** Carsten Q. Schneider (coautor del paquete y del protocolo)
**Canal:** correo electrónico. El paquete no declara `BugReports` ni `URL`, así que no hay
issue tracker público donde abrirlo.
**Adjunto:** `setmethods-4.1-reprex.R` (script autocontenido, se ejecuta tal cual)

---

## Asunto

`SetMethods 4.1: rob.cases() fails on its own documented example; rob.ncutrange() aborts on NA comparison`

---

## Cuerpo del correo

Dear Dr. Oana,

I am writing to report two reproducible bugs in `SetMethods` 4.1 that I encountered while
implementing your robustness test protocol (Oana & Schneider, 2024) in an applied fsQCA
workflow. Both are reproducible with the data shipped in the package itself, and one of
them reproduces with the verbatim example from the function's own help file.

I have attached a self-contained script that reproduces everything below.

**Environment**

```
R 4.6.1 (2026-06-24), macOS
SetMethods 4.1
QCA 3.25
admisc 0.40
```

---

### Bug 1 — `rob.cases()` fails on the example in `?rob.cases`

Running the example from the help page **without any modification** produces:

```
Error : Incorrect expression, some set names do not have brackets.
```

The example is the one shipped with the package: `data(PAYF)`, conditions
`c("HE","GG","AH","HI","HW")`, outcome `"HL"`, an initial solution at `incl.cut = 0.87`,
and two test solutions at `incl.cut = 0.7` and `n.cut = 1`.

The error originates in `admisc::checkMV()` — the only function in the loaded namespaces
that emits that message — reached through `SetMethods:::robust.intersections()`.

I have not been able to find any combination of arguments that avoids it. I tried
conditions with one-letter and two-letter names, and both conservative and intermediate
solutions; the error persists. This makes the case-oriented component of the protocol
unavailable in this version.

**Control:** `pimdata()` works correctly on the very same solution object, returning all
131 rows. The problem therefore seems confined to the intersection/expression-building
path rather than to the solution object itself.

**A possible lead, offered tentatively.** While reading
`SetMethods:::robust.intersections()` to work around the failure, I noticed that with the
default `use.tilde = TRUE` the branch at lines 76–78 of the deparsed source builds the
expressions with `toupper()`:

```r
emp2 <- paste(toupper(test_int),   collapse = "+")
emp3 <- paste(toupper(test_union), collapse = "+")
emp1 <- paste(toupper(s1),         collapse = "+")
```

Applying `toupper()` to a solution expression that encodes negation as lower case would
collapse `~A` and `A` into the same token, which may be what produces the malformed
expression that `checkMV()` then rejects. I want to be explicit that **this is a reading
of the code, not a verified diagnosis** — I could not confirm it, precisely because the
function aborts before returning anything.

---

### Bug 2 — `rob.ncutrange()` aborts when the lower sweep exhausts `max.runs`

```
Error in if (n.cut.tl == nrow(data)) { : missing value where TRUE/FALSE needed
```

**Reproduction.** The documented example (`max.runs = 10`) succeeds. The *same call* with
`max.runs = 1` fails:

```r
data(PAYF)
conds <- c("HE","GG","AH","HI","HW")

# works
rob.ncutrange(data = PAYF, step = 1, max.runs = 10, outcome = "HL",
              conditions = conds, incl.cut = 0.87, n.cut = 2, include = "?")

# aborts
rob.ncutrange(data = PAYF, step = 1, max.runs = 1, outcome = "HL",
              conditions = conds, incl.cut = 0.87, n.cut = 2, include = "?")
```

**Cause.** In the deparsed source of `rob.ncutrange()`, the lower sweep sets the bound to
`NA` when the run budget is exhausted:

```r
[37]  if ((n.cut - n.cut.tl) >= max.runs * step) {
[38]      n.cut.tl = NA
```

and the value is later compared without guarding against `NA`:

```r
[57]  if (n.cut.tl == nrow(data)) {
```

**Control, and the reason I think `NA` is the intended value rather than an error.** The
sibling function `rob.inclrange()` handles the identical situation gracefully. With
`max.runs = 1` on the same data it returns:

```
Raw Consistency T.:  Lower bound  NA Threshold  0.87 Upper bound  NA
```

That is exactly the behaviour one would want from `rob.ncutrange()`: report the bound as
not established rather than abort. A guard such as `if (!is.na(n.cut.tl) && n.cut.tl ==
nrow(data))` would appear to restore consistency between the two functions, and the
downstream arithmetic (`n.cut.tl + step` at lines 77 and 80) already propagates `NA`
correctly.

This one matters in practice because `max.runs` is a user-facing budget: a researcher who
sets it conservatively to keep runtime down gets a hard error instead of an unestablished
bound.

---

### One further observation, unverified

At line 42 of `SetMethods:::robust.intersections()` the loop over test solutions reads:

```r
for (i in length(test_sol)) {
```

rather than `seq_along(test_sol)`. As written it executes a single iteration with
`i = length(test_sol)`, which would intersect only the last test solution and silently skip
the others. I could not confirm the behavioural consequence because of Bug 1, so I flag it
only as something worth a look while you are in that file.

---

I would be glad to test a patched version against my use case, or to provide any further
detail that would help. Thank you for the package and for the protocol paper — the
robustness protocol is what my workflow is built around, which is why I wanted these
documented rather than worked around silently.

With best regards,

Javier Núñez Verbel
[cargo/afiliación — completar]
[correo — completar]
