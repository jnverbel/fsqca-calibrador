# Plan 03 — Análisis, robustez y exportación (pasos 6, 7 y 8)

> **Para trabajadores agénticos:** SUB-SKILL REQUERIDA: `superpowers:subagent-driven-development`
> o `superpowers:executing-plans`.

**Objetivo:** de la matriz calibrada a las tres soluciones con su ajuste, el barrido de
robustez y los cuatro artefactos de exportación.

**Arquitectura:** todo el cálculo lo hacen `QCA`, `SetMethods` y `NCA`. El motor decide
umbrales, traduce resultados a alertas y arma el rastro para el informe.

**Depende de los planes 01 y 02** (alertas, compuertas, calibración, semáforo, proyecto).

## Restricciones globales

Rigen las de los planes anteriores, y además:

- **`tt$tt$incl` y `tt$tt$PRI` son `character`, no numéricos**, y las filas no observadas
  traen `"-"`. Verificado contra `QCA` 3.25. Comparar sin convertir es un **bug silencioso**:
  `"-" < "0.7"` es `TRUE`, así que sobre el ejemplo de Lipset la comparación de strings
  marca 30 de 32 filas con "PRI bajo" cuando en realidad son 7. Toda lectura de la tabla de
  verdad pasa por `as.numeric()` **y** por el filtro de filas observadas.
- **El PRI no es opcional.** Se calcula y se muestra siempre, y una configuración que pase
  el umbral de consistencia pero no el de PRI se marca en rojo.
- **Se producen las tres soluciones** — conservadora, intermedia y parsimoniosa —, porque
  presentar solo una es una de las observaciones habituales de los evaluadores.

## Firmas verificadas (2026-07-30, contra los paquetes instalados)

```
QCA 3.25
  truthTable(data, outcome, conditions, incl.cut, n.cut, pri.cut, exclude, complete,
             use.letters, use.labels, show.cases, dcc, sort.by, inf.test, ...)
  minimize(input, include, dir.exp, details, pi.cons, sol.cons, all.sol, row.dom,
           first.min, max.comb, use.labels, method, ...)
  pof(setms, outcome, data, relation, use.labels, inf.test, incl.cut, add, ...)
  superSubset(data, outcome, conditions, relation, incl.cut, cov.cut, ron.cut,
              pri.cut, depth, use.letters, use.labels, add, ...)

  pof(..., relation = "necessity")$incl.cov  -> data.frame(inclN, RoN, covN)
  truthTable(...)$tt                         -> data.frame(<condiciones>, OUT, n, incl, PRI, cases)
                                                OUT/incl/PRI son character; "?" y "-" para no observadas
  minimize(...)$solution                     -> lista de vectores de terminos
  minimize(...)$IC$incl.cov                  -> data.frame(inclS, PRI, covS, covU, cases)
  minimize(...)$IC$sol.incl.cov              -> data.frame(inclS, PRI, covS) de la solucion

SetMethods 4.1 — familia rob.* (ver docs/especificacion.md, paso 7)
NCA 5.0.2
  nca_analysis(data, x, y, ceilings, ...)$summaries[[i]]$params -> matriz con
    "Effect size" y "p-value" como nombres de fila
```

---

## Tarea 1: Necesidad (paso 6, primera parte)

**Archivos:** crear `R/analisis.R` y `tests/testthat/test-necesidad.R`.

**Interfaces:**
- `analizar_necesidad(membresias, resultado, condiciones)` → `data.frame(condicion, consistencia, ron, cobertura)`.
- `necesidad_trivial(consistencia, ron)` → `logical(1)`.
- Constantes: `NECESIDAD_CONSISTENCIA <- 0.90`, `RON_MINIMO <- 0.60`.

**Por qué RoN.** Una condición necesaria trivial tiene consistencia alta y cobertura de
relevancia baja: está presente en casi todos los casos, tenga o no el resultado. Reportar
solo la consistencia es el error clásico.

- [ ] Prueba: `analizar_necesidad` coincide con `QCA::pof(relation = "necessity")` sobre
  `LF`, columna a columna, tolerancia `1e-9`.
- [ ] Prueba: `A-27 se dispara` con consistencia 0,95 y RoN 0,40; `A-27 no se dispara` con
  consistencia 0,95 y RoN 0,80 ni con consistencia 0,60 y RoN 0,40.
- [ ] Prueba de límite de `necesidad_trivial()` en 0,90 y 0,60 exactos.
- [ ] Mutaciones: `NECESIDAD_CONSISTENCIA` 0,90 → 0,50 y `RON_MINIMO` 0,60 → 0,10.

---

## Tarea 2: Tabla de verdad y PRI (paso 6, segunda parte)

**Interfaces:**
- `umbral_frecuencia(n_casos)` → `integer(1)`.
- `construir_tabla_verdad(membresias, resultado, condiciones, umbrales)` → objeto `QCA_tt`.
- `leer_tabla_verdad(tt)` → `data.frame` **con `incl` y `PRI` numéricos** y solo filas
  observadas.
- `pri_insuficiente(incl, pri)` → `logical(1)`.
- Constantes: `FRECUENCIA_PEQUENA <- 2`, `FRECUENCIA_GRANDE <- 3`,
  `LIMITE_MUESTRA_PEQUENA <- 50`, `CONSISTENCIA_MINIMA <- 0.80`, `PRI_MINIMO <- 0.70`,
  `PROPORCION_DEGENERADA <- 0.80`, `CONSISTENCIA_CONTRADICCION <- 0.50`.

- [ ] **Prueba antibug obligatoria:** `leer_tabla_verdad()` devuelve `incl` y `PRI` de tipo
  `numeric` y **cero** filas con `OUT == "?"`. Sin ella, el `"-"` se cuela.
- [ ] `A-26 se dispara` con una fila de consistencia 0,85 y PRI 0,65; `A-26 no se dispara`
  con PRI 0,75.
- [ ] `A-28 se dispara` cuando más del 80 % de las filas observadas tienen `OUT == 1`;
  `A-28 no se dispara` con reparto normal.
- [ ] `A-30 se dispara` con filas de consistencia entre 0,50 y el umbral; `A-30 no se
  dispara` sin ellas.
- [ ] `umbral_frecuencia(50)` es 2 y `umbral_frecuencia(51)` es 3 — el límite exacto.
- [ ] Mutaciones: las siete constantes.

---

## Tarea 3: Minimización y las tres soluciones

**Interfaces:**
- `minimizar(tt, expectativas = NULL)` → `list(conservadora, intermedia, parsimoniosa)`,
  cada una con `terminos`, `ajuste` y `configuraciones`.
- `cobertura_baja(cobertura)` → `logical(1)`. Constante `COBERTURA_MINIMA <- 0.50`.

- [ ] Prueba: sobre `LF` las tres soluciones coinciden con `QCA::minimize` llamado
  directamente (`include = "?"` para la parsimoniosa, `dir.exp` para la intermedia).
- [ ] Prueba: la parsimoniosa nunca tiene más términos que la conservadora.
- [ ] `A-29 se dispara` con cobertura 0,40; `A-29 no se dispara` con 0,60.
- [ ] Mutación de `COBERTURA_MINIMA`.

---

## Tarea 4: NCA

**Interfaces:** `analizar_nca(membresias, condiciones, resultado)` →
`data.frame(condicion, tamano_efecto, p_valor)`. Sin alerta propia: complementa la necesidad.

- [ ] Prueba: coincide con `NCA::nca_analysis` sobre `LF` y devuelve una fila por condición.
- [ ] Prueba: si `NCA` falla, el paso lo declara y sigue, en vez de abortar el análisis.

---

## Tarea 5: Robustez (paso 7)

**Interfaces:**
- `escenarios_anclas(anclas, desplazamientos = c(-0.5, -0.25, 0.25, 0.5))` → `list`.
- `barrer_robustez(casos, anclas, ...)` → `data.frame` por escenario con configuraciones
  mantenidas, ajuste y casos que cambian de estatus.
- `solucion_robusta(mantenidas, total)` → `logical(1)`.
- Constante: `MINIMO_ESCENARIOS <- 2`.

Se apoya en `SetMethods`: `rob.calibrange` para el barrido de anclas, `rob.inclrange` y
`rob.ncutrange` para los umbrales, `rob.fit` y `rob.cases` para la comparación.

- [ ] `A-31 se dispara` cuando una configuración desaparece en algún escenario;
  `A-31 no se dispara` si todas se mantienen.
- [ ] `A-32 se dispara` con `A-15` activa y robustez sin ejecutar; `A-32 no se dispara`
  si se ejecutó o si las anclas no son muestrales.
- [ ] Prueba: se ejecutan al menos dos juegos alternativos de anclas.

---

## Tarea 6: Exportación (paso 8)

**Interfaces:**
- `tabla_calibracion(anclas_por_condicion)` → `data.frame` lista para el anexo.
- `exportar_base_calibrada(membresias, ruta)`.
- `guion_reproducible(proyecto, ruta_datos)` → `character` con el script de R.

- [ ] Prueba: la tabla de calibración trae una fila por condición con anclas, fuente y
  **la justificación íntegra, sin recortar**.
- [ ] Prueba: el guion generado **corre en una sesión limpia** (`callr::r`) y produce los
  mismos números que el análisis.
- [ ] Prueba: el guion incluye `idm` y los umbrales como literales comentados.

---

## Tarea 7: Cierre

- [ ] Retirar el `skip` del catálogo: las 32 alertas con sus dos casos.
- [ ] Flujo completo `limpia.csv` → informe, con la bitácora entera.
- [ ] Actualizar la tabla de mutaciones de la especificación.
