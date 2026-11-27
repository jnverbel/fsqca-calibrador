# Auditoría técnica de `SetMethods` 4.1 (y `admisc` 0.40): evidencia en código fuente, artículos revisados por pares y tesis publicadas

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
>    systematic optimistic bias ($\text{RCR}_{\text{bug}} \ge \text{RCR}_{\text{true}}$ always;
>    shaky and possible cases undercounted). Because `RF_cov` and `RF_cons` come from
>    `rob.corefit()` (whose loop `for (i in 2:length(all_sols))` is correct), any published
>    table where `RF_SC_minTS > RF_cov * RF_cons + 0.003` (without altering the outcome
>    calibration) violates an exact algebraic ceiling and proves silent corruption without
>    needing raw data.
> 2. **Empirical audit of 8 open-access published studies (2024–2026) from OpenAlex (7
>    peer-reviewed articles + 1 PhD dissertation), plus 1 open-access thesis with full R code:**
>    **3 mathematically confirmed violations** (+ 1 probable violation):
>    - *Paykani & Oana (2024, BMC Public Health, 24:2400, co-authored by the `SetMethods`
>      maintainer herself)*: 3 test solutions altering only `incl.cut` and two conditions
>      (outcome unchanged); Table 6 (p. 8) reports `RF_cov = 0.935`, `RF_cons = 0.878`
>      (ceiling `0.8209`), yet `RF_SC_minTS = 0.884` (`+0.0631`, `+7.7 %` relative inflation
>      over the point ceiling; at least `+7.2 %` under worst-case bilateral rounding), along
>      with `RCR_typ = 1`, `RCC_Rank = 3`, and Figure 1 (`rob.xyplot()`).
>    - *Holstead, Pakizer, Jager, Lieberherr, & Fischer (2026, Environmental Policy and
>      Governance, Wiley)*: 5 test solutions altering only three `incl.cut` values and two
>      conditions (outcome unchanged); Table A1 (p. 827) reports `RF_cov = 0.69`,
>      `RF_cons = 0.86` (ceiling `0.5934`), yet `RF_SC_minTS = 0.73` (`+0.1366`, `+23.0 %`
>      over the point ceiling; at least `+20.6 %` under worst-case bilateral 2-decimal rounding).
>    - *Verdugo Rojas (2026, Universidad Pontificia Comillas — ICADE, PhD dissertation,
>      Table 13, p. 90)*: 3 test solutions (`rob.singletest()` indices `(2)`, `(3)`, `(1)`)
>      with the strictest model (`SC = 0.369`) in middle position `(2)` and outcome unchanged;
>      reports `RF_cov = 0.488`, `RF_cons = 0.952` (ceiling `0.4646`), yet
>      `RF_SC_minTS = 0.548` (`+0.0834`, `+18.0 %` over the point ceiling; at least `+17.0 %`
>      under worst-case rounding).
>    - *Pérez-Macías, Medina Molina, & Coronado Vaca (2024, Transformations in Business &
>      Economics)*: 3 test solutions; `BIK` reports `RF_cov = 0.560`, `RF_cons = 0.929`
>      (ceiling `0.5202`), `RF_SC_minTS = 0.577` (`+0.0568`, `+10.9 %`) — classified as
>      probable pending confirmation of list order because models 2–3 recalibrated variables
>      with 90/10 percentiles.
>    - *Stengl (2026, LMU Munich, Bachelor's thesis, Table 12, p. 38 & Appendix E, pp. 101–102)*:
>      passed 3 test solutions `list(TS1_Y2, TS2_Y2, TS3_Y2)` into `rob.fit()` and
>      `rob.xyplot()` (figures survived only because all three yielded the same formula `X3`),
>      and explicitly omitted detailed `rob.cases()` metrics *"due to software limitations"*,
>      matching the `rob.cases()` crash reproduced on her dataset.
> 3. **Exact root cause of `rob.cases()` failure (`admisc >= 0.38`):** `admisc::negate()` became
>    a wrapper `function(...) invert(...)` in `admisc 0.38`, shifting `admisc::recreate()`'s
>    `parent.frame(n = 2)` lookup away from the caller (`SetMethods:::robust.intersections()`).
> 4. **Exact root cause of `rob.ncutrange()` abort:** line 57 checks the wrong variable
>    (`if (n.cut.tl == nrow(data))` instead of `n.cut.tu`) inside the upper sweep.
> 5. **Additional defects:** `robust.rank()` line 52 contains `P[, 1] > -P[, 2]` instead of
>    `P[, 1] >= P[, 2]`; `esa()` modifies `TT$tt[..., "OUT"] <- 0` directly without updating
>    `TT$call`, so `QCA::minimize()` silently discards the exclusions whenever passed any
>    `truthTable()` argument.
>
> **Notice:** Prior reports were sent twice by email to the `SetMethods` maintainer without
> response, and a public issue (`nenaoana/SetMethods#1`) remains open with no reply.
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
| `robust.intersections()` | Interna (usada por `rob.cases()`) | L42 (`test_int`) | Intersección booleana teórica `minTS` (latente hoy tras el fallo de `rob.cases()`, y además trunca `s2` multidisyuntivo al hacer `test_int[1]` sin colapsar con `+`). |
| `robust.rank()` | Interna | L5 (`P2`) y L16 (`P3`) | Rango de robustez (llamada sin retorno en `rob.fit()` L44). Además, en **L52** contiene otro typo: `P[, 1] > -P[, 2]` en vez de `P[, 1] >= P[, 2]`. |

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
| *Bucle parcheado* en `list(A, M2, Z)` | 0.887 | 0.963 | **0.855** | **0.730** | **0.185** | — |

### 1.3 Sesgo sistemáticamente optimista y desigualdad detectora para literatura publicada

Al omitir las soluciones intermedias, para todo caso $i$:

$$\text{minTS}_{\text{bug}}(i) \ge \text{minTS}_{\text{real}}(i), \qquad \text{maxTS}_{\text{bug}}(i) \le \text{maxTS}_{\text{real}}(i)$$

Consecuencias matemáticas garantizadas:
1. Los casos *shaky* ($IS > 0.5 \land \text{minTS} < 0.5$) y *possible* ($IS < 0.5 \land \text{maxTS} > 0.5$) quedan siempre **iguales o subestimados**; los casos *robust* quedan **iguales o sobreestimados**.
2. Como $\text{Robust} + \text{Shaky}$ depende únicamente de $IS$, el numerador de `RCR_typ` y `RCR_dev` sube o se mantiene y el denominador baja o se mantiene: **$\text{RCR}_{\text{bug}} \ge \text{RCR}_{\text{real}}$ siempre** (sesgo puramente optimista). `RCC_Rank` solo puede desplazarse hacia rangos artificialmente favorables.
3. **Teorema detector sobre tablas ya publicadas (sin necesitar los datos brutos):** en `rob.fit()`, `RF_cov = rcf[2] / isf[2]` y `RF_cons = isf[1] / rcf[1]`. Cuando `initial_sol` y `test_sol[[1]]` comparten la misma calibración del resultado $Y$, al multiplicar ambas cantidades se cancelan $\sum Y$, $\sum \min(\text{IS}, Y)$ y $\sum \min(\text{RC}, Y)$:

$$\text{RF\_cov} \times \text{RF\_cons} = \frac{\sum \min(\text{IS}, \text{minTS}_{\text{real}})}{\sum \text{IS}}$$

Y como $\sum \max(\text{IS}, \text{minTS}_{\text{real}}) \ge \sum \text{IS}$ para cualquier conjunto de datos:

$$\text{RF\_SC\_minTS}_{\text{real}} = \frac{\sum \min(\text{IS}, \text{minTS}_{\text{real}})}{\sum \max(\text{IS}, \text{minTS}_{\text{real}})} \le \text{RF\_cov} \times \text{RF\_cons}$$

*(Con un margen de redondeo máximo de $\approx 0.003$ a 3 decimales —o $\approx 0.01$ cuando el artículo redondea a 2 decimales— porque `QCAfit()` redondea consistencia y cobertura a 3 decimales antes del cociente.)*

En la prueba de mutación anterior con `PAYF`, el bug produce `RF_cov × RF_cons = 0.887 × 0.963 = 0.8542` frente a `RF_SC_minTS = 0.960`, violando el techo en `+0.106`.

---

## 2. Auditoría empírica de artículos revisados por pares y tesis publicadas (2024–2026)

Una consulta en OpenAlex (2021–2026) por `RF_SC_minTS`, `RF_SC_maxTS`, `RF_cov` + `RF_cons` + `minTS`, `RCR_typ` + `RF_cov` y `rob.fit` + `SetMethods` devolvió **19 trabajos únicos**, de los cuales **8** eran descargables en acceso abierto directo sin restricciones (**7 artículos revisados por pares + 1 tesis doctoral**). A ellos se suma una tesis adicional de grado con código R completo en el apéndice (Stengl, 2026).

### 2.1 Resumen del corpus auditado (8 estudios abiertos de OpenAlex)

| # | Estudio | Revista / Institución | Soluciones de prueba | ¿Alteró *outcome* $Y$? | `RF_cov` | `RF_cons` | Techo (`RF_cov × RF_cons`) | `RF_SC_minTS` publicado | Veredicto |
|---|---|---|---:|---|---:|---:|---:|---:|---|
| **1** | **Paykani & Oana (2024)** *(autora de `SetMethods`)* | *BMC Public Health*, 24:2400 (`10.1186/s12889-024-19594-4`, Tabla 6, p. 8) | **3** | **No** (solo `incl.cut` y 2 condiciones) | `0.935` | `0.878` | **`0.821`** | **`0.884`** | **VIOLACIÓN CONFIRMADA (`+0.063`, ≥ `+7,7 %`)** |
| **2** | **Holstead, Pakizer, Jager, Lieberherr, & Fischer (2026)** | *Environmental Policy and Governance*, Wiley (`10.1002/eet.70069`, Tabla A1, p. 827) | **5** | **No** (3 cortes `incl.cut` + 2 condiciones) | `0.69` | `0.86` | **`0.593`** | **`0.73`** | **VIOLACIÓN CONFIRMADA (`+0.137`, ≥ `+23,0 %`)** |
| **3** | **Verdugo Rojas (2026)** | Tesis Doctoral, ICADE — Univ. Pontificia Comillas (Tabla 13, p. 90) | **3** | **No** (solo 5 condiciones + cortes) | `0.488` | `0.952` | **`0.465`** | **`0.548`** | **VIOLACIÓN CONFIRMADA (`+0.083`, ≥ `+18,0 %`)** |
| **4** | **Pérez-Macías, Medina Molina, & Coronado Vaca (2024)** (`BIK`) | *Transformations in Business & Economics* (`10.15388/tibe.2024.36690`, p. 682) | **3** | Posible en modelos 2–3 (no en modelo 1) | `0.560` | `0.929` | **`0.520`** | **`0.577`** | **Violación probable (`+0.057`, `+10,9 %`)\*** |
| 5 | Zubizarreta Pagaldai, Marín, & Imaz Agirre (2025) | *Pixel-Bit*, 74 (`10.12795/pixelbit.116036`, Tabla C3) | 3 (idénticas) | No | `0.78` | `0.932` | `0.727` | `0.728` | Dentro de redondeo (`+0.001`) |
| 6 | Medina Molina, Pérez-Macías, & López-Sanz (2025) (`MESS` / `~MESS`) | *JOINETECH* (`10.65479/joinetech.17`) | No declarada | No | `0.907` / `0.610` | `0.993` / `0.926` | `0.901` / `0.565` | `0.901` / `0.448` | Cumple (`≤` techo) |
| 7 | Medina Molina, Rey-Tienda, Pérez-Macías, & Bilbao Calabuig (2026) | *JOINETECH* (`10.65479/joinetech.37`) | No declarada | No | `1.000` / `0.978` | `1.000` / `0.997` | `1.000` / `0.975` | `1.000` / `0.976` | Dentro de redondeo (`+0.001`) |
| 8 | Medina Molina, Pérez-Macías, & Rey-Tienda (2025) | *ESIC Market* (`10.7200/esicm.56.421`) | No declarada | No | `1.000` / `1.000` | `1.000` / `1.000` | `1.000` / `1.000` | `0.946` / `1.000` | Cumple (`≤` techo) |

*\*En el #4 (`BIK`), el modelo 1 conserva la calibración original de la solución inicial (percentiles 95/media/5), mientras que los modelos 2 y 3 recalibran con percentiles 90/media/10; sin acceder al orden exacto en `list(...)`, se clasifica con cautela como violación probable.*

### 2.2 Detalle de los tres casos matemáticamente confirmados

1. **Paykani & Oana (2024, *BMC Public Health*, 24:2400):** coescrito por la propia mantenedora de `SetMethods`. En la p. 8 declaran explícitamente haber creado **tres soluciones alternativas** modificando únicamente el umbral de consistencia y los anclajes de calibración de dos condiciones (*state capacity* y *trust in government*), sin modificar el resultado (mortalidad COVID-19). En la Tabla 6 publican `RF_cov = 0.935`, `RF_cons = 0.878` (techo puntual `0.8209`; con redondeo máximo `0.824`) y **`RF_SC_minTS = 0.884`** (`+0.0631`, inflación relativa de `+7,7 %` sobre el techo puntual; al menos `+7,2 %` bajo el peor redondeo bilateral). Sus métricas orientadas a casos (`RCR_typ = 1`, `RCR_dev = 0`, `RCC_Rank = 3`) y la Figura 1 (`rob.xyplot()`) también se generaron omitiendo la solución intermedia.
2. **Holstead, Pakizer, Jager, Lieberherr, & Fischer (2026, *Environmental Policy and Governance*, Wiley):** en el Apéndice 7 (p. 827) enumeran **cinco soluciones alternativas** (tres cortes de consistencia `0.88`, `0.90`, `0.80` y dos cambios en condiciones: `UNCERTAIN` y `WATER_STRESS`, sin tocar el resultado `SUCCESS`). El bucle defectuoso descartó las 3 soluciones intermedias: frente a un techo de `0.69 × 0.86 = 0.5934` (máximo con redondeo a 2 decimales `0.6012`), la Tabla A1 publica **`RF_SC_minTS = 0.73`** (`+0.1366`, inflación relativa de `+23,0 %` sobre el techo puntual; al menos `+20,6 %` bajo el peor redondeo bilateral a 2 decimales, `0.725` frente a `0.6012`).
3. **Verdugo Rojas (2026, Universidad Pontificia Comillas — ICADE, tesis doctoral, Tabla 13, p. 90):** `rob.singletest()` muestra los índices `(2)`, `(3)`, `(1)` de **3 soluciones** donde la más exigente (`PEOU*SI*A + PEOU*PWC*DC*SI`, `SC = 0.369`) ocupa la posición intermedia `(2)`, sin alterar el resultado `PU`. Frente al techo `0.488 × 0.952 = 0.4646` (`0.468` con redondeo), la Tabla 13 publica **`RF_SC_minTS = 0.548`** (`+0.0834`, inflación relativa de `+18,0 %` sobre el techo puntual; al menos `+17,0 %` bajo el peor redondeo), sesgando igualmente al alza `RCR_Typ = 0.358` y `RCR_dev = 0.101`.

### 2.3 Evidencia directa del bloqueo de `rob.cases()` en una tesis publicada

- **Stengl (2026, LMU Múnich, *Bachelor's Thesis*, `epub.ub.uni-muenchen.de/132027/1/Bachelorarbeit_Stengl.pdf`):**
  1. En la Tabla 12 (p. 38) omite las métricas detalladas de `rob.cases()` declarando textualmente *"due to software limitations"*. Al replicar sus datos (Tablas 1 y 7, $N=9$, `csQCA`), `rob.cases(TS_Y2, IS_Y2, "Y2")` aborta exactamente con `Incorrect expression, some set names do not have brackets.`
  2. En el Apéndice E (pp. 101–102) pasa `TS_Y2 <- list(TS1_Y2, TS2_Y2, TS3_Y2)` a `rob.fit()` y `rob.xyplot()`; `TS2_Y2` fue ignorada en silencio, pero sus cifras (`1, 1, 1, 1`) se salvaron porque las tres soluciones dieron la misma fórmula (`X3`) cubriendo los mismos casos (`2, 3, 5`) que `IS_Y2` (`X2*X3`).

---

## 3. Causa raíz exacta de `rob.cases()` roto: regresión de *scoping* en `admisc::negate()` (`admisc >= 0.38`)

Inspeccionando el `ChangeLog` y el código fuente de `admisc 0.40` se confirma la **causa raíz exacta** (descartando la antigua hipótesis no verificada de `toupper()`):

1. En **`admisc 0.38`** (posterior a `SetMethods 4.1`, publicado en marzo de 2025), `negate()` fue renombrada a `invert()` y quedó como un envoltorio trivial: `admisc::negate <- function(...) invert(...)`.
2. `admisc::invert()` invoca `recreate(substitute(input))` y `recreate(substitute(snames))`, y `admisc::recreate()` evalúa en `envir = parent.frame(n = 2)` (línea 116).
3. Dentro de una función local (`SetMethods:::robust.intersections()`), `invert()` funciona porque `parent.frame(n = 2)` es esa función, pero `negate()` desplaza `parent.frame(n = 2)` al frame interno de `negate()`, donde no existen `emp1`, `emp2` ni `cond_names`. `recreate()` atrapa el fallo y convierte la expresión en texto literal; al estar anidado en `intersection()`, el `tryCatch` de `intersection()` entrega literalmente el código fuente `"negate(emp1, snames = cond_names, ...)"` a `admisc::checkMV()`, que lo rechaza con `Incorrect expression, some set names do not have brackets.`
4. El ejemplo de `?rob.cases` está envuelto en `\dontrun{}`, por lo que `R CMD check` en CRAN no detectó la rotura.

---

## 4. Causa raíz exacta de `rob.ncutrange()` con `max.runs` bajo

En `SetMethods::rob.ncutrange()`, la línea 57 —dentro del barrido **superior** (`n.cut.tu = n.cut.tu + step`)— compara la variable equivocada (`if (n.cut.tl == nrow(data))` en lugar de `if (n.cut.tu >= nrow(data))`). Cuando el barrido inferior agota `max.runs` y asigna `n.cut.tl = NA` (línea 38), la línea 57 evalúa `if (NA == nrow(data))` y aborta. Además, incluso sin `NA`, la condición de parada del límite superior nunca se comprueba contra `nrow(data)`.

---

## 5. `esa()` frente a `QCA::minimize()`

Documentado en [`docs/referencias/esa-minimize-reprex.R`](referencias/esa-minimize-reprex.R) y [`docs/referencias/qca-minimize-ncut-reprex.R`](referencias/qca-minimize-ncut-reprex.R) (confirmado en [dusadrian/QCA#4](https://github.com/dusadrian/QCA/issues/4)): `esa()` excluye filas escribiendo directamente `TT$tt[..., "OUT"] <- 0` sin registrarlas en `TT$call`. Si se invoca después `QCA::minimize(newtt, ...)` pasando cualquier argumento de `truthTable()` (`incl.cut`, `n.cut`, `pri.cut`, etc.), `minimize()` reconstruye la tabla desde `initial.data` sin emitir aviso y descarta todas las exclusiones de `esa()`.

---

## 6. Impacto sobre `calibraqca`

El calibrador **no está afectado** por ninguno de estos defectos:
- `pkg/calibraqca/R/robustez.R` llama a `SetMethods::rob.fit()` con un único objeto de solución por iteración (no una lista), evitando la rama del bucle defectuoso, y no usa `rob.cases()` ni `rob.ncutrange()`.
- `pkg/calibraqca/R/analisis.R` protege las exclusiones frente a la reconstrucción de `QCA::minimize()`.
