# Especificación — Calibrador fsQCA para datos Likert

**Versión:** 1.0 · **Fecha:** 2026-07-30
**Estado:** diseño aprobado; sin código.
**Documento fuente:** `docs/referencias/Propuesta-herramienta-calibracion-fsQCA.pdf`

---

## 0. Marco

### 0.1. Qué es

Una aplicación guiada que lleva un archivo de respuestas Likert de 5 puntos hasta un
anexo metodológico listo para pegar en una tesis doctoral, pasando por validación de
medida, agregación, calibración difusa directa, análisis de necesidad y suficiencia,
minimización booleana y barrido de robustez.

### 0.2. Para quién

Un investigador doctoral externo, que **trabaja solo y no escribe R**. Su interacción se
limita a cargar un archivo, mover deslizadores, escribir justificaciones y leer
diagnósticos. Javier es el apoyo técnico: desarrolla, despliega y mantiene.

### 0.3. Qué NO es

- **No es un motor de cálculo.** No se reimplementa ninguna fórmula estadística que ya
  exista en un paquete revisado por pares. Todo cálculo se delega a `QCA`, `SetMethods`,
  `psych`, `lavaan` y `NCA`. Ante el jurado no se defiende código propio de dudosa
  procedencia.
- **No decide metodología.** No propone anclas ni las justifica. Exige que el
  investigador lo haga y deja constancia escrita de cada decisión.
- **No es la GUI de Dușa.** `QCA::runGUI()` ya existe y es un constructor de comandos
  sobre la sintaxis del paquete: sirve a quien ya sabe qué función llamar. El hueco real
  son los pasos 1 a 5 y el informe. COMPASSS lo dice explícitamente: no existe
  herramienta especializada en calibración de datos de encuesta.

### 0.4. Advertencia sobre `fuzzy_likert_5.R`

El archivo en `docs/referencias/` **es otra ruta metodológica**, no el punto de partida
del motor: implementa Delphi difuso con números triangulares para ponderar enunciados por
consenso de actores. De él se reutiliza **una sola idea**: el control de validez que
compara el orden difuso contra la media Likert simple con rho de Spearman y reporta con
honestidad cuando la fuzzificación no cambió nada. Ese control aparece aquí como la
alerta `A-13` del paso 4.

---

## 1. Arquitectura

### 1.1. Dos capas, frontera dura

```
┌─────────────────────────────────────────────────────┐
│  app/          Shiny — solo dibuja y recoge         │
│                Nunca calcula. Nunca decide.         │
└───────────────────────┬─────────────────────────────┘
                        │  llamadas a funciones puras
┌───────────────────────▼─────────────────────────────┐
│  pkg/calibraqca/   Paquete de R — funciones puras   │
│                    No sabe que Shiny existe.        │
│                    Envuelve QCA/psych/lavaan/NCA.   │
└─────────────────────────────────────────────────────┘
```

**La razón de la frontera:** poder probar el cálculo con `testthat` contra
`QCA::calibrate()` y contra los puntos que la fórmula obliga, sin simular la interfaz.
Una función del motor que reciba un `input$` de Shiny o que llame a `showNotification()`
es un defecto de diseño, no un atajo.

**Regla operativa:** ninguna función bajo `pkg/calibraqca/R/` puede referirse a `session`,
`input`, `output`, `reactive`, `observe` ni `req`. Hay una prueba que lo verifica por
`grep` sobre el código fuente del paquete (`test-frontera-shiny.R`).

### 1.2. Estado de la sesión

La app mantiene un único objeto de estado (`proyecto`), que es exactamente lo que se
serializa al archivo de proyecto JSON (sección 4). No hay estado escondido en variables
reactivas sueltas: si algo influye en un resultado, vive en `proyecto` y por tanto se
guarda y se imprime en el informe.

### 1.3. Dependencias y su papel

| Paquete | Para qué | Reimplementar sería |
|---|---|---|
| `QCA` (Dușa) | `calibrate()`, `truthTable()`, `minimize()`, `pof()`, `superSubset()` | riesgo metodológico inaceptable |
| `SetMethods` (Oana & Schneider) | protocolo de robustez publicado | inventar un protocolo propio sin cita |
| `psych` | alfa de Cronbach, ítem-total corregida, ICC | trivial pero no citable |
| `lavaan` | factorial confirmatorio (opcional) | absurdo |
| `NCA` (Dul) | análisis de condiciones necesarias | absurdo |
| `readxl` / `readr` | ingesta | — |
| `shiny`, `bslib` | interfaz | — |
| `quarto` | informe | — |
| `jsonlite` | archivo de proyecto | — |
| `digest` | huella SHA-256 del archivo de datos | — |

**`renv` con versiones bloqueadas es obligatorio.** Sin eso, la reproducibilidad que
promete el informe es falsa: un cambio de valor por defecto en `QCA` altera los
resultados numéricos.

⚠️ **A verificar contra la versión instalada antes de escribir el paso 7:** los nombres
exactos de las funciones de robustez de `SetMethods` (la familia `rob.*` de Oana &
Schneider). La especificación se compromete con *el protocolo publicado*, no con una
firma de función escrita de memoria. Primera tarea del paso 7: abrir la documentación
instalada y fijar las firmas reales.

---

## 2. El asistente: compuertas, no bloqueos

El flujo es un **asistente guiado con compuertas**, no un banco de trabajo con pestañas
libres. Se avanza paso a paso.

**La regla que hace que la compuerta no sea un defecto:**

> Cada alerta se cierra **resolviéndola o reconociéndola por escrito**, y ese texto sale
> impreso en el informe junto a la alerta.

Bloquear hasta "resolver" encerraría al investigador cuando el problema es real e
inevitable — el efecto techo en encuestas de capacidad innovadora autorreportada lo es a
menudo. **La compuerta no impide avanzar con un problema; impide avanzar en silencio.**

Estados de una alerta:

| Estado | Significado | ¿Deja avanzar? | ¿Sale en el informe? |
|---|---|---|---|
| `abierta` | disparada, sin atender | **No** | — |
| `resuelta` | el investigador cambió algo y dejó de dispararse | Sí | Sí, como incidencia superada |
| `reconocida` | sigue disparada; el investigador escribió por qué se acepta | Sí | Sí, **con el texto íntegro** |

Una alerta `reconocida` exige una nota de **al menos 40 caracteres**. No se acepta
"ok", "revisado" ni la cadena vacía. El límite es deliberadamente bajo: el objetivo es
impedir el clic reflejo, no redactar por el investigador.

Las alertas de severidad `informativa` no bloquean: se registran y se imprimen.

---

## 3. Los ocho pasos

Notación de cada paso: **entrada → cálculo (paquete envuelto) → diagnósticos → qué se
guarda en el proyecto**.

### Paso 1 — Ingesta

**Entrada:** un archivo CSV o Excel. Una fila por respuesta, una columna por ítem.

**Qué hace:**
- Detecta separador y codificación; muestra las primeras 15 filas tal como se leyeron,
  para que el investigador confirme con los ojos que el archivo se interpretó bien.
- Pide declarar: columna identificadora del caso, y **si hay uno o varios encuestados por
  caso**. La ingesta se construye genérica a propósito: acepta ambos y lee el número de
  condiciones del archivo, sin depender de las respuestas a las preguntas abiertas de la
  sección 9.
- **Mapeo de ítems a constructos**: una tabla editable ítem → constructo. Los constructos
  son las condiciones (y posiblemente el resultado) del análisis.
- Declara el rango de la escala (por defecto 1–5) y los códigos de no respuesta.
- Calcula y guarda la **huella SHA-256** del archivo, su número de filas y columnas, y los
  nombres de columna.

**Diagnósticos:**

| Cód. | Alerta | Disparo | Severidad |
|---|---|---|---|
| `A-01` | Valores fuera de escala | algún valor no está en 1..5 ni es NA | bloqueante |
| `A-02` | Ítems sin constructo | alguna columna numérica quedó sin mapear | bloqueante |
| `A-03` | Constructo con un solo ítem | `n_items == 1` | bloqueante |
| `A-04` | No respuesta abundante | > 10 % de NA en algún ítem | advertencia |
| `A-05` | Casos duplicados | el identificador se repite y se declaró un encuestado por caso | advertencia |

`A-03` merece explicación, porque es la primera línea de defensa del método: **un ítem
Likert de 5 puntos genera únicamente cinco valores posibles.** Calibrar sobre un ítem
individual produce empates masivos entre casos y deja las anclas sin margen de maniobra.
La solución es calibrar sobre el promedio de los ítems del constructo, lo que produce un
rango prácticamente continuo donde la calibración directa opera como fue diseñada. Si un
constructo tiene un solo ítem, esta herramienta no puede hacer nada honesto con él.

**Se guarda:** `datos.huella`, `datos.n_filas`, `datos.n_columnas`, `mapeo`, `escala`.
**Nunca se guardan los datos crudos.**

---

### Paso 2 — Validación de medida

**Entrada:** el mapeo del paso 1.

**Qué hace, por constructo:**
- **Alfa de Cronbach** (`psych::alpha`), con su intervalo de confianza.
- **Correlación ítem-total corregida** para cada ítem, y el alfa que resultaría *si se
  elimina el ítem*.
- **Factorial confirmatorio con `lavaan::cfa`, solo si la muestra da.** La regla se fija
  aquí y no se negocia en caliente: se ofrece el CFA si `n_casos ≥ 5 × n_parámetros
  libres` y `n_casos ≥ 100`. Si no se cumple, el paso **omite el CFA explicando por qué**,
  en vez de mostrar un modelo que no ajusta. Ese texto entra en el informe.

**Diagnósticos:**

| Cód. | Alerta | Disparo | Severidad |
|---|---|---|---|
| `A-06` | Fiabilidad insuficiente | alfa < 0,70 | bloqueante |
| `A-07` | Fiabilidad dudosa | 0,70 ≤ alfa < 0,80 | advertencia |
| `A-08` | Ítem que resta | ítem-total corregida < 0,30, o alfa-si-se-elimina > alfa actual | advertencia |
| `A-09` | Alfa inflado por número de ítems | alfa > 0,95 con ≥ 6 ítems (posible redundancia) | informativa |
| `A-10` | CFA omitido por muestra | no se cumple la regla de tamaño | informativa |

**Se guarda:** por constructo, alfa e IC, la tabla ítem-total, y el ajuste del CFA si se
ejecutó (χ², gl, CFI, TLI, RMSEA, SRMR).

---

### Paso 3 — Agregación

**Entrada:** datos validados.

**Qué hace:**
- Promedio de los ítems de cada constructo, por respuesta.
- **Si hay varios encuestados por caso**, la agregación de personas a caso exige
  justificación estadística, no basta con promediar: se calcula **ICC(1) e ICC(2)**
  (`psych::ICC`) y se reporta el número de encuestados por caso (mínimo, mediana, máximo).
- Manejo declarado de NA: promedio sobre ítems presentes si el constructo conserva al
  menos la mitad de sus ítems; en caso contrario el caso queda como NA en ese constructo y
  se informa.

**Diagnósticos:**

| Cód. | Alerta | Disparo | Severidad |
|---|---|---|---|
| `A-11` | Agregación multinivel sin respaldo | ICC(1) < 0,05 o ICC(2) < 0,70 | bloqueante |
| `A-12` | Casos con un solo encuestado | hay casos con `n = 1` cuando el diseño es multinivel | advertencia |

`A-11` es bloqueante en el sentido de la sección 2: se puede reconocer por escrito, pero
el reconocimiento queda impreso. Promediar respuestas de personas para representar una
empresa sin ICC que lo respalde es exactamente el tipo de decisión que un evaluador con
experiencia busca.

**Se guarda:** método de agregación, política de NA, ICC(1), ICC(2), distribución de
encuestados por caso.

---

### Paso 4 — Calibración interactiva

Este es el corazón de la herramienta.

**Entrada:** el promedio por constructo del paso 3.

**Qué hace:** calibración directa (Ragin, 2008) sobre el promedio de cada constructo, con
tres anclas. Valores de partida sugeridos para una escala de 5 puntos:

| Ancla | Valor en la escala | Pertenencia resultante |
|---|---|---|
| Pertenencia plena al conjunto | 4,0 | 0,95 |
| Punto de cruce (máxima ambigüedad) | 3,0 | 0,50 |
| No pertenencia plena | 2,0 | 0,05 |

Si se detecta efecto techo, las anclas se desplazan hacia arriba (4,5 / 3,5 / 2,5).

**La transformación es logística por tramos y es verificable a mano:**

```
si x > c   →   L = 2,944 · (x − c) / (θ_plena − c)
si x < c   →   L = 2,944 · (x − c) / (c − θ_nula)

pertenencia = e^L / (1 + e^L)
```

donde `c` es el punto de cruce y **2,944 es el logit de 0,95**, es decir, el grado de
inclusión que define la pertenencia plena.

**Nota de reproducibilidad que debe imprimirse en el informe:** la función
`QCA::calibrate()` parametriza ese grado de inclusión mediante el argumento `idm`, cuyo
valor por defecto es 0,95. Por esta razón puede haber diferencias en el tercer decimal
frente al programa fs/QCA de Ragin. **El parámetro `idm` se declara siempre**, con el
valor efectivamente usado.

**Interfaz:** tres deslizadores por condición, con retroalimentación visual inmediata:
- histograma crudo del promedio, con las tres anclas dibujadas encima;
- distribución de la pertenencia calibrada;
- curva logística superpuesta;
- contador en vivo: `% de casos > 0,50`, `% en 0,50 exacto`, mínimo y máximo de la
  membresía.

**Campo obligatorio por condición: la fuente y la justificación del ancla.** La fuente es
una lista cerrada — `teoría`, `normativa sectorial`, `referencia de desempeño`,
`conocimiento sustantivo de los casos`, `panel de expertos`, `distribución muestral` — y
la justificación es texto libre obligatorio. No se puede pasar del paso 4 con una
condición sin justificar.

**Advertencia sobre calibración por percentiles.** Si la fuente elegida es `distribución
muestral`, la app muestra sin negociación: *fijar las anclas con percentiles de la propia
muestra (95/50/5 u 80/50/20) es la salida más rápida y la más cuestionada: hace que la
calibración dependa de la muestra y no del concepto teórico. Es admisible únicamente como
último recurso y siempre acompañada de un análisis de sensibilidad.* Elegirla marca el
paso 7 (robustez) como **obligatorio, no opcional**.

**Corrección del 0,50 exacto.** Todo caso con pertenencia exactamente igual a 0,50 queda
excluido de los análisis de necesidad y de suficiencia. La corrección estándar consiste en
sumar 0,001 a esos valores. La app la aplica, **la declara en pantalla y la imprime en el
informe**, con el listado de los casos afectados.

Conviene no confundir dos problemas distintos con el punto medio:
- **Analítico**: el 0,50 exacto se excluye del análisis. Se corrige con +0,001.
- **Conceptual**: en una escala Likert, el punto medio puede significar indiferencia,
  ambivalencia o desconocimiento. En teoría de conjuntos difusos, 0,50 significa *máxima
  ambigüedad respecto de la pertenencia al conjunto*. No son equivalentes, y tratarlos como
  tales exige un argumento sustantivo, no una nota al pie. La app pide ese argumento como
  parte de la justificación del punto de cruce.

**Diagnósticos:**

| Cód. | Alerta | Disparo | Severidad |
|---|---|---|---|
| `A-13` | La calibración no reordenó | rho de Spearman entre membresía y promedio crudo ≈ 1 y ningún caso cambia de rango | informativa |
| `A-14` | Ancla sin justificación | falta fuente o texto | bloqueante |
| `A-15` | Anclas por percentiles | fuente = `distribución muestral` | advertencia + obliga paso 7 |
| `A-16` | Anclas no monótonas | no se cumple `θ_nula < c < θ_plena` | bloqueante |
| `A-17` | Casos en 0,50 exacto | existe al menos uno antes de la corrección | informativa (se corrige e informa) |

`A-13` es la idea rescatada de `fuzzy_likert_5.R`: si el orden no cambió, la calibración no
inventó información. Eso **no invalida el método** — su aporte es el umbral formal y la
interpretación de conjuntos — pero hay que reportarlo con honestidad en lugar de vender un
orden "nuevo".

**Se guarda:** por condición, las tres anclas, la fuente, la justificación, `idm`, si se
aplicó la corrección de 0,001 y a qué casos.

---

### Paso 5 — Semáforo de diagnóstico

**Entrada:** la matriz calibrada completa.

Este paso no calcula nada nuevo: **lee la matriz calibrada y decide si el análisis del
paso 6 tiene sentido.** Es el paso que la propuesta identifica como el que debe ejecutarse
*antes* del análisis, no después.

| Cód. | Alerta | Disparo | Severidad |
|---|---|---|---|
| `A-18` | **Efecto techo** | > 85 % de los casos supera 0,50 en una condición | bloqueante |
| `A-19` | **Efecto piso** | > 85 % de los casos queda bajo 0,50 en una condición | bloqueante |
| `A-20` | **Condición que no discrimina** | desviación típica de la membresía < 0,15 | bloqueante |
| `A-21` | **Asimetría fuerte** | \|asimetría\| > 2 en la membresía calibrada | advertencia |
| `A-22` | **Membresías idénticas entre casos** | dos o más casos con vector de membresía idéntico en todas las condiciones | advertencia |
| `A-23` | **Diversidad limitada** | `n_casos < 2^n_condiciones / 4` | informativa |
| `A-24` | **Correlación alta entre condiciones** | \|r\| > 0,80 entre dos condiciones calibradas | advertencia |
| `A-25` | **Sesgo de método común** | el resultado es autorreportado y proviene del mismo cuestionario | advertencia |

Sobre `A-18`: las encuestas autorreportadas sobre capacidad innovadora tienden a
concentrar las respuestas en 4 y 5. Si tras calibrar más del 85 % de los casos supera 0,50
en una condición, esa condición deja de discriminar y **la tabla de verdad resultante es
degenerada**. El paso ofrece dos salidas: volver al paso 4 y desplazar las anclas (4,5 /
3,5 / 2,5), o reconocer el efecto por escrito. Ambas quedan en el informe.

Sobre `A-25`: se dispara por declaración, no por cálculo — el paso 1 pregunta si el
resultado sale del mismo cuestionario. Si es así, la recomendación impresa es incorporar
una prueba de sesgo de método común al capítulo metodológico.

**Se guarda:** la lista completa de alertas disparadas con su estado y su nota de cierre.

---

### Paso 6 — Análisis

**Entrada:** la matriz calibrada, ya pasada por el semáforo.

**Qué hace, en este orden:**

1. **Necesidad.** `QCA::superSubset()` y `QCA::pof()` para condiciones individuales y sus
   negaciones. Se reportan consistencia y **cobertura de relevancia (RoN)**, porque una
   condición necesaria trivial tiene consistencia alta y RoN baja.
2. **Tabla de verdad.** `QCA::truthTable()` con los umbrales declarados.
3. **Suficiencia y minimización booleana.** `QCA::minimize()`, produciendo las **tres
   soluciones** — conservadora (compleja), intermedia y parsimoniosa — porque presentar
   solo una es una de las observaciones habituales de los evaluadores. Para la intermedia
   se piden las expectativas direccionales, condición por condición.
4. **NCA** (`NCA::nca_analysis`) como complemento. Refuerza el argumento de necesidad con
   poco trabajo adicional.

**Umbrales, con sus valores por defecto y su justificación impresa:**

| Umbral | Por defecto | Regla |
|---|---|---|
| Frecuencia mínima | 2 si `n_casos ≤ 50`, si no 3 | muestra pequeña vs. grande |
| Consistencia | 0,80 | mínimo convencional |
| **Consistencia PRI** | **0,70** | se omite con frecuencia y es el que evita relaciones de subconjunto simultáneas |

El PRI no es opcional en esta herramienta: se calcula y se muestra siempre, y una
configuración que pase el umbral de consistencia pero no el de PRI se marca en rojo en la
tabla de verdad.

**Diagnósticos:**

| Cód. | Alerta | Disparo | Severidad |
|---|---|---|---|
| `A-26` | Configuraciones con PRI bajo | alguna fila con consistencia ≥ 0,80 y PRI < 0,70 | bloqueante |
| `A-27` | Necesidad trivial | consistencia ≥ 0,90 pero RoN < 0,60 | advertencia |
| `A-28` | Tabla de verdad degenerada | > 80 % de las filas observadas con resultado 1 | bloqueante |
| `A-29` | Solución con cobertura baja | cobertura de solución < 0,50 | advertencia |
| `A-30` | Contradicciones lógicas | filas con consistencia entre 0,50 y el umbral | informativa |

**Se guarda:** umbrales usados, expectativas direccionales, las tres soluciones con sus
parámetros de ajuste, resultados de necesidad y de NCA.

---

### Paso 7 — Robustez

**Entrada:** el análisis del paso 6 y las anclas del paso 4.

**Qué hace:** ejecuta automáticamente **múltiples escenarios de anclas** y compara las
soluciones obtenidas, para demostrar que los resultados no dependen de una calibración
particular. Como mínimo dos juegos alternativos de anclas, más los desplazamientos
sistemáticos de ±0,25 y ±0,50 sobre cada ancla.

**El protocolo se apoya en las funciones ya publicadas de `SetMethods`** (Oana y
Schneider), no en una ocurrencia propia. Esto es una restricción de diseño, no una
preferencia: el objetivo es que el capítulo de robustez tenga referencia bibliográfica.

Se reporta, para cada escenario:
- si las configuraciones de la solución se mantienen;
- el ajuste (consistencia y cobertura) de cada una;
- qué casos cambian de estatus (típicos, desviados por consistencia, desviados por
  cobertura);
- una matriz de coincidencia entre la solución original y cada alternativa.

También se barren los umbrales: frecuencia ∈ {1, 2, 3} y consistencia ∈ {0,75; 0,80;
0,85}.

**Este paso es obligatorio si el paso 4 registró `A-15`** (anclas por distribución
muestral). En cualquier otro caso es recomendado y se puede omitir reconociéndolo por
escrito.

| Cód. | Alerta | Disparo | Severidad |
|---|---|---|---|
| `A-31` | Solución no robusta | alguna configuración desaparece en ≥ 1 escenario | advertencia |
| `A-32` | Robustez omitida con anclas muestrales | `A-15` activa y paso 7 sin ejecutar | bloqueante |

**Se guarda:** los escenarios ejecutados y su comparación completa.

---

### Paso 8 — Exportación

**Entrada:** el proyecto completo.

**Produce cuatro artefactos:**

1. **Tabla de calibración lista para el anexo**, con las anclas y su justificación fila
   por fila. Es lo primero que revisa un evaluador con experiencia en el método.
2. **Base de datos calibrada** (CSV) — casos × condiciones, con las membresías.
3. **Informe reproducible** en **HTML y Word** (el investigador necesita pegar texto en la
   tesis).
4. **Script de R que reproduce todo desde el archivo crudo**, ejecutable y verificable por
   el jurado.

Detalle en la sección 5.

---

## 4. El archivo de proyecto

**Formato JSON, no RDS.** Un RDS es opaco: no se puede leer, ni versionar en git, ni abrir
dentro de diez años sin R. El archivo de proyecto es el rastro documental de las decisiones
metodológicas, y por tanto debe ser legible por un humano.

**No guarda datos crudos. El servidor no persiste nada.** El investigador descarga el
archivo y lo vuelve a subir cuando retoma.

### 4.1. Esquema

```json
{
  "version_esquema": "1.0",
  "version_app": "0.1.0",
  "creado": "2026-07-30T14:22:11Z",
  "modificado": "2026-07-30T18:03:55Z",

  "datos": {
    "nombre_archivo": "encuesta_innovacion.xlsx",
    "huella_sha256": "9f2c…",
    "n_filas": 214,
    "n_columnas": 37,
    "nombres_columnas": ["id_empresa", "IT01", "IT02", "…"],
    "escala": { "min": 1, "max": 5, "codigos_na": [99] },
    "resultado_autorreportado_mismo_cuestionario": true
  },

  "mapeo": {
    "unidad_analisis": "empresa",
    "columna_id": "id_empresa",
    "encuestados_por_caso": "varios",
    "constructos": [
      { "nombre": "CAP_ABS", "rol": "condicion", "items": ["IT01", "IT02", "IT03"] },
      { "nombre": "INNOV",   "rol": "resultado", "items": ["RS01", "RS02"] }
    ]
  },

  "validacion": {
    "CAP_ABS": {
      "alfa": 0.842, "alfa_ic": [0.79, 0.88],
      "item_total": { "IT01": 0.71, "IT02": 0.68, "IT03": 0.55 },
      "cfa": { "ejecutado": false, "motivo_omision": "n = 214 < 5 × 48 parámetros libres" }
    }
  },

  "agregacion": {
    "metodo": "promedio de items",
    "politica_na": "promedia si conserva >= 50% de los items",
    "icc1": 0.21, "icc2": 0.78,
    "encuestados_por_caso": { "min": 1, "mediana": 3, "max": 7 }
  },

  "calibracion": {
    "idm": 0.95,
    "correccion_050": { "aplicada": true, "casos": ["E014", "E087"] },
    "condiciones": {
      "CAP_ABS": {
        "anclas": { "plena": 4.0, "cruce": 3.0, "nula": 2.0 },
        "fuente": "teoria",
        "justificacion": "El umbral de 4 corresponde a … (Zahra y George, 2002).",
        "spearman_vs_crudo": 0.998
      }
    }
  },

  "analisis": {
    "umbrales": { "frecuencia": 2, "consistencia": 0.80, "pri": 0.70 },
    "expectativas_direccionales": { "CAP_ABS": "presente", "REDES": "presente" },
    "necesidad": [ { "condicion": "CAP_ABS", "consistencia": 0.91, "cobertura": 0.74, "ron": 0.52 } ],
    "soluciones": { "conservadora": "…", "intermedia": "…", "parsimoniosa": "…" },
    "nca": { "ejecutado": true, "efectos": [] }
  },

  "robustez": {
    "ejecutado": true,
    "escenarios": [
      { "id": "anclas_+0.5", "configuraciones_mantenidas": 3, "de": 3, "cobertura": 0.61 }
    ]
  },

  "alertas": [
    {
      "codigo": "A-18",
      "paso": 5,
      "severidad": "bloqueante",
      "condicion": "CAP_ABS",
      "detalle": "91,3 % de los casos supera 0,50",
      "estado": "reconocida",
      "nota": "El efecto techo refleja un rasgo real del sector: …",
      "cerrada": "2026-07-30T17:41:02Z"
    }
  ],

  "entorno": {
    "r_version": "4.5.1",
    "paquetes": { "QCA": "3.23", "SetMethods": "3.0.2", "psych": "2.4.6" }
  }
}
```

### 4.2. Reglas del archivo de proyecto

- **Al cargar, se compara la huella SHA-256** con la del archivo de datos que se suba. Si
  difieren, la app **advierte antes de continuar**: el proyecto se creó contra otra base.
  No bloquea — puede ser una corrección legítima del archivo — pero la discrepancia queda
  registrada y sale en el informe.
- El campo `version_esquema` permite migrar. Un proyecto de versión desconocida se rechaza
  con un mensaje claro, nunca se abre "a ver si funciona".
- Todo lo que influye en un resultado está en el archivo. Si un número del informe no se
  puede rastrear hasta un campo de este JSON, es un defecto.

---

## 5. El informe

### 5.1. Formatos

**Quarto**, renderizado a **HTML y Word**. El Word no es un lujo: el investigador necesita
pegar texto y tablas dentro de la tesis.

### 5.2. Contenido, en orden

1. **Ficha de reproducibilidad** — versión de R, versiones exactas de los paquetes, `idm`
   usado, huella del archivo de datos, fecha.
2. **Descripción de la muestra y del mapeo** — casos, condiciones, ítems por constructo.
3. **Validación de medida** — tabla de alfas con IC, ítem-total corregida, y el CFA o el
   motivo de su omisión.
4. **Agregación** — método, política de NA, ICC si aplica.
5. **Tabla de calibración** — la pieza central. Una fila por condición: anclas, fuente,
   justificación íntegra, `idm`.
6. **Diagnósticos** — todas las alertas disparadas, su severidad, y **el texto con que se
   cerró cada una**. Las reconocidas aparecen con la nota completa, sin recortar.
7. **Análisis** — necesidad con RoN, tabla de verdad, las tres soluciones con consistencia,
   PRI, cobertura bruta y única, y los casos de cada configuración.
8. **NCA**, si se ejecutó.
9. **Robustez** — escenarios y comparación, o la declaración de por qué se omitió.
10. **Declaraciones obligatorias** — la corrección de +0,001 con los casos afectados; la
    nota sobre `idm` y las diferencias en el tercer decimal frente a fs/QCA; el control de
    validez `A-13` cuando la calibración no reordenó.
11. **Referencias** — las citas de los paquetes usados (vía `citation()`, generadas desde
    el propio análisis y no escritas a mano) más el corpus metodológico fijo, que es el de
    la sección 8 del PDF de la propuesta. Los DOI se comprueban antes de incorporarlos al
    documento final.

### 5.3. El script reproducible

Un `.R` autocontenido que va del archivo crudo a las soluciones, con las anclas y umbrales
del proyecto escritos como literales y comentados con su justificación. **Debe correr en
una sesión limpia** y producir los mismos números que el informe. Hay una prueba que lo
verifica (sección 6, `test-reproducibilidad.R`).

---

## 6. Plan de pruebas

`testthat` sobre el paquete `calibraqca`. La interfaz no se prueba automáticamente; se
verifica a ojo (sección 6.5).

### 6.1. Principio rector

> Las pruebas se vuelven ciegas por el **dato** que eligen, y **nunca deben usar la función
> bajo prueba para montar su propio escenario**.

Calcular el valor esperado llamando a `calibrar()` y luego comprobar que `calibrar()`
devuelve eso es una prueba que siempre pasa y nunca detecta nada.

### 6.2. Sensibilidad a mutaciones

**Cambiar la constante 2,944 en el código debe poner algo en rojo.** Si no, la prueba de
calibración no está probando la calibración. Lo mismo con:

| Mutación | Debe fallar |
|---|---|
| `2.944` → `2.9` | `test-calibracion.R` (puntos que la fórmula obliga) |
| `idm` 0,95 → 0,90 | `test-calibracion.R` |
| umbral de efecto techo 85 % → 90 % | `test-alertas.R::A-18 se dispara` |
| umbral PRI 0,70 → 0,60 | `test-alertas.R::A-26 se dispara` |
| `+0.001` → `+0.01` | `test-correccion-050.R` |
| desviación típica 0,15 → 0,05 en `A-20` | `test-alertas.R::A-20 se dispara` |

Esta tabla se mantiene viva: **cada constante numérica del motor debe aparecer en ella**.
Una constante que no está en la tabla es una constante sin prueba.

### 6.3. Pruebas del motor

**`test-calibracion.R`** — el núcleo.
- Los tres puntos que la fórmula obliga: `x = θ_plena → 0,95`; `x = c → 0,50`;
  `x = θ_nula → 0,05`. Valores escritos a mano, no calculados por el código.
- **Comparación directa contra `QCA::calibrate()`** con las mismas anclas y el mismo `idm`,
  sobre un vector fijo. Tolerancia `1e-9`. Esta es la prueba que justifica no haber
  reimplementado nada.
- Monotonía: la membresía nunca decrece cuando el promedio crece.
- Rango: toda membresía queda en [0, 1].
- Anclas no monótonas producen error, no un resultado silencioso.

**`test-correccion-050.R`**
- Un vector con un 0,50 exacto sale como 0,501, y el caso queda listado.
- Un vector sin 0,50 exacto sale idéntico y la lista de casos afectados está vacía.

**`test-alertas.R`** — la regla es explícita:

> **Cada alerta necesita un caso que la dispare y uno que no.** Una alerta con solo el caso
> positivo esconde el falso positivo permanente; una con solo el negativo esconde la alerta
> que nunca se activa.

Son 32 alertas (`A-01` … `A-32`), luego **64 pruebas como mínimo**. Hay una prueba que
recorre el catálogo de alertas y falla si alguna no tiene sus dos casos
(`test-catalogo-alertas.R`).

**`test-compuertas.R`**
- Una alerta bloqueante `abierta` impide avanzar.
- `reconocida` con nota de 40+ caracteres deja avanzar.
- `reconocida` con nota vacía o de 5 caracteres es rechazada.
- `resuelta` deja avanzar y sigue apareciendo en el informe.

**`test-proyecto.R`**
- Ida y vuelta: serializar un proyecto y volver a leerlo devuelve un objeto idéntico.
- Huella distinta ⇒ advertencia, no bloqueo.
- `version_esquema` desconocida ⇒ error claro.
- **Prueba de mutación del propio archivo**: cambiar un ancla en el JSON debe cambiar el
  número correspondiente del informe. Si no cambia, ese número no venía del proyecto.

**`test-frontera-shiny.R`**
- `grep` sobre `pkg/calibraqca/R/`: cero apariciones de `input$`, `output$`, `session`,
  `reactive(`, `observe(`, `showNotification`.

**`test-reproducibilidad.R`**
- Generar el script de un proyecto de ejemplo, ejecutarlo en una sesión limpia
  (`callr::r`), y comparar sus resultados con los del informe. Cualquier diferencia
  numérica es un fallo.

### 6.4. Datos de prueba

Tres bases sintéticas fijas, versionadas en `tests/testthat/datos/`, con semilla escrita:

| Base | Para qué |
|---|---|
| `limpia.csv` | todo pasa, ninguna alerta bloqueante — el caso negativo de casi todas |
| `techo.csv` | 92 % de los casos sobre 0,50 tras calibrar — dispara `A-18` |
| `degenerada.csv` | un constructo de un solo ítem, alfa 0,58, dos casos idénticos — dispara `A-03`, `A-06`, `A-22` |

### 6.5. Lo que las pruebas no cubren

- **La interfaz se mira a ojo**, con capturas en los tres puntos del flujo donde el
  investigador toma una decisión: el mapeo, los deslizadores y el semáforo. Las capturas
  las revisa Javier, no un script.
- **Nada sustituye a que el investigador use la herramienta.** Antes de darla por
  terminada, una sesión completa con sus datos reales, mirando dónde duda.

---

## 7. Estructura del repositorio

Es la estructura **destino**. Hoy solo existen `docs/especificacion.md` y
`docs/referencias/`.

```
fsqca-calibrador/
├── README.md
├── renv.lock                      # versiones bloqueadas — obligatorio
├── .Rprofile
├── Dockerfile
├── fly.toml
├── docs/
│   ├── especificacion.md          # este documento
│   ├── preguntas-al-investigador.md
│   └── referencias/
│       ├── Propuesta-herramienta-calibracion-fsQCA.pdf
│       └── fuzzy_likert_5.R
├── pkg/calibraqca/                # el motor — funciones puras
│   ├── DESCRIPTION
│   ├── NAMESPACE
│   ├── R/
│   │   ├── ingesta.R
│   │   ├── validacion.R
│   │   ├── agregacion.R
│   │   ├── calibracion.R
│   │   ├── alertas.R              # catálogo A-01..A-32 en un solo lugar
│   │   ├── analisis.R
│   │   ├── robustez.R
│   │   └── proyecto.R             # esquema JSON, leer/escribir/migrar
│   └── tests/testthat/
├── app/                           # Shiny — solo dibuja
│   ├── app.R
│   ├── R/paso_1_ingesta.R … paso_8_exportacion.R
│   └── www/
└── informe/
    ├── informe.qmd
    └── plantilla-word.docx
```

**El catálogo de alertas vive en un solo archivo** (`alertas.R`), como datos, no repartido
por el código: código, severidad, texto, paso y condición de disparo. Es lo que permite
que `test-catalogo-alertas.R` recorra las 32 y verifique que ninguna quedó sin sus dos
casos de prueba.

---

## 8. Despliegue

**Contenedor Docker en Fly.io**, con contraseña y HTTPS.

**Por qué no las alternativas:**
- **Docker local:** el investigador trabaja solo; cada tropiezo dependería de la
  disponibilidad de Javier.
- **shinyapps.io:** la autenticación real está en un plan caro.

Al ser un contenedor, mudarlo a Cloud Run, a un VPS o a la máquina del investigador es un
detalle de despliegue, no un rediseño.

**El servidor no persiste nada.** Los datos suben, se procesan en memoria y se van con la
sesión. El único artefacto que sobrevive es el que el investigador descarga.

---

## 9. Preguntas abiertas

### 9.1. Las ocho de la sección 7 del PDF — sin responder

1. ¿Cuál es el objetivo analítico? (explicar combinaciones con fsQCA / ponderar factores
   con panel de expertos / predecir con inferencia difusa)
2. ¿Unidad de análisis y tamaño de la muestra?
3. ¿Cuántos ítems por constructo y qué evidencia de validez existe?
4. ¿La variable de resultado también es Likert autorreportada del mismo cuestionario?
5. ¿Cómo se distribuyen las respuestas? (concentración en valores altos ⇒ efecto techo)
6. ¿De dónde saldrían las anclas?
7. ¿fsQCA es el método principal o complementa un modelo de ecuaciones estructurales?
8. ¿La tesis promete una contribución metodológica?

**La ingesta se construyó genérica a propósito para no bloquearse ante ninguna de ellas.**

### 9.2. La que más pesa

**¿La tesis reclama contribución metodológica?** Si sí, la herramienta es publicable por sí
misma — paquete en CRAN o nota de software — porque no hay nada equivalente: los 19
programas de la lista de COMPASSS son gratuitos y ninguno cubre calibración de datos de
encuesta. Si no, es apoyo instrumental y **no debe entrar en el argumento de la tesis**.

Esta respuesta no bloquea el desarrollo, pero sí determina cuánto se invierte en
documentación pública y en la calidad del paquete como artefacto citable.

### 9.3. Sugerencia pendiente al investigador

Abrir `QCA::runGUI()` media hora **antes** de que se construya el paso 6, dos veces. Ver
qué le resulta natural y qué no en una interfaz que ya existe ahorra rehacer la propia.

---

## 10. No-objetivos

- **No se emplean conjuntos difusos de tipo 2, intuicionistas, pitagóricos ni
  neutrosóficos**, salvo que la tesis argumente explícitamente que existe incertidumbre
  *sobre el propio grado de pertenencia*. Utilizarlos sin ese argumento se interpreta como
  inflación metodológica y suele detectarse en la defensa.
- **No se implementa el Delphi difuso de `fuzzy_likert_5.R`** en esta herramienta. Es otra
  ruta metodológica; si el objetivo analítico resulta ser multicriterio (pregunta 1), esto
  se replantea de cero.
- **No hay cuentas de usuario ni multiusuario.** Una contraseña, un investigador.
- **No se publica como aplicación web en TypeScript.** Es viable *después* de la defensa,
  envolviendo el motor de R como servicio, y solo si la herramienta se publica como aporte
  abierto a la comunidad.
