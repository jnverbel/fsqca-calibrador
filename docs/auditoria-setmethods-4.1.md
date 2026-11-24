# Auditoría técnica de `SetMethods` 4.1 (y `admisc` 0.40): evidencia en código fuente y en tesis publicadas

> **English summary.** This note consolidates the complete source-level verification of four
> upstream defects affecting the QCA robustness test protocol (Oana & Schneider, 2024) as
> implemented in `SetMethods 4.1` (CRAN, 2025-03-21) alongside `QCA 3.25` and `admisc 0.40`
> under `R 4.6.1`. All findings are reproduced by the self-contained script
> [`docs/referencias/auditoria-setmethods-4.1-reprex.R`](referencias/auditoria-setmethods-4.1-reprex.R).
>
> 1. **Silent corruption across 9 loops in 5 functions (`for (i in length(test_sol))`):**
>    whenever three or more test solutions are passed, all middle specifications are silently
>    dropped in `rob.fit()`, `rob.xyplot()`, `rob.evaluation()` (which feeds `rob.case.ratio()`
>    and `rob.cases()`), `robust.intersections()`, and `robust.rank()`. This introduces a
>    systematic optimistic bias (inflating `RCR_typ`/`RCR_dev`, undercounting shaky and possible
>    cases, and generally inflating `RF_SC_minTS`). Because `RF_cov` and `RF_cons` come from
>    `rob.corefit()` (whose loop `for (i in 2:length(all_sols))` is correct), any published
>    table where `RF_SC_minTS > RF_cov * RF_cons + 0.003` (without altering the outcome
>    calibration) violates an exact algebraic ceiling and proves silent corruption without
>    needing raw data.
> 2. **Empirical audit of published 2026 theses:**
>    - *Verdugo Rojas (2026, Universidad Pontificia Comillas — ICADE, PhD dissertation, Table 13,
>      p. 90)* reports `RF_cov = 0.488`, `RF_cons = 0.952`, and `RF_SC_minTS = 0.548` across
>      three test solutions (`rob.singletest()` indices `(2)`, `(3)`, `(1)`), with the strictest
>      model (`SC = 0.369`) in middle position `(2)`. The reported `0.548` exceeds the exact
>      mathematical ceiling `0.488 × 0.952 = 0.4646` by at least `+0.083` (+18 % relative
>      inflation).
>    - *Stengl (2026, LMU Munich, Bachelor's thesis, Table 12, p. 38 & Appendix E, pp. 101–102)*
>      passed `list(TS1_Y2, TS2_Y2, TS3_Y2)` into `rob.fit()` and `rob.xyplot()` (figures
>      survived only because all three test solutions produced the same formula `X3`), and
>      explicitly omitted detailed `rob.cases()` metrics *"due to software limitations"*,
>      matching the `rob.cases()` crash reproduced on her dataset.
> 3. **Exact root cause of `rob.cases()` failure (`admisc >= 0.38`):** `admisc::negate()` became
>    a wrapper `function(...) invert(...)` in `admisc 0.38`, shifting `admisc::recreate()`'s
>    `parent.frame(n = 2)` lookup away from the caller (`SetMethods:::robust.intersections()`).
>    Calling `invert()` inside a local function succeeds; calling `negate()` fails.
> 4. **Exact root cause of `rob.ncutrange()` abort:** line 57 checks the wrong variable
>    (`if (n.cut.tl == nrow(data))` instead of `n.cut.tu`) inside the upper sweep, aborting on
>    `NA` whenever the lower sweep exhausts `max.runs`.
> 5. **Additional defects:** `robust.rank()` line 52 contains `P[, 1] > -P[, 2]` instead of
>    `P[, 1] >= P[, 2]`; `esa()` modifies `TT$tt[..., "OUT"] <- 0` directly without updating
>    `TT$call`, so `QCA::minimize()` silently discards the exclusions whenever passed any
>    `truthTable()` argument.
>
> **Notice:** Prior reports were sent twice to the `SetMethods` maintainer without response.
> This document places the verified, reproducible technical evidence on public record.
> `calibraqca` itself is not affected by any of these defects.

---

## Entorno verificado

| Componente | Versión | Fecha / empaquetado |
|---|---|---|
| R | `4.6.1` | 2026-06-24 |
| `SetMethods` | `4.1` | CRAN 2025-03-21 |
| `QCA` | `3.25` | CRAN 2026-05-09 |
| `admisc` | `0.40` | CRAN 2026-03-27 |

Script autocontenido que reproduce todas las verificaciones de este documento:
[`docs/referencias/auditoria-setmethods-4.1-reprex.R`](referencias/auditoria-setmethods-4.1-reprex.R).

---

## 1. Corrupción silenciosa: 9 bucles `for (i in length(test_sol))` en 5 funciones

### 1.1 Alcance completo en el namespace de `SetMethods 4.1`

Un barrido sistemático de todas las funciones del namespace `SetMethods` (no solo `R/helper_rob.R`) muestra que el patrón defectuoso `for (i in length(test_sol))` —en lugar de `for (i in 1:length(test_sol))` o `seq_along(test_sol)`— aparece en **9 bucles repartidos en 5 funciones**, incluidas **dos funciones públicas exportadas** que hoy corren sin error y devuelven cifras y gráficos plausibles:

| Función | Visibilidad | Líneas (deparse) | Qué corrompe cuando `length(test_sol) >= 3` |
|---|---|---|---|
| `rob.fit()` | **Pública** | L17 (`P2` / `minTS`) y L28 (`P3` / `maxTS`) | `RF_SC_minTS` y `RF_SC_maxTS` ignoran todas las soluciones intermedias (`2 .. k-1`). |
| `rob.xyplot()` | **Pública** | L6 (`P2` / `minTS`) y L17 (`P3` / `maxTS`) | Coordenadas `minTS`/`maxTS` de cada caso y subtítulo (`RCR_typ`, `RCR_dev`, `RCC_Rank`). |
| `rob.evaluation()` | Interna (usada por `rob.case.ratio()` y `rob.cases()`) | L5 (`P2`) y L16 (`P3`) | `RCR_typ`, `RCR_dev`, `RCC_Rank` y clasificación de casos *robust / shaky / possible*. |
| `robust.intersections()` | Interna (usada por `rob.cases()`) | L42 (`test_int`) | Intersección booleana teórica `minTS` (latente hoy tras el fallo de `rob.cases()`). |
| `robust.rank()` | Interna | L5 (`P2`) y L16 (`P3`) | Rango de robustez. Además, en **L52** contiene otro typo: `P[, 1] > -P[, 2]` en vez de `P[, 1] >= P[, 2]`. |

**Por qué `RF_cov` y `RF_cons` sí reaccionan en `rob.fit()`:** se calculan llamando a `rob.corefit()`, cuya línea 14 sí está bien escrita (`for (i in 2:length(all_sols))`). En cambio, `rob.fit()` no delega `RF_SC_minTS` y `RF_SC_maxTS` en `rob.evaluation()`, sino que duplica inline los dos bucles defectuosos (L15–L36).

**Por qué pasó desapercibido:** con 1 o 2 soluciones de prueba el bucle coincide con el comportamiento correcto (`P2` y `P3` se inicializan con `test_sol[[1]]` y el bucle ejecuta una sola iteración con `i = 2`). Todos los ejemplos documentados del paquete usan exactamente 2 soluciones (`TS <- list(TS1, TS2)`). El fallo se activa a partir de **3 soluciones alternativas**, que es precisamente el caso habitual del protocolo de Oana & Schneider (2024) (variaciones en calibración, `incl.cut` y `n.cut`).

### 1.2 Prueba de mutación sobre datos del propio paquete (`PAYF`)

Con `IS = minimize(PAYF, incl.cut = 0.87, n.cut = 2)`, primera fija `A = m(0.70, 2)`, última fija `Z = m(0.87, 1)` y variando únicamente la solución intermedia entre `M1 = m(0.80, 3)` (`HE`) y `M2 = m(0.90, 2)` (`GG*AH`):

| Llamada | `RF_cov` | `RF_cons` | `RF_SC_minTS` | `RF_SC_maxTS` | `RCR_dev` | `rob.xyplot()$data` |
|---|---|---|---|---|---|---|
| `list(A, M1, Z)` | 0.987 | 0.973 | **0.960** | **0.724** | **0.296** | Idéntico a `M2` |
| `list(A, M2, Z)` | 0.887 | 0.963 | **0.960** | **0.724** | **0.296** | Idéntico a `M1` |
| `list(A, Z)` (sin medio) | 0.987 | 0.973 | **0.960** | **0.724** | **0.296** | Idéntico |
| `list(A, Z, M2)` (`M2` al final) | 0.887 | 0.963 | **0.885** | **0.730** | **0.222** | Cambia (`FALSE`) |

### 1.3 Sesgo sistemáticamente optimista y desigualdad detectora para literatura publicada

Al omitir las soluciones intermedias, para todo caso $i$:

$$\text{minTS}_{\text{bug}}(i) \ge \text{minTS}_{\text{real}}(i), \qquad \text{maxTS}_{\text{bug}}(i) \le \text{maxTS}_{\text{real}}(i)$$

Consecuencias matemáticas garantizadas:
1. Los casos *shaky* ($IS > 0.5 \land \text{minTS} < 0.5$) y *possible* ($IS < 0.5 \land \text{maxTS} > 0.5$) quedan siempre **iguales o subestimados**; los casos *robust* quedan **iguales o sobreestimados**.
2. Como $\text{Robust} + \text{Shaky}$ depende únicamente de $IS$, el numerador de `RCR_typ` y `RCR_dev` sube o se mantiene y el denominador baja o se mantiene: **$\text{RCR}_{\text{bug}} \ge \text{RCR}_{\text{real}}$ siempre** (sesgo puramente optimista). `RCC_Rank` solo puede desplazarse hacia rangos artificialmente favorables.
3. **Teorema detector sobre tablas ya publicadas (sin necesitar los datos brutos):** en `rob.fit()`, `RF_cov = rcf[2] / isf[2]` y `RF_cons = isf[1] / rcf[1]`. Cuando todas las especificaciones comparten la misma calibración del resultado $Y$, al multiplicar ambas cantidades se cancelan $\sum Y$, $\sum \min(\text{IS}, Y)$ y $\sum \min(\text{RC}, Y)$:

$$\text{RF\_cov} \times \text{RF\_cons} = \frac{\sum \min(\text{IS}, \text{minTS}_{\text{real}})}{\sum \text{IS}}$$

Y como $\sum \max(\text{IS}, \text{minTS}_{\text{real}}) \ge \sum \text{IS}$ para cualquier conjunto de datos:

$$\text{RF\_SC\_minTS}_{\text{real}} = \frac{\sum \min(\text{IS}, \text{minTS}_{\text{real}})}{\sum \max(\text{IS}, \text{minTS}_{\text{real}})} \le \text{RF\_cov} \times \text{RF\_cons}$$

*(Con un margen de redondeo máximo de $\approx 0.003$ porque `QCAfit()` redondea consistencia y cobertura a 3 decimales antes del cociente.)*

En la prueba de mutación anterior con `PAYF`, el bug produce `RF_cov × RF_cons = 0.887 × 0.963 = 0.8542` frente a `RF_SC_minTS = 0.960`, violando el techo en `+0.106`. Cualquier publicación que muestre `RF_SC_minTS > RF_cov × RF_cons + 0.003` (sin variar la calibración del resultado) contiene una **violación matemática directa causada por este bug**.

---

## 2. Auditoría empírica de tesis publicadas (2026)

### 2.1 Tesis doctoral con corrupción numérica matemáticamente demostrada

- **Autora:** Norma Carolina Verdugo Rojas
- **Título:** *Embedding Spirituality into Organizational Decision-Making, A Study of Enabling Conditions for Spiritual Discernment*
- **Grado / Institución:** Tesis Doctoral, Facultad de Ciencias Económicas y Empresariales (ICADE), Universidad Pontificia Comillas (Madrid), 16 de octubre de 2026
- **Fuente:** `https://repositorio.comillas.edu/bitstreams/d7797d84-9447-4085-b51f-3a46f2292a74/download`
- **Tabla auditada:** Tabla 13 (*Robustness test*, p. 90; software declarado `SetMethods` en R, p. 80; protocolo Oana & Schneider, 2024, p. 89).

La Tabla 13 reporta:
- `RF_cov = 0.488`, `RF_cons = 0.952`, **`RF_SC_minTS = 0.548`**, `RF_SC_maxTS = 0.517`
- `RCR_Typ = 0.358`, `RCR_dev = 0.101`, `RCC_Rank = 4`
- `Performing models` (salida ordenada de `rob.singletest()`, que preserva los índices originales de `test_sol`):
  - `(2)` `PEOU*SI*A + PEOU*PWC*DC*SI` — `Rank: 4`, **`SC: 0.369`**
  - `(3)` `PEOU*PWC + PEOU*DC + PWC*DC*SI + PWC*~SI*~A` — `Rank: 4`, `SC: 0.481`
  - `(1)` `PEOU + PWC + DC` — `Rank: 2`, `SC: 0.573`

**Diagnóstico demostrado:**
1. Los índices `(2)`, `(3)`, `(1)` muestran una lista `test_sol` de **3 soluciones** en la que la especificación más severa y divergente (`SC = 0.369`) ocupó la **posición intermedia `(2)`**, que `rob.fit()` y `rob.evaluation()` omiten por completo.
2. En la Tabla 13 solo se variaron los anclajes de las 5 condiciones (`PEOU`, `PWC`, `DC`, `SI`, `A`), no del resultado (`PU`). Por el teorema anterior, el techo matemático absoluto para el verdadero `RF_SC_minTS` es:

$$0.488 \times 0.952 = \mathbf{0.4646} \quad (\text{con redondeo máximo: } 0.468)$$

3. El valor publicado (`0.548`) **supera su techo matemático en al menos `+0.083` puntos (una inflación relativa mínima del +18 %)**. Por la misma razón, `RCR_Typ = 0.358` y `RCR_dev = 0.101` también se calcularon excluyendo el modelo `(2)` y quedaron sesgados al alza.

### 2.2 Tesis con código R y datos completos auditados (evidencia directa del bloqueo de `rob.cases()`)

- **Autora:** Laura Stengl
- **Título:** *Transatlantic Sanctions Coherence in the Russia-Ukraine War: A Comparative Analysis of EU and U.S. Sanction Regimes*
- **Grado / Institución:** Bachelor's Thesis, Geschwister-Scholl-Institut für Politikwissenschaft, LMU Múnich (publicada en Open Access LMU, febrero de 2026)
- **Fuente:** `https://epub.ub.uni-muenchen.de/132027/1/Bachelorarbeit_Stengl.pdf`

**Diagnóstico demostrado:**
1. **Impacto directo de `rob.cases()` roto:** en la Tabla 12 (p. 38), la nota indica textualmente: *"detailed RCC case metrics are not reported due to software limitations."* Al replicar sus datos (Tablas 1 y 7, $N=9$, `csQCA`) y ejecutar `rob.cases(TS_Y2, IS_Y2, "Y2")` en `SetMethods 4.1`, la función aborta con `Incorrect expression, some set names do not have brackets.`
2. **Ejecución del bucle defectuoso sin alteración numérica por coincidencia:** en el Apéndice E (pp. 101–102) ejecuta `TS_Y2 <- list(TS1_Y2, TS2_Y2, TS3_Y2)` sobre `rob.fit()` y `rob.xyplot()`. `TS2_Y2` fue ignorada en silencio, pero al replicar los datos en R se verifica que las tres soluciones de prueba producen la misma fórmula (`X3`) cubriendo los mismos casos (`2, 3, 5`) que `IS_Y2` (`X2*X3`), por lo que sus cifras publicadas (`1, 1, 1, 1`) coincidieron por azar.

---

## 3. Causa raíz exacta de `rob.cases()` roto: regresión de *scoping* en `admisc::negate()` (`admisc >= 0.38`)

En reportes previos se había descartado la hipótesis inicial de `toupper()` (las soluciones de `PAYF` usan `~`, no minúsculas) y observado que `admisc::checkMV()` recibía fragmentos literales del código fuente (`'negate' 'emp1' 'snames=cond_names' ...`).

Inspeccionando el `ChangeLog` y el código fuente de `admisc 0.40` se confirma la **causa raíz exacta**:

1. En **`admisc 0.38`** (posterior a `SetMethods 4.1`, publicado en marzo de 2025), `negate()` fue renombrada a `invert()` y quedó como un envoltorio trivial:
   ```r
   admisc::negate <- function(...) {
       invert(...)
   }
   ```
2. `admisc::invert()` invoca `recreate(substitute(input))` y `recreate(substitute(snames))`, y `admisc::recreate()` evalúa las expresiones en `envir = parent.frame(n = 2)` (línea 116).
3. Cuando se llama a `invert(x_local, snames = cn_local)` dentro de una función, `parent.frame(n = 2)` es esa función y la evaluación **funciona**. Cuando se llama a `negate(x_local, snames = cn_local)` (como hace `SetMethods:::robust.intersections()` en las líneas 84–99), la capa intermedia de `negate()` desplaza `parent.frame(n = 2)` al frame interno de `negate()`, donde no existen `emp1`, `emp2` ni `cond_names`. `recreate()` atrapa el error y convierte `"emp1"` en cadena literal, lo que dispara `Unkown condition(s) in the expression.`
4. Al estar `negate(...)` anidado dentro de `intersection(...)`, el `tryCatch` de `recreate()` dentro de `intersection()` captura ese fallo y convierte toda la llamada `"negate(emp1, snames = cond_names, simplify = FALSE)[[1]][1]"` en texto literal, que `admisc::checkMV()` rechaza con `Incorrect expression, some set names do not have brackets.`
5. El ejemplo oficial de `?rob.cases` está envuelto en `\dontrun{}`, por lo que `R CMD check` en CRAN no detectó la rotura.

**Corrección:** arreglar el *scoping* del wrapper `admisc::negate()` en `admisc` (o migrar `SetMethods:::robust.intersections()` de `negate()` a `invert()` y pre-evaluar los argumentos antes de pasarlos a `intersection()`).

---

## 4. Causa raíz exacta de `rob.ncutrange()` con `max.runs` bajo

En `SetMethods::rob.ncutrange()`, la línea 57 —dentro del barrido **superior** (`n.cut.tu = n.cut.tu + step`)— dice:

```r
n.cut.tu = n.cut
while (setequal(is, s)) {
    n.cut.tu = n.cut.tu + step
    if (n.cut.tl == nrow(data)) {   # <- variable equivocada (límite inferior)
        break
    }
```

Se trata de un error de copiar y pegar el nombre de variable (`n.cut.tl` en lugar de `n.cut.tu`). Cuando el barrido inferior agota `max.runs` y asigna `n.cut.tl = NA` (línea 38), la línea 57 evalúa `if (NA == nrow(data))` y aborta. Además, incluso sin `NA`, el límite superior nunca se compara contra `nrow(data)`. La corrección real es `if (n.cut.tu >= nrow(data))`, no un parche `!is.na(n.cut.tl)`.

---

## 5. `esa()` frente a `QCA::minimize()`

Documentado en [`docs/referencias/esa-minimize-reprex.R`](referencias/esa-minimize-reprex.R) y [`docs/referencias/qca-minimize-ncut-reprex.R`](referencias/qca-minimize-ncut-reprex.R) (confirmado en [dusadrian/QCA#4](https://github.com/dusadrian/QCA/issues/4)): `esa()` excluye filas escribiendo directamente `TT$tt[..., "OUT"] <- 0` sin registrarlas en `TT$call`. Si se invoca después `QCA::minimize(newtt, ...)` pasando cualquier argumento de `truthTable()` (`incl.cut`, `n.cut`, `pri.cut`, etc., aunque con el mismo valor original), `minimize()` reconstruye la tabla desde `initial.data` sin emitir aviso y descarta todas las exclusiones de `esa()`.

---

## 6. Impacto sobre `calibraqca`

El calibrador **no está afectado** por ninguno de estos defectos:
- `pkg/calibraqca/R/robustez.R` llama a `SetMethods::rob.fit()` con un único objeto de solución por iteración (no una lista), evitando la rama del bucle defectuoso, y no usa `rob.cases()` ni `rob.ncutrange()`.
- `pkg/calibraqca/R/analisis.R` protege las exclusiones frente a la reconstrucción de `QCA::minimize()`.
