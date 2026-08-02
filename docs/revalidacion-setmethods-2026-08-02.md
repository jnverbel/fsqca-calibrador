# Revalidación de lo enviado a Oana — 2026-08-02

Motivo: tras la respuesta de Adrian Dușa en `dusadrian/QCA#4` (que reencaminó un reporte mal
dirigido), se re-ejecutaron los tres hallazgos ya enviados a Oana contra una instalación
limpia de SetMethods 4.1 / QCA 3.25 / admisc 0.40, para comprobar que lo que salió por correo
se sostiene.

## Resultado: los tres se sostienen

| Hallazgo enviado | Re-ejecutado hoy |
|---|---|
| Bug 1 — `rob.cases()` falla con el ejemplo de `?rob.cases` | ✅ `Incorrect expression, some set names do not have brackets.` |
| Bug 2 — `rob.ncutrange()` aborta con `max.runs = 1` | ✅ `max.runs=10` → bounds 2/2/2; `max.runs=1` → `missing value where TRUE/FALSE needed` |
| Obs. 3 — `for (i in length(test_sol))` en `robust.intersections()` | ✅ literal; `rob.union()` escribe `for (i in 1:length(test_sol))` |

También se confirmó lo afirmado sobre el origen del mensaje: `admisc::checkMV()` es la **única**
función en los tres namespaces cargados que emite `"do not have brackets"`.

## Lo que NO se sostiene: el *lead* del `toupper`

El reporte ofrecía —marcado explícitamente como *"a reading of the code, not a verified
diagnosis"*— la hipótesis de que `toupper()` en las líneas 76–78 colapsaría `~A` y `A`.

**Es incorrecta.** Las soluciones de `PAYF` codifican la negación con `~`, no con minúsculas:

```
solución inicial : GG*AH + HE*~GG*HI*HW
test 1           : HE + HW + AH*HI
test 2           : HE*GG*AH + HE*~GG*HI*HW
hay minúsculas   : FALSE      hay tilde ~ : TRUE
```

`toupper()` sobre esas cadenas no cambia nada. La hipótesis no explica el fallo.

## Evidencia mejor, en su lugar

Instrumentando `admisc::checkMV()` se ve qué recibe en cada llamada durante `rob.cases()`:

```
>> checkMV recibe: 'A[1]B[1]C[1]+A[1]B[0]D[1]E[1]'              <- bien
>> checkMV recibe: 'E[1]A[1]B[1]C[1]+E[1]A[1]B[0]D[1]'          <- bien
>> checkMV recibe: 'C[1]D[1]A[1]B[1]+C[1]D[1]A[1]B[0]E[1]'      <- bien
>> checkMV recibe: 'negate' 'emp1' 'snames=cond_names' 'simplify=FALSE[[1]][1]HEGGAH+negate' …
                                                                 ^ vector corrupto
```

La cuarta llamada no recibe una expresión: recibe **fragmentos del propio código fuente**
convertidos en texto (`negate`, `emp1`, `snames=cond_names`, `simplify=FALSE[[1]][1]…`), con
los nombres de condición ya pegados sin operadores (`HEGGAH`). Eso es lo que `checkMV()`
rechaza, y con razón.

Las llamadas implicadas son las de las líneas 84–99 del deparse:

```r
thintersect$s1s2 <- intersection(negate(emp1, snames = cond_names, simplify = FALSE)[[1]][1],
                                 negate(emp2, snames = cond_names, simplify = FALSE)[[1]][1])
```

**Causa exacta: no determinada.** Se probaron tres variantes en aislamiento —inline con
`snames`, inline sin `snames`, y con el valor pre-evaluado en variable— y **las tres
funcionan**. La hipótesis de que se deba a la evaluación no estándar de `intersection()`
(`dots <- substitute(list(...))`) no reproduce fuera de la función. No se siguió indagando:
depurar el interior de SetMethods no es trabajo de este proyecto.

Lo que se le puede dar a Oana es la traza de `checkMV()`, que es dato duro y le señala el
punto exacto donde mirar, sin adjudicar una causa.

## Consecuencia para el correo ya enviado

El reporte que Oana tiene en su bandeja contiene una hipótesis errada. Está etiquetada como
no verificada, así que no compromete la credibilidad de los dos bugs —ambos reproducibles con
los ejemplos del propio paquete—, pero puede hacerle perder tiempo buscando por donde no es.

## Lección

Dos hipótesis de causa se cayeron al probarlas (el `toupper` y el NSE de `intersection()`).
La regla que sale de aquí: **un reprex que falla es un hecho; una lectura del código que
explica por qué falla es una conjetura, y no debe salir por correo sin haberla intentado
romper primero.** Lo mismo vale para elegir destinatario: el reporte a QCA salió mal dirigido
por no comprobar si la API ya ofrecía una vía soportada (`exclude`).
