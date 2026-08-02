# Seguimiento a Oana — la observación 3 del reporte, ahora confirmada

**Destinataria:** Ioana-Elena Oana <ioana.oana@eui.eu>
**Copia sugerida:** Carsten Q. Schneider (coautor) — añadir su correo antes de enviar.
**Canal:** respuesta al mismo hilo del reporte original (`reporte-bugs-setmethods.md`).
**Adjunto opcional:** `docs/referencias/seq-along-robcases-demo.R` (demostración autocontenida).

Es un seguimiento corto: sube la tercera observación —marcada en su día como *sin
verificar*— a bug confirmado. La prueba decisiva es el contraste entre `rob.union()` y
`robust.intersections()`: la misma operación, en el mismo archivo, escrita bien en una y mal
en la otra.

---

## Asunto

`Re: SetMethods 4.1: rob.cases() … — follow-up: the third observation is confirmed (robust.intersections intersects only the last test solution)`

---

## Cuerpo del correo

Dear Dr. Oana,

A brief follow-up to my earlier report. The third item there, which I had flagged only as an
unverified observation, I have now been able to confirm — and I think it is worth a look in
the same pass as the other two, because it is a one-character fix in the file you would
already be editing.

**The loop.** In `SetMethods:::robust.intersections()` the loop over the test solutions reads:

```r
# robust.intersections(), line 42
test_int <- s2
for (i in length(test_sol)) {
    test_int <- intersection(test_int, test_sol[[i]])
    test_int <- test_int[1]
}
```

`length(test_sol)` is a single number, so the loop runs exactly once, with
`i = length(test_sol)`. `test_int` is seeded from the first test solution (`s2 <-
test_sol[[1]]$solution[[1]]`) and then intersected only with the **last** one. Every test
solution in between is silently skipped.

**Why I am now confident it is a typo and not intended.** The sibling function `rob.union()`,
in the same file, performs the analogous fold over the same list and does it correctly:

```r
# rob.union(), line 4
for (i in 1:length(test_sol)) {
    ...
}
```

The `1:` is simply missing in `robust.intersections()`.

**Behavioural consequence, and why it stayed hidden.** With one or two test solutions the
result happens to be correct — with two, `i = 2` intersects the first and the last, which are
the only two. The defect appears only from **three test solutions onward**, where the middle
ones drop out. The example in `?rob.cases` uses exactly two, which is why it never surfaced. I
verified the consequence by holding the first and last test solutions fixed and varying a
middle one: the current loop's output does not change (the middle solution is ignored),
whereas the corrected fold does. A self-contained demonstration is attached.

Because `test_int` feeds the case categorisation in the default (`maxTS = FALSE`) branch, a
user supplying three or more test solutions to `rob.cases()` would get a silently incorrect
theoretical intersection — the intersection of the first and last test solutions rather than
of all of them.

**One honest caveat.** As things stand this is masked by Bug 1: `rob.cases()` aborts before
the loop is reached, so the miscount cannot currently manifest. I raise it now precisely
because, once Bug 1 is fixed and `rob.cases()` runs again, this would otherwise become a
silent correctness problem for anyone testing three or more alternative specifications.

**Suggested fix**, mirroring `rob.union()`:

```r
for (i in 1:length(test_sol)) {   # or seq_along(test_sol)
```

As before, I would be glad to test a patched version. Thank you again for the package.

With best regards,

Javier Núñez Verbel
[cargo/afiliación — completar]
[correo — completar]
