# Cuarto hallazgo en SetMethods: `esa()` — EN ESPERA, no enviado

**Estado:** verificado y guardado. **No se envía todavía.**
**Motivo:** el 2026-08-02 ya salieron dos correos a Oana (el reporte de `rob.cases()` /
`rob.ncutrange()` y el seguimiento de `robust.intersections()`), ninguno respondido aún. Un
tercer correo el mismo día resta peso a los dos que ya están sobre su mesa. Este texto entra
como punto adicional **cuando ella conteste**, o en el siguiente seguimiento si no contesta.

**Destinataria:** Ioana-Elena Oana <ioana.oana@eui.eu> — mismo hilo.
**Adjunto:** `docs/referencias/esa-minimize-reprex.R` (corre entero, salidas verificadas).

---

## El hallazgo

`esa()` excluye configuraciones escribiendo directamente sobre la columna `OUT` del objeto
(`TT$tt[filas, "OUT"] <- 0`). Esa vía no deja rastro en `tt$call`, así que cualquier
reconstrucción posterior de la tabla la borra. Y `QCA::minimize()` reconstruye la tabla —de
forma documentada e intencional— en cuanto recibe cualquier argumento de `truthTable()`
(`n.cut`, `incl.cut`, `pri.cut`, `include`, `exclude`…), **aunque el valor sea idéntico al
que ya se usó**.

Resultado: la solución sale sin las exclusiones y sin ningún aviso. Una solución *enhanced*
que no está enhanced.

Reproducido con el ejemplo publicado en `?esa`, sin modificarlo (QCA 3.25, admisc 0.40,
SetMethods 4.1):

| llamada | solución |
|---|---|
| `minimize(newtt, include="?")` | `EMP*~BARGAIN*STOCK + EMP*UNI*OCCUP*STOCK + EMP*UNI*STOCK*MA` |
| `minimize(newtt, incl.cut=.9, include="?")` | `~EMP*OCCUP + BARGAIN*UNI*STOCK + ~OCCUP*STOCK*~MA` |

`esa()` había puesto `OUT = 0` en 39 filas (de 10 a 49). El `incl.cut = .9` es el mismo valor
con el que se construyó `TT_y`.

## La corrección

Usar el argumento `exclude` de `truthTable()`, que sí queda registrado en la llamada y por
tanto sobrevive a la reconstrucción. `change(tt, exclude = 22)` aguanta un `n.cut` posterior;
la edición manual de `OUT` no. Es un cambio local dentro de `esa()`.

## Procedencia

Adrian Dușa (mantenedor de QCA) lo confirmó en
[dusadrian/QCA#4](https://github.com/dusadrian/QCA/issues/4) el 2026-08-02, al responder a un
reporte que le habíamos dirigido a QCA por error: *"What I believe is not working (well) …
is the old hack in function `esa()`"*, y señaló `exclude` como la vía recomendada. El
comportamiento de `minimize()` es suyo, intencional y documentado; el defecto está en
`esa()`.

**Lección para reportes futuros:** el primer reporte fue al paquete equivocado por no
comprobar si la API ya ofrecía una vía soportada. Verificar que una función existe no es
verificar que es la que corresponde usar.

---

## Párrafo para el correo (inglés, listo)

Dear Dr. Oana,

One further item, related to `esa()` rather than to the robustness functions.

`esa()` excludes configurations by writing directly on the `OUT` column of the truth table
object. That modification leaves no trace in `tt$call`, so it does not survive a
reconstruction of the truth table — and `QCA::minimize()` reconstructs the truth table
whenever it receives any `truthTable()` argument, even when the value passed is identical to
the one already used. The exclusions are dropped and no warning is issued: the resulting
"enhanced" solution is quietly not enhanced.

This reproduces with the example published in `?esa`, unmodified:

```r
newtt <- esa(oldtt = TT_y, nec_cond = c("STOCK+MA", "EMP"),
             untenable_LR = "BARGAIN*~OCCUP", contrad_rows = c("19","14","46","51"))

minimize(newtt, include = "?")$solution
#> "EMP*~BARGAIN*STOCK"  "EMP*UNI*OCCUP*STOCK"  "EMP*UNI*STOCK*MA"

minimize(newtt, incl.cut = .9, include = "?")$solution
#> "~EMP*OCCUP"  "BARGAIN*UNI*STOCK"  "~OCCUP*STOCK*~MA"
```

`incl.cut = .9` is the same value used to build `TT_y`, so passing it should be a no-op; it
silently discards the 39 rows `esa()` had just excluded. The same happens with `n.cut`,
`pri.cut` and the remaining truth-table arguments.

Adrian Dușa confirmed the diagnosis in dusadrian/QCA#4: the reconstruction in `minimize()` is
intended and documented, and the recommended route for exclusions is the `exclude` argument
of `truthTable()`, which is recorded in the call and therefore survives. Switching `esa()`
from the direct `OUT` assignment to `exclude` would close this.

A self-contained script is attached.

With best regards,

Javier Núñez Verbel
