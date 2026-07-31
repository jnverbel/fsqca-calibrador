# Especificación — Calibrador fsQCA para datos Likert

**Versión:** 1.1 · **Fecha:** 2026-07-30
**Estado:** completo y funcionando. Motor con 373 pruebas sin `skip`, interfaz Shiny de
ocho pasos e informe Quarto en HTML y Word. **Se ejecuta en el equipo del investigador**
(sección 8), con doble clic sobre `Ejecutar-en-Mac.command` o `Ejecutar-en-Windows.bat`.
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
honestidad cuando la fuzzificación no cambió nada.

**Ojo: trasladar ese control tal cual fue un error que hubo que corregir.** La calibración
directa es monótona, así que aquí el orden se conserva siempre. Ver `A-13` en el paso 4.

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
| `psych` | alfa de Cronbach, ítem-total corregida | trivial pero no citable |
| `multilevel` (Bliese) | ICC(1) e ICC(2) con grupos desbalanceados | ver el paso 3 |
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

✅ **Verificado contra `SetMethods` 4.1 instalado** (2026-07-30). La familia `rob.*` existe
y cubre el protocolo completo; las firmas reales están en el paso 7. No hizo falta inventar
nada.

⚠️ **Que las firmas existan no significa que se llamen.** Hasta el 2026-07-31, `SetMethods`
y `lavaan` estaban en `Imports`, en `PAQUETES_INFORME` y en la sección de referencias del
informe **sin una sola invocación en el motor**. Corregido: el paso 7 usa `rob.calibrange` y
`rob.fit`, el paso 2 usa `lavaan::cfa`, y `test-paquetes-declarados.R` falla si vuelve a
aparecer un paquete citado sin usar. La comprobación se hace sobre el namespace cargado, no
sobre los archivos del disco.

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
- **Mapeo de ítems a constructos**: se **propone automáticamente** agrupando los ítems por
  su prefijo (`ABS1`, `ABS2`… → `ABS`), porque los cuestionarios los nombran así. El
  investigador revisa la propuesta, renombra si quiere, marca cuál es el resultado y
  descarta lo que no use. Convierte el paso de teclear un desplegable por columna a
  corregir una tabla. La columna identificadora también se propone: la primera de texto
  sin valores repetidos.
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
  aquí y no se negocia en caliente: se ofrece el CFA si `n_casos ≥ 100` **y**
  `n_casos ≥ 5 × parámetros`, donde

  ```
  parámetros = 2 × n_ítems + n_factores × (n_factores − 1) / 2
  ```

  es decir, una carga y una varianza de error por ítem más las covarianzas entre factores,
  con la varianza de cada factor fijada en 1 para identificar el modelo. Si no se cumple,
  el paso **omite el CFA explicando por qué**, en vez de mostrar un modelo que no ajusta.
  Ese texto entra en el informe.

  **REVISADO el 2026-07-31.** `cfa_viable()` decidía si el modelo era defendible, pero
  nadie lo estimaba: `lavaan` figuraba en las dependencias y en la ficha del informe sin
  haber calculado nada. Ahora `ajustar_cfa()` lo ejecuta con `lavaan::cfa(std.lv = TRUE)`
  cuando la muestra lo sostiene — `std.lv` fija la varianza de cada factor en 1, que es el
  supuesto con el que `parametros_cfa()` cuenta los parámetros libres — y reporta χ², gl,
  CFI, TLI, RMSEA y SRMR. Un modelo que no converge se declara omitido; el CFA es un
  complemento del paso 2, no su condición de existencia.

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
  justificación estadística, no basta con promediar: se calcula **ICC(1) e ICC(2)** y se
  reporta el número de encuestados por caso (mínimo, mediana, máximo).

  El cálculo va con **`multilevel::ICC1()` e `ICC2()`** (Bliese), no con `psych::ICC`:
  `psych::ICC` espera una matriz de casos por jueces con los mismos jueces para todos los
  casos, y aquí el número de encuestados varía de un caso a otro. `multilevel` trabaja
  sobre un ANOVA de un factor con grupos desbalanceados, que es exactamente este diseño.
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
| `A-13` | La calibración alteró el orden de los casos | rho de Spearman entre membresía y promedio crudo < 1 | informativa |
| `A-14` | Ancla sin justificación | falta fuente o texto | bloqueante |
| `A-15` | Anclas por percentiles | fuente = `distribución muestral` | advertencia + obliga paso 7 |
| `A-16` | Anclas no monótonas | no se cumple `θ_nula < c < θ_plena` | bloqueante |
| `A-17` | Casos en 0,50 exacto | existe al menos uno antes de la corrección | informativa (se corrige e informa) |

**Sobre `A-13` y la idea rescatada de `fuzzy_likert_5.R`.** El control de validez de aquel
script comparaba el orden difuso contra la media Likert simple para reportar con honestidad
cuando la fuzzificación no cambiaba nada. Trasladarlo tal cual aquí sería un error: **la
calibración directa es una transformación monótona creciente del promedio, así que el orden
se conserva por construcción y rho vale exactamente 1 siempre.** Una alerta que se dispara
en el 100 % de los casos es ruido, no diagnóstico.

Por eso la alerta se invierte: `A-13` se dispara cuando rho **< 1**, que indicaría un fallo
del cálculo —anclas mal ordenadas, NA mal manejados— y no un hallazgo del estudio.

La honestidad que buscaba el control original se conserva, pero como **declaración
obligatoria del informe** y no como alerta: *la calibración no reordena los casos; su aporte
es el umbral formal y la lectura en términos de pertenencia a un conjunto, no un orden
nuevo.* Se imprime siempre, con el rho como evidencia.

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

**`A-28` cubre los dos extremos, y el segundo lo destapó una encuesta de prueba.** Si casi
todas las configuraciones son suficientes, no separan nada; pero si **ninguna** lo es, no hay
nada que minimizar y `QCA::minimize()` aborta con *"None of the values in OUT is
explained"*. Ese caso aparece de verdad con efecto techo fuerte, y sin la alerta el
investigador solo vería un error en inglés. `diagnosticar_suficiencia()` recoge el fallo y
devuelve `minimizacion_posible = FALSE` con su motivo, para que el paso siga vivo.

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

**Lo que está implementado — REVISADO el 2026-07-31.** Hasta esa fecha la afirmación de
arriba era falsa: `SetMethods` figuraba en las dependencias y en la ficha del informe, pero
**no se invocaba en ninguna parte**, el barrido era propio y el botón «Ejecutar el barrido»
no tenía ningún `observeEvent` que lo escuchara. El paso 7 no calculaba nada. Corregido en
`pkg/calibraqca/R/robustez.R` y `app/app.R`.

Firmas verificadas contra `SetMethods` 4.1 instalado, no escritas de memoria:

| Función | Para qué | ¿Se usa? |
|---|---|---|
| `rob.calibrange(raw.data, calib.data, test.cond.raw, test.cond.calib, test.thresholds, type, step, max.runs, outcome, conditions, incl.cut, n.cut, include, ...)` | **el rango de cada ancla** — hasta dónde puede moverse sin que la solución cambie | **sí**, en `rango_anclas()` |
| `rob.fit(test_sol, initial_sol, outcome)` | ajuste de la solución alternativa frente a la original | **sí**, en `ejecutar_escenario()` |
| `rob.inclrange(data, step, max.runs, outcome, conditions, incl.cut, n.cut, include, ...)` | barrido del umbral de consistencia | **sí**, en `rango_consistencia()` |
| `rob.ncutrange(data, step, max.runs, outcome, conditions, incl.cut, n.cut, include, ...)` | barrido de la frecuencia mínima | **sí**, en `rango_frecuencia()` |
| `pimdata(results, outcome)` | pertenencia de cada caso a la solución y al resultado | **sí**, en `estatus_de_casos()` |
| `rob.cases(test_sol, initial_sol, outcome)` | qué casos cambian de estatus | **no — está roto**, ver abajo |
| `rob.corefit(...)` | ajuste de las configuraciones centrales | no |
| `rob.singletest(...)` | comparación contra un único escenario | no |
| `rob.xyplot(...)` | gráfico de la comparación | no |

#### Dos fallos de `SetMethods` 4.1 que hubo que rodear

Verificados el 2026-07-31 contra `SetMethods` 4.1, `QCA` 3.25 y `admisc` 0.40.

- **`rob.cases` no es utilizable.** Aborta con `Incorrect expression, some set names do not
  have brackets`, lanzado desde su interna `robust.intersections`. **Falla también con el
  ejemplo oficial de su propia documentación** (`?rob.cases` sobre `PAYF`), y con
  condiciones de una y de dos letras, así que no es cuestión de los datos ni de cómo se
  llama. En su lugar, `estatus_de_casos()` toma las pertenencias de `SetMethods::pimdata`
  —que sí funciona— y aplica la clasificación de **Schneider y Rohlfing (2013)**: típico,
  desviado por consistencia, desviado por cobertura o irrelevante. El cálculo sigue siendo
  de `SetMethods`; lo propio es la clasificación, y es una regla publicada y citable.
- **`rob.ncutrange` aborta cuando el barrido inferior agota `max.runs`**: compara
  `n.cut.tl == nrow(data)` después de haberle asignado `NA`, y revienta con `missing value
  where TRUE/FALSE needed`. `.rango_umbral()` lo captura, devuelve los límites en `NA` y
  **escribe el motivo en el informe**. El guion reproducible envuelve esa llamada en `try()`
  para que no detenga el script en manos de un tercero.

Un caso se considera perteneciente a un conjunto con pertenencia **> 0,5**, no ≥ 0,5: una
pertenencia de 0,50 exacta no es pertenencia. El paso 4 ya corrige esos casos, así que no
debería haber ninguno, pero la regla se escribe igual para que ninguno quede sin clasificar.

La columna «¿Se usa?» no es decorativa: `test-paquetes-declarados.R` falla si un paquete
aparece en `PAQUETES_INFORME` sin una sola llamada en el motor, para que el informe no
pueda volver a citar a nadie por un cálculo que no hizo.

Se reporta:

- **Rango de cada ancla** (`rob.calibrange`), una fila por condición y ancla. Un límite
  vacío se escribe **«no cambia»** y no «—»: significa que la solución aguantó toda la
  ventana explorada, `max_pasos` pasos de tamaño `paso` a cada lado. Es el mejor resultado
  posible, y presentarlo como un dato ausente lo haría parecer un fallo.
- **Escenarios alternativos**, cada uno recalibrado y vuelto a minimizar de verdad: cuántas
  configuraciones de la solución original se mantienen, la cobertura, y `RF_cons` / `RF_cov`
  de `rob.fit`.
- **El motivo escrito** de los escenarios cuya minimización es imposible. Un «0 de 1» sin
  explicación se lee como un fallo del programa, y es un resultado.
- **Rango de los dos umbrales del paso 6**: consistencia (`rob.inclrange`, pasos de 0,05) y
  frecuencia mínima (`rob.ncutrange`, pasos de 1, porque es un conteo de casos).
- **Qué casos cambian de estatus** en cada escenario, con nombre y con el cambio concreto
  (`E005: típico → desviado por cobertura`). Un escenario sin solución que comparar se
  reporta **«no comparable»**, nunca «0 casos cambian»: no hay cero cambios, no hay
  comparación.

**Advertencia sobre `idm`.** `rob.calibrange` llama a `QCA::calibrate()` sin pasarle `idm`,
así que trabaja siempre con el valor por defecto de QCA (0,95). Si el paso 4 usara otro,
los rangos dejarían de ser comparables con la calibración que documenta el informe:
`barrido_robustez()` avisa en vez de callarlo.

Pendiente: nada del protocolo. Queda fuera por decisión, no por falta: `rob.corefit`,
`rob.singletest` y `rob.xyplot`, que no añaden nada que el informe no diga ya.

**Este paso es obligatorio si el paso 4 registró `A-15`** (anclas por distribución
muestral). En cualquier otro caso es recomendado y se puede omitir reconociéndolo por
escrito.

| Cód. | Alerta | Disparo | Severidad |
|---|---|---|---|
| `A-31` | Solución no robusta | alguna configuración desaparece en ≥ 1 escenario | advertencia |
| `A-32` | Robustez omitida con anclas muestrales | `A-15` activa y paso 7 sin ejecutar | bloqueante |

**Se guarda:** los rangos de todas las anclas, los escenarios ejecutados con su ajuste, y
la ventana explorada (`paso`, `max_pasos`, `idm`) para que el barrido sea reproducible.

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
    nota sobre `idm` y las diferencias en el tercer decimal frente a fs/QCA; y el control de
    validez: *la calibración no reordena los casos, su aporte es el umbral formal y la
    lectura en términos de pertenencia*, con el rho de Spearman como evidencia.
11. **Referencias** — las citas de los paquetes usados (vía `citation()`, generadas desde
    el propio análisis y no escritas a mano) más el corpus metodológico fijo, que es el de
    la sección 8 del PDF de la propuesta. Los DOI se comprueban antes de incorporarlos al
    documento final. **La herramienta no se cita a sí misma**: la tesis no reclama
    contribución metodológica, así que el crédito va a Ragin, Dușa, Oana y Schneider, Dul,
    y Pappas y Woodside (sección 9.2).

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

**Pasos 1 a 3:**

| Mutación | Debe fallar |
|---|---|
| `MIN_CARACTERES_NOTA` 40 → 2 | `test-compuertas.R::una nota corta o vacia es rechazada` |
| `UMBRAL_NA_ITEM` 0,10 → 0,20 | `test-ingesta.R::A-04 se dispara` |
| `ALFA_MINIMO` 0,70 → 0,50 | `test-validacion.R::A-06 se dispara` |
| `ALFA_DUDOSO` 0,80 → 0,90 | `test-validacion.R::clasificar_alfa` |
| `ALFA_INFLADO` 0,95 → 0,99 | `test-validacion.R::alfa_inflado marca el limite exacto` |
| `ITEMS_PARA_ALFA_INFLADO` 6 → 3 | `test-validacion.R::alfa_inflado marca el limite exacto` |
| `ITEM_TOTAL_MINIMO` 0,30 → 0,10 | `test-validacion.R::A-08 se dispara` |
| `CASOS_POR_PARAMETRO` 5 → 2 | `test-validacion.R::A-10 se dispara` |
| `CASOS_MINIMOS_CFA` 100 → 30 | `test-validacion.R::el minimo absoluto de casos manda` |
| `PROPORCION_MINIMA_ITEMS` 0,5 → 0,2 | `test-agregacion.R::demasiados NA` |
| `ICC1_MINIMO` 0,05 → −1 | `test-agregacion.R::cada umbral del ICC manda por separado` |
| `ICC2_MINIMO` 0,70 → 0,10 | `test-agregacion.R::cada umbral del ICC manda por separado` |

**Pasos 4 y 5:**

| Mutación | Debe fallar |
|---|---|
| `IDM_POR_DEFECTO` 0,95 → 0,90 | `test-calibracion.R::los tres puntos que la formula obliga` |
| umbrales `e`/`i` invertidos en `calibrar()` | `test-calibracion.R::coincide con QCA::calibrate` |
| `MIN_CARACTERES_JUSTIFICACION` 30 → 2 | `test-calibracion.R::A-14 se dispara` |
| `CORRECCION_050` 0,001 → 0,01 | `test-correccion-050.R::A-17 se dispara` |
| `UMBRAL_TECHO` 0,85 → 0,95 | `test-semaforo.R::A-18 se dispara` |
| `UMBRAL_PISO` 0,85 → 0,95 | `test-semaforo.R::A-19 se dispara` |
| `SD_MINIMA` 0,15 → 0,01 | `test-semaforo.R::A-20 se dispara` |
| `ASIMETRIA_MAXIMA` 2 → 10 | `test-semaforo.R::A-21 se dispara` |
| `CORRELACION_MAXIMA` 0,80 → 0,999 **y** → 0,50 | `test-semaforo.R::cada predicado marca su limite` |
| `DIVISOR_DIVERSIDAD` 4 → 100 | `test-semaforo.R::A-23 se dispara` |

**Pasos 6 y 7:**

| Mutación | Debe fallar |
|---|---|
| `NECESIDAD_CONSISTENCIA` 0,90 → 0,50 | `test-necesidad.R::necesidad_trivial marca los limites` |
| `RON_MINIMO` 0,60 → 0,10 | `test-necesidad.R::A-27 se dispara` |
| `CONSISTENCIA_MINIMA` 0,80 → 0,50 | `test-tabla-verdad.R::A-26 se dispara` |
| `PRI_MINIMO` 0,70 → 0,30 | `test-tabla-verdad.R::A-26 se dispara` |
| `PROPORCION_DEGENERADA` 0,80 → 0,99 | `test-tabla-verdad.R::A-28 se dispara` |
| `CONSISTENCIA_CONTRADICCION` 0,50 → 0,79 | `test-tabla-verdad.R::A-30 se dispara` |
| `LIMITE_MUESTRA_PEQUENA` 50 → 5 | `test-tabla-verdad.R::umbral_frecuencia marca el limite` |
| `COBERTURA_MINIMA` 0,50 → 0,10 | `test-minimizacion.R::A-29 se dispara` |
| `IDM_SETMETHODS` 0,95 → 0,90 | `test-robustez-setmethods.R::el barrido avisa cuando idm no es el que usa SetMethods` |
| `ANCLAS_EN_ORDEN` permutado | `test-robustez-setmethods.R::el rango nombra las tres anclas` |
| `NOMBRES_AJUSTE` reordenado | `test-robustez-setmethods.R::el ajuste del escenario sale de rob.fit` |
| `PASO_CONSISTENCIA` 0,05 → 0,10 | `test-robustez-setmethods.R::el rango de consistencia coincide con rob.inclrange` |
| `PASO_FRECUENCIA` 1 → 2 | `test-robustez-setmethods.R::el rango de frecuencia coincide con rob.ncutrange` |
| el `> 0.5` de `clasificar_casos()` → `>= 0.5` | `test-robustez-setmethods.R::el punto de cruce exacto no deja un caso sin clasificar` |
| los cuatro `ESTATUS_*` permutados | `test-robustez-setmethods.R::cada caso se clasifica por su pertenencia` |

**El bug que la lectura de la tabla de verdad evita.** En `QCA` 3.25 las columnas `incl` y
`PRI` de `tt$tt` son **`character`**, y las filas no observadas traen `"-"`. Como
`"-" < "0.7"` es `TRUE`, comparar sin convertir marca casi toda la tabla como PRI bajo:
sobre el ejemplo de Lipset, **30 de 32 filas en vez de 7**. Por eso existe
`leer_tabla_verdad()`, que convierte con `as.numeric()` y filtra las observadas, y por eso
hay una prueba que contrasta la lectura ingenua con la correcta.

**La constante 2,944 no aparece en esta tabla, y es correcto:** vive dentro de
`QCA::calibrate()`, que es lo que se quería. Lo que la prueba verifica en su lugar es que
la envoltura pasa las anclas en el orden debido y que los tres puntos obligados dan 0,05 /
0,50 / 0,95 — invertir los umbrales `e` e `i` produce 0,95 donde debe haber 0,05.

**Lección de la primera ronda, que se repitió dos veces:** cuatro de estas constantes
sobrevivieron su mutación porque la prueba que supuestamente las cubría decidía por otro
camino. `ALFA_INFLADO` no mordía porque el escenario de `A-09` superaba cualquier umbral
razonable; `CASOS_MINIMOS_CFA` no mordía porque el otro criterio siempre era mayor; y los
dos umbrales del ICC no mordían porque en datos reales fallan juntos y la disyunción tapaba
cuál mandó. **Cuando una constante vive dentro de una condición compuesta, se aísla en su
propia función y se prueba en el límite** — así nacieron `alfa_inflado()` e `icc_respalda()`.

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
- **Lo que sí se comprueba desde el 2026-07-31:** que ningún botón quede dibujado sin
  manejador (`test-botones-cableados.R`). Es el fallo que más veces se ha repetido aquí y
  siempre lo encontró alguien usando la aplicación, nunca la suite: los cuatro botones de
  descarga (`52ab42f`), el flujo de los pasos 4 a 8 (`c00c918`) y el barrido de robustez,
  que llevaba desde el principio sin ningún `observeEvent`. La prueba lee los archivos de
  `app/` y exige que cada `actionButton` aparezca como `input$id` y cada `downloadButton`
  como `output$id`.
- **Sigue sin cubrirse** que el manejador haga lo correcto, ni que el panel pinte lo que
  debe. Para eso hace falta `shinytest2`, que no está.
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

## 8. Despliegue — REVISADO el 2026-07-30

**La herramienta se ejecuta en el equipo del investigador.** No hay servidor.

Esto **invierte la decisión original**, que era un contenedor en Fly.io. Conviene dejar
claro por qué se descartó entonces lo local y qué cambió:

> El argumento en contra era que el investigador trabaja solo, y que ante cada tropiezo
> —un contenedor que no arranca, un puerto ocupado— dependería de la disponibilidad de
> Javier. **Ese riesgo sigue siendo real.** Lo que cambió no es el diagnóstico sino la
> mitigación: en vez de pedirle que instale Docker y ejecute comandos, se le entrega un
> archivo que abre con doble clic, con todos los mensajes en español y diciendo qué hacer
> ante cada fallo previsible.

A favor de lo local, y pesa: **los datos de la encuesta nunca salen de su equipo**, no hay
costo mensual, y no hay una URL que alguien pueda encontrar.

### Cómo arranca

| Sistema | Archivo | Qué hace |
|---|---|---|
| Windows | `Ejecutar-en-Windows.bat` | busca R, instala paquetes la primera vez, abre el navegador |
| macOS | `Ejecutar-en-Mac.command` | lo mismo, y detecta si faltan las Xcode Command Line Tools |

Único requisito previo: **instalar R una vez**, desde el instalador oficial de CRAN. Las
instrucciones para el investigador están en `INSTALAR.md`, escritas sin jerga.

### El repositorio de paquetes es un snapshot con fecha, y no es un detalle

`renv.lock` apunta a **`https://packagemanager.posit.co/cran/2026-07-30`**, no a CRAN.

CRAN solo sirve como binario la **última** versión de cada paquete. En cuanto `QCA` pase
de 3.25 a 3.26, un `renv::restore()` en Windows no encontraría el binario de la versión
clavada e intentaría **compilar desde fuente**, lo que exige instalar Rtools; compilar
`lavaan`, `stringi` o `Matrix` sin él falla en seco. El snapshot con fecha congela el
estado del repositorio y sirve binarios de las versiones exactas del lockfile.

Verificado: el snapshot declara `QCA 3.25` y entrega su binario de Windows.

En macOS el snapshot entrega código fuente. Los paquetes de R puro se instalan igual; para
los que llevan C hacen falta las Xcode Command Line Tools, y el guion de arranque lo
detecta y explica cómo instalarlas.

### Acceso

`CLAVE_APP` protege la aplicación cuando escucha fuera de `127.0.0.1`. **En local no se
usa**: la app solo escucha en loopback, así que no hay a quién proteger, y el aviso de
"aplicación abierta" solo aparece si se expone a la red. Sacarlo en local sería alarmar
sin motivo.

### El contenedor sigue existiendo

`Dockerfile` y `fly.toml` se conservan. Publicar en Fly.io queda a un `flyctl deploy
--remote-only` de distancia si más adelante hiciera falta —por ejemplo, si el investigador
cambia de equipo a menudo o quiere trabajar desde varios sitios—. Al ser un contenedor,
mudarlo a Cloud Run o a un VPS es un detalle de despliegue, no un rediseño.

**El servidor no persiste nada**, se ejecute donde se ejecute. Los datos se procesan en
memoria y desaparecen al cerrar. Lo único que sobrevive es lo que el investigador descarga.

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

### 9.2. La que más pesaba — RESPONDIDA el 2026-07-30

**La tesis NO reclama contribución metodológica.** Aplica un método existente.

Consecuencias, que rigen de aquí en adelante:

- **La herramienta es apoyo instrumental y no entra en el argumento de la tesis.**
  Presentarla como aporte cuando el capítulo no lo sostiene es de las cosas que se detectan
  en la defensa.
- **No se publica**: ni CRAN, ni nota de software, ni documentación pública. Ese trabajo
  sale del alcance (sección 10).
- **El capítulo metodológico describe el procedimiento, no el software.** Lo que se defiende
  es la calibración directa sobre el promedio del constructo, con sus anclas justificadas y
  sus umbrales declarados. Que esos pasos los haya ejecutado una aplicación propia es
  irrelevante para el argumento, igual que lo sería haberlos ejecutado a mano en R.
- **Las citas van a los paquetes y a las obras**, nunca a la herramienta: Ragin para la
  calibración directa, Dușa para `QCA`, Oana y Schneider para `SetMethods` y el protocolo
  de robustez, Dul para NCA, Pappas y Woodside para calibrar datos de encuesta.

**Lo que NO cambia, y conviene subrayarlo:** el informe y el rastro de decisiones siguen
siendo la razón de ser de la herramienta. Que la tesis no reclame aporte metodológico no
relaja ni un punto la exigencia de justificar cada ancla ni de declarar cada umbral — esas
son preguntas del jurado sobre el *método*, y llegan igual, con herramienta o sin ella.

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
- **No se publica como aplicación web en TypeScript.** Solo tenía sentido si la herramienta
  se publicaba como aporte abierto a la comunidad, y la tesis no reclama contribución
  metodológica (sección 9.2). Descartado.
- **No se prepara el paquete para CRAN.** Sin contribución metodológica que defender, no hay
  razón para invertir en `roxygen2` completo, viñetas, `R CMD check` limpio ni el trámite de
  publicación. **Las pruebas se mantienen íntegras**: no son para el jurado, son para que el
  cálculo sea correcto.
