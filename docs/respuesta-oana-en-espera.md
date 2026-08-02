# Respuesta a Oana — LISTA, en espera de que ella conteste

**Estado:** redactada y verificada. **NO enviar hasta que Oana responda** al reporte del
2026-07-31 o al seguimiento del 2026-08-02.
**Destinataria:** Ioana-Elena Oana <ioana.oana@eui.eu> — mismo hilo, no correo nuevo.
**Adjunto:** `referencias/esa-minimize-reprex.R` (corre entero; salidas verificadas 2026-08-02).
**Soporte:** `revalidacion-setmethods-2026-08-02.md` (re-ejecución de los tres hallazgos),
`hallazgo-esa-setmethods.md` (detalle de `esa()`).

Lleva dos cosas, en este orden deliberado: **primero la rectificación** de una pista errada
que ya está en su bandeja, y solo después el hallazgo nuevo. Rectificar antes de añadir es lo
que evita que esto parezca acumulación de reportes.

---

## Asunto

`Re: SetMethods 4.1: rob.cases() … — correction to my earlier speculation, and one further item (esa)`

---

## Cuerpo del correo

Dear Dr. Oana,

Two things, the first of which is a correction to my own earlier message.

### 1. Correcting my speculation about `rob.cases()`

In my first report I offered, explicitly as unverified speculation, the idea that the
`toupper()` calls in `robust.intersections()` might be collapsing `~A` and `A`. **I have since
tested that and it is wrong** — please disregard it, so that it does not cost you time. The
solutions in `PAYF` encode negation with `~` rather than with lower case, so `toupper()`
leaves them unchanged:

```
initial solution : GG*AH + HE*~GG*HI*HW
test solution 1  : HE + HW + AH*HI
test solution 2  : HE*GG*AH + HE*~GG*HI*HW
```

What I can offer instead is an observation rather than a diagnosis. Instrumenting
`admisc::checkMV()` shows what it receives on each call during the failing `rob.cases()` run:

```
checkMV receives: 'A[1]B[1]C[1]+A[1]B[0]D[1]E[1]'                       <- well formed
checkMV receives: 'E[1]A[1]B[1]C[1]+E[1]A[1]B[0]D[1]'                   <- well formed
checkMV receives: 'C[1]D[1]A[1]B[1]+C[1]D[1]A[1]B[0]E[1]'               <- well formed
checkMV receives: 'negate' 'emp1' 'snames=cond_names'
                  'simplify=FALSE[[1]][1]HEGGAH+negate' ...             <- malformed
```

The fourth call does not receive an expression at all: it receives a character vector holding
fragments of the source code itself, with the condition names concatenated without operators
(`HEGGAH`). That is what `checkMV()` rejects. The calls involved appear to be those at lines
84–99 of the deparsed source:

```r
thintersect$s1s2 <- intersection(negate(emp1, snames = cond_names, simplify = FALSE)[[1]][1],
                                 negate(emp2, snames = cond_names, simplify = FALSE)[[1]][1])
```

I want to be equally explicit this time: **I could not establish the cause.** I tried the call
inline with `snames`, inline without `snames`, and with the value pre-evaluated into a
variable; all three work in isolation, so my hypothesis about non-standard evaluation in
`intersection()` does not reproduce outside the function. I am reporting only what I observed.

The two bugs themselves are unaffected by any of this and still reproduce as reported, on a
clean SetMethods 4.1 / QCA 3.25 / admisc 0.40 installation.

### 2. One further item, in `esa()`

`esa()` excludes configurations by writing directly on the `OUT` column of the truth table
object. That modification leaves no trace in `tt$call`, so it does not survive a
reconstruction of the truth table — and `QCA::minimize()` reconstructs the truth table
whenever it receives any `truthTable()` argument, even when the value passed is identical to
the one already used. The exclusions are dropped with no warning: the resulting "enhanced"
solution is quietly not enhanced.

This reproduces with the example published in `?esa`, unmodified:

```r
newtt <- esa(oldtt = TT_y, nec_cond = c("STOCK+MA", "EMP"),
             untenable_LR = "BARGAIN*~OCCUP", contrad_rows = c("19","14","46","51"))

minimize(newtt, include = "?")$solution
#> "EMP*~BARGAIN*STOCK"  "EMP*UNI*OCCUP*STOCK"  "EMP*UNI*STOCK*MA"

minimize(newtt, incl.cut = .9, include = "?")$solution
#> "~EMP*OCCUP"  "BARGAIN*UNI*STOCK"  "~OCCUP*STOCK*~MA"
```

`incl.cut = .9` is the same value used to build `TT_y`, so passing it should be a no-op;
instead it silently discards the 39 rows `esa()` had just excluded. The same happens with
`n.cut`, `pri.cut` and the other truth-table arguments.

Adrian Dușa confirmed the diagnosis in dusadrian/QCA#4: the reconstruction inside `minimize()`
is intended and documented, and the supported route for exclusions is the `exclude` argument
of `truthTable()`, which is recorded in the call and therefore survives. Moving `esa()` from
the direct `OUT` assignment to `exclude` would close this. A self-contained script is
attached.

With best regards,

Javier Núñez Verbel
