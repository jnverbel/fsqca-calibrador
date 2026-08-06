# Respuesta a Oana — LISTA, en espera hasta septiembre de 2026

**Estado:** redactada y verificada. **NO enviar en agosto** — decisión del 2026-08-06. El EUI
está en cierre estival y ya hay dos correos sin responder en su bandeja (07-31 y 08-02); un
tercero en la misma semana se lee como acumulación. Se envía en **septiembre**, responda ella
o no.
**Destinataria:** Ioana-Elena Oana <ioana.oana@eui.eu> — mismo hilo, no correo nuevo.
**Canal alternativo a valorar el mismo día:** issue en `github.com/nenaoana/SetMethods` (repo
de desarrollo de ella, issues habilitados, cero abiertos jamás). Deja rastro público fechado.
**Adjuntos:** `referencias/esa-minimize-reprex.R` y
`referencias/robfit-solucion-media-ignorada.R` (ambos corren enteros; salidas verificadas).
**Soporte:** `revalidacion-setmethods-2026-08-02.md` (re-ejecución de los tres hallazgos),
`hallazgo-esa-setmethods.md` (detalle de `esa()`),
`hallazgo-robfit-bucle-activo.md` (el bucle en tres sitios y activo en `rob.fit`).

Lleva cuatro cosas, en este orden deliberado: **primero las dos rectificaciones** de lo que ya
está en su bandeja —una pista errada y un alcance mal medido—, y solo después los dos
hallazgos nuevos. Rectificar antes de añadir es lo que evita que esto parezca acumulación de
reportes. El último punto, el de `rob.fit()`, es el más fuerte de todo lo enviado hasta hoy:
es el único que corrompe resultados en silencio en vez de abortar.

---

## Asunto

`Re: SetMethods 4.1: rob.cases() … — correction to my earlier speculation, and one further item (esa)`

---

## Cuerpo del correo

Dear Dr. Oana,

Four things, the first two of which are corrections to my own earlier messages.

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

### 2. Correcting the scope of the loop I reported

In my follow-up of 2 August I described the `for (i in length(test_sol))` loop as occurring in
`robust.intersections()`, and added that it was for the time being *masked* by the
`rob.cases()` failure. **Both statements were too narrow**, and I would rather correct them
myself than have you work from them.

Reading `R/helper_rob.R` in full, the same pattern occurs in **three** functions, against one
that is written correctly:

| Line | Function | As written |
|---|---|---|
| 5 | `rob.union` | `for (i in 1:length(test_sol))` — correct |
| 26 | `rob.evaluation` | `for (i in length(test_sol))` |
| 147 | `robust.intersections` | `for (i in length(test_sol))` |
| 208 | `robust.rank` | `for (i in length(test_sol))` |

I had only seen the one in `robust.intersections()`, which is the one visible when
disassembling `rob.cases()`.

### 3. The consequence is not masked: `rob.fit()` is affected today

`rob.fit()` calls `rob.evaluation()`, and `rob.fit()` runs fine — so the loop at line 26
executes in normal use and produces plausible numbers rather than an error.

A mutation test on `PAYF`, with three test solutions. The first and the last are held fixed;
only the middle one is varied, between two solutions that have nothing in common:

```
                      RF_cov RF_cons RF_SC_minTS RF_SC_maxTS
middle = HE            0.987   0.973       0.960       0.724
middle = GG*AH         0.887   0.963       0.960       0.724   <- unchanged
GG*AH moved to last    0.887   0.963       0.885       0.730   <- same solution, now counted
```

`RF_SC_minTS` and `RF_SC_maxTS` do not respond to the middle solution, and do respond to the
very same solution once it occupies the last position. `RF_cov` and `RF_cons` do respond,
because they go through `rob.union()`, which folds over the whole list.

So a user supplying three or more alternative specifications to `rob.fit()` — which is what
the protocol asks for — receives two of the four fit measures computed from the first and the
last specification only, with no warning. I am flagging this ahead of the other two because it
is the only one of the four that returns a wrong answer instead of an error. A self-contained
script is attached.

### 4. One further item, in `esa()`

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
