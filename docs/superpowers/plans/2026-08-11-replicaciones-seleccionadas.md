# Replicaciones seleccionadas de Nivel B: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ejecutar, contra los nueve estudios de Nivel B congelados el 2026-08-11, únicamente los módulos que cada uno declara reproducibles; clasificar cada diferencia con un código `D-*` y publicar el resultado sin convertir cobertura modular en validación integral.

**Architecture:** Cada estudio tiene manifiesto (procedencia y SHA-256), prerregistro (decisiones y expectativas con localizador), tabla de expectativas legible por máquina, adaptador de preparación y una prueba `testthat`. El corredor recorre los manifiestos existentes, escribe un CSV de resultados y desde ese CSV se generan las tablas de `docs/validacion-integral.md`. Ningún documento transcribe a mano un número que ya viva en un archivo estructurado.

**Tech Stack:** R 4.6.1 con `renv.lock`, `QCA`, `NCA`, `readxl`, `readr`, `digest`, `jsonlite`, `testthat`, Markdown, SHA-256, GitHub Actions y Git.

---

## Declaración de alcance (obligatoria y literal)

Este párrafo se copia sin cambios en `docs/validacion-integral.md`, en el resumen del
`README.md` y en el `README.es.md`:

> No existe validación externa integral del flujo Likert/multiítem de `fsqca-calibrador`.
> La selección congelada el 2026-08-11 contiene **0 estudios de Nivel A** sobre 28
> evaluaciones a texto completo. Los nueve estudios replicados son de **Nivel B**: cubren
> módulos sueltos del flujo y **ninguno cuenta como validación integral**, ni siquiera
> sumados. Un resultado favorable en los nueve autoriza a decir que esos módulos
> reprodujeron los valores publicados de esos estudios, y nada más.

## Restricciones globales

- La selección está **congelada**. Este plan no reabre `docs/validacion/estudios.csv`, no
  promueve estudios, no reclasifica niveles y no altera criterios. Los módulos de cada
  estudio son exactamente sus campos `mod_* == "si"`.
- **Tolerancias congeladas antes de ejecutar nada**, y no se modifican después de observar
  un resultado: `1e-9` para valores disponibles con precisión completa;
  `0.5 * 10^(-d)` para un valor publicado con `d` decimales; igualdad exacta para conteos,
  filas de tabla de verdad y soluciones normalizadas.
- Un valor que solo exista en una **figura** no se usa como prueba numérica de aprobación
  (especificación §6). Sí se usa la afirmación proposicional que el texto haga sobre esa
  figura, citando el párrafo.
- **No se versionan archivos de terceros.** Los binarios originales se descargan a un
  directorio ignorado por Git y se verifican contra el manifiesto. Las dos únicas
  excepciones son transcripciones de artefactos ilegibles por máquina (PDF y `.doc`), que
  sí se versionan porque su licencia CC BY 4.0 lo permite, con atribución, procedencia y
  regla de verificación en el propio archivo.
- El corredor de CI no admite `skip`, `continue-on-error`, `testthat::skip*` ni
  `if (interactive())` alrededor de una comparación.
- Una fuente caída o un hash que no coincide dejan la replicación en **no ejecutable**,
  nunca en aprobada (especificación §12).
- Ninguna afirmación de este plan sustituye a las tolerancias por juicio: si el estudio no
  declara un parámetro, el prerregistro lo registra como **ausente** con el localizador de
  la búsqueda, y la comparación que dependa de él se clasifica `D-AMB`.

---

## Artefactos verificados el 2026-08-11

Nombre de archivo tal como lo sirve el repositorio, bytes servidos y SHA-256 calculado con
`shasum -a 256` sobre el archivo descargado fuera del repositorio. Todos los suplementos
PLOS se obtuvieron de
`https://journals.plos.org/plosone/article/file?id=<DOI>.<sNNN>&type=supplementary`.

| Estudio | Archivo servido | Bytes | SHA-256 | Licencia |
| --- | --- | ---: | --- | --- |
| E008 | `journal.pone.0326226.s001.docx` | 35.343 | `0720325c7d1658d7f150abb866a722096d250d3c97b564dafb8f46805ca850f4` | CC BY 4.0 |
| E008 | `journal.pone.0326226.s002.docx` | 18.029 | `c7db607d8f2a31aa1d90c655b4560767ae1a0bd4e0cb78eaf7a32e714eeb294f` | CC BY 4.0 |
| E008 | `journal.pone.0326226.s003.xlsx` | 29.514 | `583c935f3015d7b664c6a49cbb0bd541dcca19b9b85e794d0ce4573ce9d28d32` | CC BY 4.0 |
| E009 | `journal.pone.0348315.s002.xlsx` | 40.315 | `4e74fbe6859cf3aae69f288a1e0db211c0d2df5c136226e738cff33d1382ebb3` | CC BY 4.0 |
| E009 | `journal.pone.0348315.s004.docx` | 11.371 | `851b22c25ab9cf7293d0b0b770cb75f31d4154da94b4bf7e7bffaa434f1ba2a3` | CC BY 4.0 |
| E012 | `journal.pone.0282617.s001.xlsx` | 13.393 | `ce4bdff6e659f14dce5dd0669ebf92b319db2ef176c97c8f0c7a825495e00f20` | CC BY 4.0 |
| E012 | `journal.pone.0282617.s002.doc` | 143.360 | `60b8dd40d1266527d7f3ccb331edd8ab111b935be5dd20c8d41e49275849152d` | CC BY 4.0 |
| E014 | `journal.pone.0301031.s001.csv` | 668 | `e8ee154fec02a51a5e864f04a1cd5150dc119972e6b77b0568a1cdc39d5f9812` | CC BY 4.0 |
| E015 | `journal.pone.0302210.s001.pdf` | 168.967 | `c505a456869c547444fb858c850032fc8203458588eea0657357c6f08a66b604` | CC BY 4.0 |
| E025 | `journal.pone.0291870.s001.csv` | 16.149 | `01712015f25e947bddff4381ab11f40055ca66c8efc359003eb1c39ef870030b` | CC BY 4.0 |
| E026 | `journal.pone.0315249.s001.zip` | 9.216 | `e076c63a2f8221f8ab33c74e9e6747d25e81afe4ebcf48f57ff41c744a28ac28` | CC BY 4.0 |
| E026 | `dataset.csv` (interior del ZIP) | 29.155 | `4d8655ba5f66f95f544c073ecc8d4c229266ddf1352c3a8bd4c4af95c04a26ce` | CC BY 4.0 |
| E027 | `journal.pone.0320723.s003.csv` | 22.728 | `5428111021daf9ec132dc425ab137966f36f724f628e1bbdff99cc7a413ed4f0` | CC BY 4.0 |
| E001 | **ausente**: ver «Bloqueo de acceso a Harvard Dataverse» | — | — | CC0 1.0 |

Artefactos adicionales inspeccionados y hasheados el 2026-08-11, no usados como entrada de
datos: `journal.pone.0320723.s001.docx`
(`f3eacfb21a851027603cb02703b68a29500903002ce3d674e0a4fcb7974ca76e`, 18.079 B) y
`journal.pone.0320723.s002.docx`
(`2c5ed6e7746bf7c298c14219c8bd87e86e5b713d24ad418b5d8dff27c5b66ea7`, 54.227 B);
`journal.pone.0282617.s003.doc`
(`0875441e072840525078e8890a90ace0d40f8049561deb329c4e10cd1e734723`, 48.640 B),
`.s004.doc` (`caf06be5fb0188fe31c4c2fce49369f7e283f44e1764582a026b1fb663a33701`, 75.264 B),
`.s005.doc` (`080839eb9f836e71c9c26420e1c7140d6fd73e421333e4cd416eebeacdfbe662`, 76.288 B) y
`.s006.doc` (`8fa25f41ee8c30290000884b19d73b43b3a9a3f080239068314a3203a16681aa`, 46.080 B).

### Bloqueo de acceso a Harvard Dataverse (E001)

El 2026-08-11 no fue posible enumerar ni descargar el paquete `doi:10.7910/DVN/27100`.
Seis rutas de `https://dataverse.harvard.edu` devolvieron `HTTP/2 202` con cuerpo vacío y
la cabecera `x-amzn-waf-action: challenge` (`server: awselb/2.0`):
`/api/datasets/:persistentId/?persistentId=doi:10.7910/DVN/27100`,
`/api/datasets/export?exporter=dataverse_json&persistentId=doi:10.7910/DVN/27100`,
`/api/search?q=identifier:DVN/27100`,
`/dataset.xhtml?persistentId=doi:10.7910/DVN/27100`,
`/api/info/version` y `/api/access/datafile/3820358`. El bloqueo es del servidor y afecta a
todo `dataverse.harvard.edu`, no a un archivo concreto. Lo que sí se verificó ese día, en
`https://api.datacite.org/dois/10.7910/DVN/27100`: título «Replication data for: Fuzzy Sets
on Shaky Ground…», versión `2.0`, `rightsIdentifier: cc0-1.0` con
`rightsUri: https://creativecommons.org/publicdomain/zero/1.0/legalcode`, y sendas listas de
**144** tamaños y 144 formatos de archivo **sin nombres de archivo** (`length(sizes)` y
`length(formats)` en el JSON, y 144 etiquetas `<size>` en
`application/vnd.datacite.datacite+xml`, comprobado el 2026-08-11). Por eso este plan no escribe un
nombre de archivo de E001: no lo tiene verificado, y no lo inventa. El único identificador
en firme es el SHA-256 `58c75ec4d18f1914b0d442f40f19007375014140d7a2827afb0f7f11c8d60aae`
del script oficial, congelado en `docs/validacion/estudios.csv` el 2026-08-10.

## Módulos declarados por estudio

Copia literal de los campos `mod_*` de `docs/validacion/estudios.csv`. **La copia no se
sostiene con un volcado**: un `print()` da estado 0 con la tabla correcta y también con la
tabla desviada. Quien la sostiene es `validation/tests/test-tabla-modulos-del-plan.R`
(Task 13), que compara las 54 celdas y **aborta**; el corredor de CI lo ejecuta. Cualquier
tabla de este plan que diga ser copia de un CSV necesita un verificador así, no un comando
que imprima.

Solo se planifican las celdas `si`; `no_evaluable` no se replica y se informa como tal.

| Estudio | calibracion | necesidad | tabla_verdad | minimizacion | ajuste | robustez |
| --- | --- | --- | --- | --- | --- | --- |
| E001 | si | no_evaluable | si | si | si | si |
| E008 | si | si | si | si | si | si |
| E009 | no_evaluable | si | si | no_evaluable | si | si |
| E012 | si | si | si | si | si | si |
| E014 | si | si | si | no_evaluable | si | no_evaluable |
| E015 | si | si | si | si | si | no_evaluable |
| E025 | si | si | si | no_evaluable | si | si |
| E026 | si | si | si | no_evaluable | si | si |
| E027 | si | si | si | no_evaluable | si | no_evaluable |

**`minimizacion` es `si` en cuatro estudios y solo cuatro: E001, E008, E012 y E015.** En
E009, E014, E025, E026 y E027 la selección la congeló como `no_evaluable` porque el estudio
no publica el `include` con el que se obtuvo su solución. Ese hecho gobierna dos decisiones
del plan que sin él serían errores:

1. En esos cinco estudios **no se compara ninguna solución**, y en particular **no se
   sustituye la intermedia publicada por la parsimoniosa**. Sus tablas de configuraciones
   son intermedias: E014 lo dice literalmente («The intermediate solution with moderate
   complexity and strong rationality is selected as the analysis result»), y E025, E026 y
   E027 distinguen condiciones centrales de periféricas anidando la parsimoniosa dentro de
   la intermedia. Comparar una intermedia publicada con la parsimoniosa de la aplicación
   produciría un `D-APP` que culparía al motor de una diferencia que no es suya.
2. Su módulo de **ajuste**, que sí está `si`, se rige por la regla de la sección siguiente.

## Regla de tipo de solución y de ajuste

Los parámetros de ajuste que publica un estudio son los **de la solución que ese estudio
reporta**. Comparar el ajuste de la aplicación con ellos solo es decidible si la aplicación
puede producir esa misma solución. De ahí dos reglas, fijadas antes de ejecutar nada:

- **Una diferencia atribuible al tipo de solución nunca se clasifica `D-APP`.** Si los
  términos de la aplicación difieren de los publicados solo por condiciones adicionales
  compatibles con la relación parsimoniosa ⊆ intermedia ⊆ compleja, el código es `D-AMB`.
- **Esa excusa la lleva la FILA, no el estudio, y solo vale en tres módulos.** La columna
  `decidible` de `validation/expectativas/<ID>.csv` admite `si`, `no_tipo_solucion` y
  `no_sin_fuente`, y `no_tipo_solucion` **solo puede aparecer en `minimizacion`, `ajuste` y
  `robustez`**, que son los únicos que dependen de qué solución se eligió. `calibracion`,
  `necesidad` y `tabla_verdad` se calculan antes de minimizar: marcarlas así es un error de
  categoría y `codigo_de_la_fila()` aborta. Sin esa regla, un absorbedor por estudio
  absolvería también las 459 × 6 membresías calibradas de E026 —la comparación más fuerte de
  la muestra— y un fallo real de `calibrar()` saldría en verde.
- **`no_sin_fuente` exige que la columna `fuente` declare la ausencia** («ausente», «no
  publica»…). Es lo que impide absolver una comparación cuyo valor sí está publicado.
- **`ajuste` decidible** en los cuatro estudios cuya solución sí es reproducible:
  E001 (la produce su script oficial), E008 (la nota de su Tabla 7 declara **todas** las
  condiciones mostradas como centrales, de modo que los términos exhibidos coinciden con los
  de la parsimoniosa), E012 (publica el `include` en texto) y E015 (publica explícitamente
  la más parsimoniosa, por Quine-McCluskey).
- **`ajuste` prerregistrado `D-AMB`** en E009, E014, E025, E026 y E027: su ajuste publicado
  es el de la solución intermedia y su `include` es ausente, así que no hay solución de la
  aplicación con la que confrontarlo. La comparación **se ejecuta igualmente** y su fila
  entra en el CSV con código `D-AMB`, la fuente de la expectativa y el ajuste que la
  aplicación sí produce anotado en la columna `obtenido`, para que el informe muestre ambos
  números sin declarar equivalencia. Un `D-AMB` no cuenta como aprobación.
- **La robustez de E009 NO entra en esa excusa.** Lo que compara es la estabilidad de los
  veredictos de necesidad ante el barrido de anclas del propio motor: no depende del tipo de
  solución, depende de la aplicación. Su fila lleva `decidible = si` y **tiene que poder
  salir `D-APP`**, porque un barrido que voltea un veredicto sería un defecto de
  `fsqca-calibrador`. Un guardián que exigiera `D-AMB` para toda la robustez de los cinco
  estudios convertiría ese hallazgo en una prueba roja y presionaría a degradarlo.
- **Qué estudios tienen minimización comparable no se escribe a mano**: sale de
  `mod_minimizacion == "si"` en `docs/validacion/estudios.csv` (E001, E008, E012 y E015), y
  `test-consolidacion.R` exige, para cada uno, o bien una expectativa con `decidible = si`,
  o bien un registro en `docs/validacion/no-ejecutables.csv` con su evidencia. Así, añadir
  un estudio a una lista de absueltos no puede pasar en silencio.

## Compuertas previas (no son módulos)

`MODULOS` es un dominio cerrado de seis nombres. La verificación de la **agregación de ítem
a constructo** no es ninguno de ellos: es una **compuerta previa**, sin fila en
`docs/validacion/replicaciones.csv`. Se registra en `docs/validacion/compuertas.csv` con
encabezado `id_estudio,compuerta,fuente,estado,detalle`, donde `estado` admite `pasa`,
`no_pasa` y `no_aplica`. Afecta a E025, E027 y E009. Si una compuerta queda en `no_pasa`,
**todas** las filas de resultados de ese estudio se registran `D-AMB`; nunca se omiten.

## Estructura de archivos

- `validation/R/comun-replicacion.R`: descarga verificada, tolerancias, comparador y códigos `D-*`.
- `docs/validacion/compuertas.csv`: estado de las compuertas previas de agregación.
- `docs/validacion/no-ejecutables.csv`: estudios que no se pudieron ejecutar, con evidencia.
- `validation/manifiestos/<ID>.json`: procedencia, archivo servido, bytes, SHA-256, licencia y fecha.
- `validation/prerregistros/<ID>.md`: decisiones, ausencias con localizador y límites.
- `validation/expectativas/<ID>.csv`: expectativas legibles por máquina.
- `validation/R/adaptador-<ID>.R`: preparación sin decisiones ocultas.
- `validation/tests/testthat/test-replicacion-<ID>.R`: comparaciones con tolerancia.
- `validation/transcripciones/`: transcripciones versionadas de PDF y `.doc`, con atribución.
- `validation/R/ejecutar-replicaciones.R`: corredor que escribe los resultados.
- `docs/validacion/replicaciones.csv`: una fila por comparación, con su código `D-*`.
- `docs/validacion-integral.md`: informe generado desde ese CSV.
- `.github/workflows/pruebas.yml`: trabajo `replicaciones`.

---

### Task 1: Fijar los contratos de replicación

**Files:**
- Create: `validation/R/comun-replicacion.R`
- Create: `validation/tests/test-contratos-replicacion.R`
- Create: `docs/validacion/diccionario-replicaciones.md`

**Interfaces:**
- Consumes: las tolerancias congeladas y los códigos `D-*` de la especificación §6 y §8.
- Produces: `obtener_artefacto()`, `tolerancia_de()`, `comparar()` y los esquemas de manifiesto, expectativas y resultados.

- [ ] **Step 1: Escribir la prueba de los contratos antes que el código**

Crear `validation/tests/test-contratos-replicacion.R`. Este es el contenido exacto,
ejecutado y sometido a mutación antes de escribirlo aquí:

```r
source("validation/R/comun-replicacion.R")

stopifnot(identical(CODIGOS_DISCREPANCIA,
                    c("D-OK", "D-FMT", "D-DEP", "D-EST", "D-AMB", "D-APP")))

stopifnot(tolerancia_de("completa", NA) == 1e-9)
stopifnot(tolerancia_de("decimales", 3) == 0.0005)
stopifnot(tolerancia_de("decimales", 2) == 0.005)
stopifnot(tolerancia_de("exacta", NA) == 0)
stopifnot(inherits(try(tolerancia_de("holgada", NA), silent = TRUE), "try-error"))

stopifnot(comparar(0.9157, 0.916, tolerancia_de("decimales", 3))$codigo == "D-OK")
stopifnot(comparar(0.9100, 0.916, tolerancia_de("decimales", 3))$codigo == "D-APP")
stopifnot(comparar(NA_real_, 0.916, tolerancia_de("decimales", 3))$codigo == "D-AMB")

# El umbral se prueba moviendo el PARAMETRO, nunca llevando el dato al limite:
# con 0,9152 la diferencia es 0,0008, que cae fuera de la tolerancia de tres
# decimales y dentro de la de dos. Un dato colocado justo en 0,0005 no probaria
# nada, porque el punto flotante no aterriza ahi.
stopifnot(comparar(0.9152, 0.916, tolerancia_de("decimales", 3))$codigo == "D-APP")
stopifnot(comparar(0.9152, 0.916, tolerancia_de("decimales", 2))$codigo == "D-OK")

stopifnot(identical(COLUMNAS_EXPECTATIVAS, c(
  "id_estudio", "modulo", "comparacion", "esperado", "precision",
  "decimales", "decidible", "fuente")))
stopifnot(identical(COLUMNAS_RESULTADOS, c(
  "id_estudio", "nivel", "modulo", "comparacion", "esperado", "obtenido",
  "tolerancia", "codigo", "fuente", "fecha")))
stopifnot(identical(COLUMNAS_COMPUERTAS, c("id_estudio", "compuerta", "fuente",
                                           "estado", "detalle")))
stopifnot(identical(MODULOS, c("calibracion", "necesidad", "tabla_verdad",
                               "minimizacion", "ajuste", "robustez")))
stopifnot(!"agregacion" %in% MODULOS)

fila <- function(id, modulo, esperado, decidible, fuente = "Tabla X",
                 precision = "decimales", decimales = 3) {
  data.frame(id_estudio = id, modulo = modulo, comparacion = "c",
             esperado = esperado, precision = precision, decimales = decimales,
             decidible = decidible, fuente = fuente, stringsAsFactors = FALSE)
}

# 1. El ajuste de un estudio sin `include` publicado no culpa al motor.
amb <- fila("E025", "ajuste", 0.915, "no_tipo_solucion")
stopifnot(codigo_de_la_fila(amb, 0.915) == "D-AMB")
stopifnot(codigo_de_la_fila(amb, 0.100) == "D-AMB")

# 2. Pero la CALIBRACION del mismo estudio si muerde: no depende de la
#    solucion, y absolverla dejaria pasar un fallo real de calibrar().
cal <- fila("E026", "calibracion", 0.79, "si",
            fuente = "columna fhuman de dataset.csv", decimales = 2)
stopifnot(codigo_de_la_fila(cal, 0.79) == "D-OK")
stopifnot(codigo_de_la_fila(cal, 0.11) == "D-APP")
nec <- fila("E025", "necesidad", 0.952, "si", fuente = "Tabla 9")
stopifnot(codigo_de_la_fila(nec, 0.952) == "D-OK")
stopifnot(codigo_de_la_fila(nec, 0.500) == "D-APP")

# 3. Y no se puede absolver por la puerta de atras: marcar `no_tipo_solucion`
#    en un modulo que no depende de la solucion es un error de categoria.
cal_absuelta <- cal
cal_absuelta$decidible <- "no_tipo_solucion"
stopifnot(inherits(try(codigo_de_la_fila(cal_absuelta, 0.11), silent = TRUE),
                   "try-error"))
nec_absuelta <- nec
nec_absuelta$decidible <- "no_tipo_solucion"
stopifnot(inherits(try(codigo_de_la_fila(nec_absuelta, 0.5), silent = TRUE),
                   "try-error"))

# 4. `no_sin_fuente` exige que la ausencia este declarada en `fuente`.
sin_fuente_ok <- fila("E008", "robustez", NA_real_, "no_sin_fuente",
                      fuente = "El estudio no publica escenario alternativo: ausente")
stopifnot(codigo_de_la_fila(sin_fuente_ok, 0.5) == "D-AMB")
sin_fuente_mal <- fila("E008", "robustez", NA_real_, "no_sin_fuente",
                       fuente = "Tabla 6")
stopifnot(inherits(try(codigo_de_la_fila(sin_fuente_mal, 0.5), silent = TRUE),
                   "try-error"))

# 5. Los cuatro estudios cuya minimizacion SI es comparable estan anclados
#    contra estudios.csv, no contra una lista escrita a mano.
est <- utils::read.csv("docs/validacion/estudios.csv", stringsAsFactors = FALSE)
inc <- subset(est, decision == "incluir")
stopifnot(identical(sort(inc$id[inc$mod_minimizacion == "si"]),
                    c("E001", "E008", "E012", "E015")))
for (id in c("E008", "E012", "E015")) {
  f <- fila(id, "minimizacion", 3, "si", precision = "exacta", decimales = NA)
  stopifnot(codigo_de_la_fila(f, 3) == "D-OK")
  stopifnot(codigo_de_la_fila(f, 2) == "D-APP")
}

# 6. Veredicto por estudio: pareja de casos opuestos sobre datos sinteticos.
sint <- data.frame(
  id_estudio = c("X", "X", "Y", "Z", "W"),
  codigo     = c("D-OK", "D-AMB", "D-OK", "D-APP", "D-EST"),
  stringsAsFactors = FALSE)
stopifnot(veredicto(sint, "X") == "reproduccion parcial")
stopifnot(veredicto(sint, "Y") == "reproducido")
stopifnot(veredicto(sint, "Z") == "no reproducido")
stopifnot(veredicto(sint, "W") == "reproduccion parcial")
stopifnot(veredicto(sint, "sin_filas") == "no ejecutable")

cat("contratos de replicacion: en verde\n")
```

- [ ] **Step 2: Ejecutar RED**

Run: `Rscript --vanilla validation/tests/test-contratos-replicacion.R`
Expected: estado distinto de cero porque `comun-replicacion.R` no existe.

- [ ] **Step 3: Implementar el común**

En `validation/R/comun-replicacion.R`:

```r
MODULOS <- c("calibracion", "necesidad", "tabla_verdad", "minimizacion",
             "ajuste", "robustez")

CODIGOS_DISCREPANCIA <- c("D-OK", "D-FMT", "D-DEP", "D-EST", "D-AMB", "D-APP")

VEREDICTOS <- c("reproducido", "reproduccion parcial", "no reproducido",
                "no ejecutable")

COLUMNAS_EXPECTATIVAS <- c("id_estudio", "modulo", "comparacion", "esperado",
                           "precision", "decimales", "decidible", "fuente")
COLUMNAS_RESULTADOS <- c("id_estudio", "nivel", "modulo", "comparacion",
                         "esperado", "obtenido", "tolerancia", "codigo",
                         "fuente", "fecha")
COLUMNAS_COMPUERTAS <- c("id_estudio", "compuerta", "fuente", "estado",
                         "detalle")

# Solo estos tres modulos dependen de que solucion se haya elegido. Los otros
# tres se calculan antes de minimizar, asi que su resultado NO puede excusarse
# con el tipo de solucion.
MODULOS_DEPENDIENTES_DE_SOLUCION <- c("minimizacion", "ajuste", "robustez")

DECIDIBLE <- c("si", "no_tipo_solucion", "no_sin_fuente")

tolerancia_de <- function(precision, decimales) {
  switch(precision,
    completa = 1e-9,
    decimales = 0.5 * 10^(-as.integer(decimales)),
    exacta = 0,
    stop("Precision no admitida: ", precision,
         ". Se admite completa, decimales o exacta.", call. = FALSE))
}

comparar <- function(obtenido, esperado, tolerancia) {
  if (is.na(esperado) || is.na(obtenido)) {
    return(list(codigo = "D-AMB", diferencia = NA_real_))
  }
  d <- abs(obtenido - esperado)
  list(codigo = if (d <= tolerancia) "D-OK" else "D-APP", diferencia = d)
}

# El codigo lo decide la FILA, no el estudio: un absorbedor por estudio
# absolveria tambien su calibracion y su necesidad, que no dependen de la
# solucion. Marcar `no_tipo_solucion` fuera de los tres modulos que si
# dependen de ella es un error de categoria y aborta.
codigo_de_la_fila <- function(fila, obtenido) {
  if (!fila$decidible %in% DECIDIBLE) {
    stop("Valor de `decidible` no admitido: ", fila$decidible, call. = FALSE)
  }
  if (identical(fila$decidible, "no_tipo_solucion") &&
      !fila$modulo %in% MODULOS_DEPENDIENTES_DE_SOLUCION) {
    stop("El modulo ", fila$modulo, " no depende del tipo de solucion: ",
         "no puede marcarse `no_tipo_solucion` (", fila$id_estudio, ", ",
         fila$comparacion, ").", call. = FALSE)
  }
  if (identical(fila$decidible, "no_sin_fuente") &&
      !grepl("ausente|no publica|no publicad", fila$fuente, ignore.case = TRUE)) {
    stop("`no_sin_fuente` exige que la columna `fuente` declare la ausencia: ",
         fila$id_estudio, ", ", fila$comparacion, ".", call. = FALSE)
  }
  if (identical(fila$decidible, "si")) {
    return(comparar(obtenido, fila$esperado,
                    tolerancia_de(fila$precision, fila$decimales))$codigo)
  }
  "D-AMB"
}

# Funcion pura sobre la tabla de resultados: se puede probar con casos
# sinteticos opuestos, que es lo que distingue un veredicto mudo de uno
# ruidoso.
veredicto <- function(res, id) {
  r <- res[res$id_estudio == id, , drop = FALSE]
  if (nrow(r) == 0L) return("no ejecutable")
  if (any(r$codigo == "D-APP")) return("no reproducido")
  if (any(r$codigo %in% c("D-AMB", "D-EST"))) return("reproduccion parcial")
  "reproducido"
}

CACHE_ARTEFACTOS <- Sys.getenv("FSQCA_CACHE_ARTEFACTOS",
                               file.path(tempdir(), "artefactos-replicacion"))

# Descarga fuera del repositorio y verifica el hash. Sin red o con hash
# distinto no hay resultado: hay error.
CACHE_ARTEFACTOS <- Sys.getenv("FSQCA_CACHE_ARTEFACTOS",
                               file.path(tempdir(), "artefactos-replicacion"))

obtener_artefacto <- function(manifiesto, nombre) {
  m <- jsonlite::fromJSON(manifiesto, simplifyDataFrame = FALSE)
  a <- Filter(function(x) identical(x$archivo, nombre), m$artefactos)[[1L]]
  dir.create(CACHE_ARTEFACTOS, recursive = TRUE, showWarnings = FALSE)
  destino <- file.path(CACHE_ARTEFACTOS, a$archivo)
  if (!file.exists(destino)) {
    for (intento in 1:3) {
      ok <- tryCatch({
        utils::download.file(a$url, destino, mode = "wb", quiet = TRUE)
        TRUE
      }, error = function(e) FALSE)
      if (ok && file.exists(destino)) break
    }
  }
  if (!file.exists(destino)) {
    stop("Artefacto no descargable: ", a$archivo, " desde ", a$url,
         ". La replicacion queda NO EJECUTABLE.", call. = FALSE)
  }
  hash <- digest::digest(file = destino, algo = "sha256")
  if (!identical(hash, a$sha256)) {
    stop("El artefacto cambio en origen: ", a$archivo, ". Esperado ",
         a$sha256, ", obtenido ", hash, ".", call. = FALSE)
  }
  destino
}
```

- [ ] **Step 4: Documentar los dominios**

En `docs/validacion/diccionario-replicaciones.md`, definir cada columna de
`validation/expectativas/<ID>.csv`, de `docs/validacion/replicaciones.csv`, de
`docs/validacion/compuertas.csv` y de `docs/validacion/no-ejecutables.csv`; el dominio
cerrado de `modulo` (los seis nombres canónicos), el de `precision`
(`completa`, `decimales`, `exacta`), el de `decidible` (`si`, `no_tipo_solucion`,
`no_sin_fuente`, con `no_tipo_solucion` restringido a `minimizacion`, `ajuste` y
`robustez`) y el de `codigo`:

- `D-OK`: equivalencia dentro de la tolerancia prerregistrada.
- `D-FMT`: diferencia solo de presentación, sin efecto numérico.
- `D-DEP`: diferencia atribuida a una versión o comportamiento de dependencia, con evidencia.
- `D-EST`: inconsistencia interna del estudio, documentada en el prerregistro antes de ejecutar.
- `D-AMB`: el estudio no publica lo necesario para decidir. **No cuenta como aprobación.**
- `D-APP`: defecto o decisión no documentada de `fsqca-calibrador`.

- [ ] **Step 5: Ejecutar GREEN**

Run: `Rscript --vanilla validation/tests/test-contratos-replicacion.R`
Expected: estado 0.

- [ ] **Step 6: Commit**

```bash
git add validation/R/comun-replicacion.R validation/tests/test-contratos-replicacion.R docs/validacion/diccionario-replicaciones.md
git commit -m "test: fijar contratos de replicacion"
```

---

### Task 2: Replicar E025 — intención de compra de ropa inteligente (Nivel B)

**Files:**
- Create: `validation/manifiestos/E025.json`
- Create: `validation/prerregistros/E025.md`
- Create: `validation/expectativas/E025.csv`
- Create: `validation/R/adaptador-E025.R`
- Create: `validation/tests/testthat/test-replicacion-E025.R`

**Interfaces:**
- Consumes: `journal.pone.0291870.s001.csv` y las Tablas 8, 9, 10 y 11 de la publicación.
- Produces: la compuerta de agregación y comparaciones de `calibracion`, `necesidad`, `tabla_verdad`, `ajuste` y `robustez`. `minimizacion` es `no_evaluable`.

- [ ] **Step 1: Escribir el manifiesto**

`validation/manifiestos/E025.json`:

```json
{
  "id_estudio": "E025",
  "nivel": "B",
  "doi": "10.1371/journal.pone.0291870",
  "licencia": "CC-BY-4.0",
  "fecha_verificacion": "2026-08-11",
  "artefactos": [
    {
      "archivo": "journal.pone.0291870.s001.csv",
      "url": "https://journals.plos.org/plosone/article/file?id=10.1371/journal.pone.0291870.s001&type=supplementary",
      "bytes": 16149,
      "sha256": "01712015f25e947bddff4381ab11f40055ca66c8efc359003eb1c39ef870030b"
    }
  ]
}
```

- [ ] **Step 2: Escribir el prerregistro**

`validation/prerregistros/E025.md` fija, antes de ejecutar:

- **Archivo**: 35 columnas, 225 filas de datos, BOM UTF-8, sin columna identificadora.
  Columnas `FUN1–FUN5`, `AES1–AES5`, `EXP1–EXP5`, `PU1–PU5`, `PEOU1–PEOU5`, `ATT1–ATT5`,
  `PI1–PI5`; escala Likert 1–5 (Métodos, «Variables and measures»). Sin códigos de ausente
  ni exclusiones declaradas: se usan las 225 filas.
- **Identificador**: el adaptador crea `caso = seq_len(225)`; el archivo no lo trae.
- **Constructos**: `FUN`, `AES`, `EXP`, `PU`, `PEOU`, `ATTs` (ítems `ATT*`) como
  condiciones y `PIs` (ítems `PI*`) como resultado.
- **Agregación de ítem a constructo: ausente.** Se buscó en «Variables and measures»,
  «Analytical approaches» y «fsQCA results / Calibration» de
  <https://doi.org/10.1371/journal.pone.0291870> el 2026-08-11; el texto declara las anclas
  y remite a la Tabla 8, pero **no** declara cómo se combinan los cinco ítems en el
  constructo. Se prerregistra la **media aritmética de los ítems** como hipótesis y se
  comprueba como **compuerta previa** —fila en `docs/validacion/compuertas.csv`, no en
  `replicaciones.csv`, porque `agregacion` no es un módulo canónico—: si la media y la
  desviación típica de cada conjunto calibrado no reproducen la Tabla 8, la compuerta queda
  en `no_pasa` y todas las filas de E025 se registran `D-AMB`. Esta compuerta **no**
  promueve E025 a Nivel A: la regla la pone este plan, no los autores.
- **Anclas** (Tabla 8, idénticas para las siete variables): plena `5.00`, cruce `3.50`,
  nula `1.00`; fuente de ancla `teoria` («Based on the suggestions made by Fiss»,
  sección «Calibration»). `idm = 0.95`: la Tabla 8 publica mín. `0.05` y máx. `0.95` para
  las siete variables, que es la convención de fs/QCA 3.0, el programa que el artículo
  declara haber usado.
- **Corrección del 0,50**: no declarada por el estudio. Se ejecuta la del motor
  (`+0.001`) y se registra en el informe; si alguna comparación cambia al desactivarla, esa
  comparación pasa a `D-AMB`.
- **Umbrales**: `incl.cut = 0.80`, `pri.cut = 0.75`, `n.cut = 3` (sección «Sufficient
  conditions analysis»).
- **`include`**: ausente, y por eso `mod_minimizacion = no_evaluable` en la selección
  congelada. **No se compara ninguna solución.** La Tabla 10 es la solución intermedia
  —el texto declara que se usan «intermediate and parsimonious solutions to distinguish
  between peripheral and core conditions»— y no se sustituye por la parsimoniosa de la
  aplicación. `minimizar()` se ejecuta porque la tabla de verdad lo exige aguas abajo, y sus
  términos se anotan en el informe como descripción, sin fila de comparación.
- **Ajuste**: `mod_ajuste = si`. La `consistencia_solucion` `0.915` y la
  `cobertura_solucion` `0.881` de la Tabla 10 son las de esa solución intermedia, así que la
  comparación se ejecuta y entra **prerregistrada `D-AMB`**, con el ajuste de la solución que
  la aplicación sí produce anotado al lado. Es la regla general de la sección «Regla de tipo
  de solución y de ajuste».
- **Robustez**: `mod_robustez = si`. Lo que el estudio publica como robustez es la
  **validez predictiva** (Tabla 11 y sección «Predictive validity»): partición aleatoria en
  submuestra y muestra de reserva, los mismos cortes, y dos modelos de la submuestra
  —`M1: FUN*PU*PEOU*ATTs` con cobertura bruta `0.8035`, única `0.4796` y consistencia
  `0.9306`; `M2: ~FUN*AES*~EXP*~PU*PEOU*ATTs` con `0.3435`, `0.0195` y `0.9817`; solución
  `0.8230 / 0.9305`—. **La partición no está publicada**: ni la semilla, ni el tamaño, ni la
  lista de casos de cada mitad; se buscó en la sección «Predictive validity» el 2026-08-11 y
  solo consta «randomly divided into holdout samples and subsamples». Sin ella esos cuatro
  decimales no son reproducibles, así que la comparación entra **prerregistrada `D-AMB`**
  con las cifras publicadas en `esperado` y la razón en el informe. Los valores de la Fig 3
  (consistencia `0.937`, cobertura `0.784`) no se usan: son de figura. Además se ejecuta el
  barrido de anclas y umbrales del paso 7 del motor y se informa como descripción.

- [ ] **Step 3: Escribir las expectativas**

`validation/expectativas/E025.csv` (extracto exacto del encabezado y de las primeras filas;
se completa con las 7 medias y 7 desviaciones de la Tabla 8, las 12 consistencias y 12
coberturas de la Tabla 9 y las cifras de las Tablas 10 y 11). **No hay ninguna fila
`modulo = minimizacion`**: la selección la congeló como `no_evaluable`.

```csv
id_estudio,modulo,comparacion,esperado,precision,decimales,decidible,fuente
E025,calibracion,media_fs_FUN,0.69,decimales,2,si,Tabla 8
E025,calibracion,de_fs_FUN,0.20,decimales,2,si,Tabla 8
E025,calibracion,min_fs_PIs,0.05,decimales,2,si,Tabla 8
E025,calibracion,max_fs_PIs,0.95,decimales,2,si,Tabla 8
E025,calibracion,n_casos,225,exacta,,si,Tabla 8
E025,necesidad,consistencia_fs_ATTs,0.952,decimales,3,si,Tabla 9
E025,necesidad,cobertura_fs_ATTs,0.860,decimales,3,si,Tabla 9
E025,tabla_verdad,filas_observadas,,exacta,,no_sin_fuente,El articulo no publica tabla de verdad: ausente
E025,ajuste,consistencia_solucion,0.915,decimales,3,no_tipo_solucion,Tabla 10 (solucion intermedia)
E025,ajuste,cobertura_solucion,0.881,decimales,3,no_tipo_solucion,Tabla 10 (solucion intermedia)
E025,robustez,consistencia_M1_submuestra,0.9306,decimales,4,no_sin_fuente,Tabla 11 (particion aleatoria no publicada: ausente)
E025,robustez,cobertura_bruta_M1_submuestra,0.8035,decimales,4,no_sin_fuente,Tabla 11 (particion aleatoria no publicada: ausente)
```

Las cinco primeras filas y las dos de necesidad llevan `decidible = si`: **pueden dar
`D-APP`** y son las que ejercitan el motor. Las de ajuste llevan `no_tipo_solucion` —solo
admisible en los tres módulos que dependen de la solución— y las de robustez y tabla de
verdad, `no_sin_fuente`, cuya columna `fuente` tiene que declarar la ausencia.

**`tabla_verdad`**: `mod_tabla_verdad = si` porque el estudio declara los tres umbrales, no
porque publique la tabla. No hay tabla de verdad impresa en el artículo ni en su suplemento;
se buscó en las Tablas 1–11 y en la sección «Sufficient conditions analysis» el 2026-08-11.
La fila entra con `esperado` vacío y código `D-AMB`, y el `obtenido` guarda el número de
filas, sus frecuencias y sus consistencias para que queden publicadas. No se inventa una
cuenta de filas a partir de las seis configuraciones de la Tabla 10: ese número no es el
mismo objeto.

- [ ] **Step 4: Escribir el adaptador**

`validation/R/adaptador-E025.R` lee el CSV verificado, arma el mapeo con la API pública y
no toma ninguna decisión más:

```r
adaptar_E025 <- function(ruta) {
  crudo <- calibraqca::leer_datos(ruta)$datos
  crudo$caso <- seq_len(nrow(crudo))
  mapeo <- calibraqca::definir_mapeo(
    columna_id = "caso", encuestados_por_caso = "uno",
    escala = c(1, 5),
    constructos = list(
      list(nombre = "FUN",  rol = "condicion", items = paste0("FUN", 1:5)),
      list(nombre = "EXP",  rol = "condicion", items = paste0("EXP", 1:5)),
      list(nombre = "AES",  rol = "condicion", items = paste0("AES", 1:5)),
      list(nombre = "PU",   rol = "condicion", items = paste0("PU", 1:5)),
      list(nombre = "PEOU", rol = "condicion", items = paste0("PEOU", 1:5)),
      list(nombre = "ATTs", rol = "condicion", items = paste0("ATT", 1:5)),
      list(nombre = "PIs",  rol = "resultado", items = paste0("PI", 1:5))
    ),
    resultado_mismo_cuestionario = TRUE
  )
  list(crudo = crudo, mapeo = mapeo,
       promedios = calibraqca::promediar_constructos(crudo, mapeo))
}
```

- [ ] **Step 5: Escribir la prueba**

`validation/tests/testthat/test-replicacion-E025.R` compara contra las expectativas leídas
del CSV, nunca contra números escritos en la prueba:

```r
esperado <- function(comparacion) {
  e <- utils::read.csv("validation/expectativas/E025.csv", stringsAsFactors = FALSE)
  e[e$comparacion == comparacion, , drop = FALSE]
}

test_that("la calibracion de E025 reproduce la Tabla 8", {
  ruta <- obtener_artefacto("validation/manifiestos/E025.json",
                            "journal.pone.0291870.s001.csv")
  a <- adaptar_E025(ruta)
  anclas <- calibraqca::definir_anclas(
    plena = 5, cruce = 3.5, nula = 1, fuente = "teoria",
    justificacion = paste("Anclas 5/3.5/1 declaradas en la seccion Calibration",
                          "del articulo, siguiendo la recomendacion de Fiss",
                          "para escalas Likert de cinco puntos."))
  fs <- calibraqca::calibrar(a$promedios$FUN, anclas, idm = 0.95)
  fila <- esperado("media_fs_FUN")
  tol <- tolerancia_de(fila$precision, fila$decimales)
  expect_equal(comparar(mean(fs), fila$esperado, tol)$codigo, "D-OK")
})
```

Las demás pruebas del archivo, con la misma forma: `de_fs_*`, `min/max`, `n_casos` y las
doce consistencias y coberturas de necesidad con `analizar_necesidad()`, que son las
comparaciones que sí pueden dar `D-OK`; y la tabla de verdad con
`construir_tabla_verdad(..., consistencia = 0.80, pri = 0.75, frecuencia = 3)`, el ajuste
con `diagnosticar_suficiencia()` y la validez predictiva, que se ejecutan y **se afirman
como `D-AMB`**, no como `D-OK`:

```r
test_that("el ajuste de E025 no es decidible y se registra asi", {
  fila <- esperado("consistencia_solucion")         # decidible = no_tipo_solucion
  obtenido <- ajuste_de_la_app                      # solucion que la app si produce
  expect_equal(codigo_de_la_fila(fila, obtenido), "D-AMB")
})

test_that("la calibracion y la necesidad de E025 si muerden", {
  expect_equal(codigo_de_la_fila(esperado("media_fs_FUN"), 0.6903), "D-OK")
  expect_equal(codigo_de_la_fila(esperado("media_fs_FUN"), 0.1000), "D-APP")
})
```

`codigo_de_la_fila()` vive en `comun-replicacion.R` y devuelve `D-AMB` **solo** cuando la
fila lo declara y el módulo es uno de los tres que dependen de la solución; con
`calibracion` o `necesidad` compara de verdad, y si alguien intentara marcarlas
`no_tipo_solucion` la función aborta. Así la prueba no puede aprobar por casualidad, no
puede fallar por una diferencia que no es del motor, y no puede absolver a la aplicación de
un fallo suyo.

- [ ] **Step 6: Ejecutar y registrar**

Run: `Rscript --vanilla -e 'testthat::test_file("validation/tests/testthat/test-replicacion-E025.R")'`
Expected: la prueba corre entera. Un `D-APP` **no** se corrige tocando la tolerancia ni el
prerregistro: se investiga y se registra en `docs/validacion/replicaciones.csv`.

- [ ] **Step 7: Commit**

```bash
git add validation/manifiestos/E025.json validation/prerregistros/E025.md validation/expectativas/E025.csv validation/R/adaptador-E025.R validation/tests/testthat/test-replicacion-E025.R
git commit -m "test: replicar E025 contra sus tablas publicadas"
```

---

### Task 3: Replicar E027 — liderazgo académico (Nivel B)

**Files:** los cinco archivos de `E027`, con la misma estructura de la Task 2.

**Interfaces:**
- Consumes: `journal.pone.0320723.s003.csv` y las Tablas 8, 9 y 10.
- Produces: la compuerta de agregación y comparaciones de `calibracion`, `necesidad`, `tabla_verdad` y `ajuste`. `minimizacion` y `robustez` son `no_evaluable`.

- [ ] **Step 1: Manifiesto**

Artefacto `journal.pone.0320723.s003.csv`, 22.728 bytes, SHA-256
`5428111021daf9ec132dc425ab137966f36f724f628e1bbdff99cc7a413ed4f0`, URL
`https://journals.plos.org/plosone/article/file?id=10.1371/journal.pone.0320723.s003&type=supplementary`,
CC BY 4.0, verificado el 2026-08-11.

- [ ] **Step 2: Prerregistro**

- **Archivo**: BOM UTF-8, 35 columnas, 318 filas. Columnas `VG2, VG4, VG5, VG6, VG9, VG10`,
  `MU3–MU6`, `IR2, IR3, IR6, IR7, IR8`, `CS1–CS5`, `PE1–PE5`, `QEU1–QEU5`, `LE1–LE5`.
  Coinciden exactamente con la depuración declarada en Resultados: se eliminaron
  `VG1, VG3, VG7, VG8, VG11`, `MU1, MU2, MU7, MU8` e `IR1, IR4, IR5, IR9`. Sin columna
  identificadora: el adaptador crea `caso = seq_len(318)`.
- **Agregación: declarada.** «This was accomplished by taking an average of the associated
  indicators and using it to generate an index for each construct» (sección de calibración).
  Se comprueba contra la Tabla 8 —media, desviación típica, mínimo y máximo por constructo,
  con dos decimales— como **compuerta previa**, con fila en `docs/validacion/compuertas.csv`
  y ninguna en `replicaciones.csv`: `agregacion` no es un módulo canónico. Aquí la compuerta
  es más fuerte que en E025 y E009 porque la regla la declaran los autores, no el plan; aun
  así su fallo no se atribuye al motor, sino que deja el estudio en `D-AMB`.
- **Anclas**: plena `4`, cruce `3`, nula `2` para las siete variables (Tabla 8), con
  membresías `0.95 / 0.5 / 0.05` declaradas en el texto ⇒ `idm = 0.95`. Fuente de ancla
  `teoria`. Corrección declarada por el estudio: `+0.001` a las membresías iguales a `0.50`.
- **Umbrales**: `incl.cut = 0.8`, `n.cut = 3` (sección de suficiencia). **PRI: ausente.**
  Se buscó «PRI» y «proportional reduction» en el texto completo el 2026-08-11: cero
  coincidencias. Se ejecuta con `pri = 0` y se hace la sensibilidad con `pri = 0.70`; si la
  tabla de verdad cambia entre ambas, sus comparaciones pasan a `D-AMB`.
- **`include`**: ausente ⇒ `mod_minimizacion = no_evaluable`. **No se compara ninguna
  solución**: la Tabla 10 es la intermedia —«The complex solution lacked explanatory value,
  while the parsimonious and intermediate solutions successfully made a distinction between
  the core and peripheral conditions»— y no se sustituye por la parsimoniosa.
- **Ajuste**: `mod_ajuste = si`, con `consistencia_solucion 0.920` y
  `cobertura_solucion 0.890` de esa misma solución intermedia ⇒ comparación ejecutada y
  **prerregistrada `D-AMB`**, con el ajuste de la solución que la aplicación sí produce
  anotado al lado.
- **Robustez**: `no_evaluable`.

- [ ] **Step 3: Expectativas**

`docs/validacion/compuertas.csv` recoge, de la Tabla 8, las 28 cifras de media, desviación
típica, mínimo y máximo de los **promedios por constructo** —la compuerta de agregación,
antes de calibrar, con dos decimales—:
`VG 3.52 / 0.62 / 1.7 / 5`, `MU 3.64 / 0.60 / 2.3 / 5`, `IR 3.69 / 0.61 / 2 / 5`,
`CS 3.58 / 0.69 / 1.2 / 5`, `PE 3.48 / 0.67 / 1.2 / 5`, `QEU 3.56 / 0.68 / 1.2 / 5` y
`LE 3.47 / 0.71 / 1 / 5`. `validation/expectativas/E027.csv` recoge, de la Tabla 9, las seis
consistencias de presencia (`VG 0.898`, `MU 0.922`, `IR 0.942`, `CS 0.916`, `PE 0.904`,
`QEU 0.924`), sus seis de ausencia entre paréntesis y las doce coberturas (3 decimales) para
el módulo `necesidad`; y de la Tabla 10, `consistencia_solucion = 0.920` y
`cobertura_solucion = 0.890` para el módulo `ajuste`, marcadas en su columna `fuente` como
solución intermedia y por tanto `D-AMB`. Las seis configuraciones `S-1` a `S-6` con sus
consistencias y coberturas **no** entran como expectativas de minimización: ese módulo es
`no_evaluable`. Se transcriben en el prerregistro para que el informe pueda enseñarlas junto
a lo que produzca la aplicación, sin compararlas.

- [ ] **Step 4: Adaptador y prueba**

Igual forma que E025: `definir_mapeo()` con los siete constructos y sus ítems reales
(`VG` = `VG2, VG4, VG5, VG6, VG9, VG10`; `MU` = `MU3, MU4, MU5, MU6`;
`IR` = `IR2, IR3, IR6, IR7, IR8`; `CS`, `PE`, `QEU`, `LE` con sus cinco ítems),
`escala = c(1, 5)`, `LE` con rol `resultado`. La prueba resuelve primero la compuerta de
agregación (Tabla 8) y solo después la cadena calibración → necesidad → tabla de verdad →
ajuste. El ajuste se afirma con `codigo_de_la_fila()` sobre una fila con
`decidible = no_tipo_solucion`, que devuelve `D-AMB` para E027 igual que en E025; la
calibración y la necesidad, sobre filas con `decidible = si`, siguen pudiendo dar `D-APP`.

- [ ] **Step 5: Commit**

```bash
git add validation/manifiestos/E027.json validation/prerregistros/E027.md validation/expectativas/E027.csv validation/R/adaptador-E027.R validation/tests/testthat/test-replicacion-E027.R
git commit -m "test: replicar E027 contra sus tablas publicadas"
```

---

### Task 4: Replicar E009 — innovación exploratoria en emprendedores del arte (Nivel B)

**Files:** los cinco archivos de `E009`.

**Interfaces:**
- Consumes: `journal.pone.0348315.s002.xlsx` y las Tablas 5, 8 y 9.
- Produces: comparaciones de necesidad, tabla de verdad, ajuste y robustez. **No** de calibración ni de minimización: `mod_calibracion` y `mod_minimizacion` son `no_evaluable`.

- [ ] **Step 1: Manifiesto**

`journal.pone.0348315.s002.xlsx`, 40.315 bytes, SHA-256
`4e74fbe6859cf3aae69f288a1e0db211c0d2df5c136226e738cff33d1382ebb3`. Se registra también
`journal.pone.0348315.s004.docx` (11.371 bytes,
`851b22c25ab9cf7293d0b0b770cb75f31d4154da94b4bf7e7bffaa434f1ba2a3`) como código NCA
inspeccionado, no como entrada.

- [ ] **Step 2: Prerregistro**

- **Archivo**: una hoja, `DATA`; cabecera en la fila 1; 203 filas; 38 columnas: `No` más
  37 ítems `MSC1–MSC10`, `TC1–TC5`, `SF1–SF6`, `TT1–TT4`, `IP1–IP3`, `MG1–MG3`, `EI1–EI6`,
  escala Likert de 7 puntos. `No` es el identificador. **El archivo no contiene columnas
  calibradas**: se abrieron sus 38 columnas el 2026-08-11 y todas son ítems.
- **Agregación: ausente**, igual que en E025 (buscada en «Measurement» y en el párrafo de
  calibración de <https://doi.org/10.1371/journal.pone.0348315> el 2026-08-11). Se
  prerregistra la media de ítems como hipótesis y su compuerta es exacta: los percentiles
  95, 50 y 5 de cada constructo así construido deben reproducir la Tabla 5
  (`EI 6.167/4.333/1.333`, `IP 6.667/5.000/1.667`, `MG 6.600/4.333/1.667`,
  `MSC 6.000/4.800/1.700`, `SF 5.667/4.333/1.500`, `TC 5.600/4.200/1.200`,
  `TT 6.500/4.000/1.250`), con tres decimales. Es una **compuerta previa**: fila en
  `docs/validacion/compuertas.csv`, ninguna en `replicaciones.csv`, porque `agregacion` no
  es un módulo canónico. Si falla, **todas** las comparaciones de E009 se registran `D-AMB`
  y el estudio queda como no reproducible por información insuficiente, no como fallo de la
  aplicación.
- **Cuantiles**: `stats::quantile(..., type = 7)`, el de R. La elección se prerregistra
  porque fs/QCA puede usar otra definición; una diferencia atribuible solo a eso es `D-DEP`
  y exige mostrar el valor con los dos tipos.
- **Calibración**: `mod_calibracion = no_evaluable`. La compuerta de anclas se ejecuta como
  verificación de la agregación, **no** se informa como módulo de calibración reproducido.
- **Umbrales**: `incl.cut = 0.8`, `pri.cut = 0.8`, `n.cut = 3`, `+0.001` al `0.50`
  (sección de suficiencia; fsQCA 4.0).
- **Expectativas**: Tabla 8 (necesidad, alto y bajo nivel de `EI`, 24 consistencias y 24
  coberturas, 3 decimales) para el módulo `necesidad`, que es el único de E009 que puede dar
  `D-OK`. Del módulo **ajuste**, `consistencia_solucion` `0.923` y `0.929` y
  `cobertura_solucion` `0.625` y `0.391` de la Tabla 9, **prerregistrados `D-AMB`**: el
  artículo declara que «This study primarily relies on the intermediate solution» y no
  publica su `include`. Las siete configuraciones de la Tabla 9 no entran como expectativas:
  `mod_minimizacion` es `no_evaluable`, y no se sustituye la intermedia por la parsimoniosa.
- **Robustez**: se compara la estabilidad de los veredictos de necesidad de la Tabla 8 ante
  el desplazamiento de anclas del barrido del motor. **Su fila lleva `decidible = si`**, con
  `precision = exacta`, y por tanto **puede salir `D-APP`**: esta comparación no depende del
  tipo de solución, depende de la aplicación, y un barrido que voltea un veredicto es un
  defecto de `fsqca-calibrador`, no una ambigüedad del estudio. `test-consolidacion.R`
  comprueba explícitamente que esta fila no esté marcada `no_tipo_solucion`: si lo estuviera,
  un defecto real quedaría absuelto.

- [ ] **Step 3: Adaptador, expectativas y prueba**

Misma forma que E025: `definir_mapeo(columna_id = "No", encuestados_por_caso = "uno",
escala = c(1, 7), ...)` con los siete constructos y sus ítems reales —`MSC` = `MSC1–MSC10`,
`TC` = `TC1–TC5`, `SF` = `SF1–SF6`, `TT` = `TT1–TT4`, `IP` = `IP1–IP3`, `MG` = `MG1–MG3` y
`EI` = `EI1–EI6` con rol `resultado`—. El primer bloque de la prueba es la compuerta de
agregación contra la Tabla 5; los bloques siguientes solo se evalúan si esa compuerta pasa,
y si no pasa se registran `D-AMB` en vez de omitirse.

- [ ] **Step 4: Commit**

```bash
git add validation/manifiestos/E009.json validation/prerregistros/E009.md validation/expectativas/E009.csv validation/R/adaptador-E009.R validation/tests/testthat/test-replicacion-E009.R
git commit -m "test: replicar los modulos declarados de E009"
```

---

### Task 5: Replicar E008 — gestión de la polinización de cultivos (Nivel B)

**Files:** los cinco archivos de `E008`.

**Interfaces:**
- Consumes: `journal.pone.0326226.s003.xlsx` y las Tablas 4 y 7 más el párrafo de necesidad.
- Produces: comparaciones de los seis módulos.

- [ ] **Step 1: Manifiesto**

Los tres suplementos con sus hashes de la tabla de artefactos. Entrada de datos: `s003.xlsx`.

- [ ] **Step 2: Prerregistro**

- **Archivo**: hoja `Sheet1`, cabecera en fila 1, 267 filas; columnas `ICSM`, `EI`,
  `Gender`, `Age`, `Education`, `Agricultural_acreage`, `AT`, `SN`, `PBC`. Las hojas
  `Sheet2` y `Sheet3` están vacías. `Age` llega como texto en parte de las filas y no se
  usa. Sin columna identificadora: `caso = seq_len(267)`.
- **Constructos**: no hay ítems que agregar. `ICSM` es el índice integrado que el propio
  estudio calcula con los pesos del apéndice `s001.docx`; `AT`, `SN` y `PBC` llegan ya
  sumados. Se toman como vienen y se documenta que la construcción del índice **no** se
  replica: no forma parte de ningún módulo del flujo.
- **Anclas** (Tabla 4): `ICSM 70.33 / 53.25 / 28.16`; `AT 15.73 / 11.01 / 4.56`;
  `SN 14.39 / 6.92 / 3.02`; `PBC 13.93 / 13.92 / 9.29`; `EI 14007.67 / 2986.73 / 392.33`.
  Fuente `distribucion muestral`. `idm = 0.95`: el texto declara «0.05 for complete
  disaffiliation; 0.5 for crossover; and 0.95 for complete affiliation».
  **Aviso prerregistrado**: en `PBC` la plena (`13.93`) y el cruce (`13.92`) distan `0.01`;
  `definir_anclas()` las acepta por ser monótonas, pero la membresía resultante es casi
  escalonada. Si la comparación de `PBC` falla, se examina primero esa vecindad y se
  clasifica `D-EST`, no `D-APP`, salvo que el motor difiera de `QCA::calibrate` con las
  mismas anclas.
- **Umbrales**: `incl.cut = 0.8`, `pri.cut = 0.6`, `n.cut = 1` («The original consistency
  threshold, PRI consistency threshold, and case frequency threshold are set to 0.8, 0.6,
  and 1, respectively»).
- **Necesidad**: el estudio publica los valores solo en la **Fig 7**. Por la
  especificación §6 no se usan como prueba numérica. La expectativa es la afirmación del
  texto: ninguna consistencia de necesidad —presencia ni ausencia, alto ni bajo `ICSM`—
  alcanza `0.9`. Comparación proposicional `necesidad_ninguna_supera_0_9`, precisión
  `exacta`.
- **Tipo de solución y `include`**: `mod_minimizacion = si` en la selección congelada, y el
  artefacto lo sostiene: el texto declara que se usan «nested results of simple and
  intermediate solutions to determine core conditions» y la **nota de la Tabla 7 solo define
  dos símbolos, ambos centrales** («● = existence of core condition; ⊗ = loss of core
  condition»), sin símbolo periférico. Los términos exhibidos son, por tanto, los de la
  solución parsimoniosa, que es la que la aplicación puede producir sin `include`. Es la
  diferencia con E025, E026 y E027, cuyas tablas sí distinguen central de periférico. Si aun
  así los términos de la aplicación difieren de la Tabla 7 solo por condiciones adicionales
  compatibles con parsimoniosa ⊆ intermedia, el código es `D-AMB`, no `D-APP`.
- **Expectativas de ajuste y minimización** (Tabla 7): cinco configuraciones, `CPSM1–CPSM3`
  para alto `ICSM` y `CPSM4–CPSM5` para bajo; consistencias `0.832, 0.893, 0.831, 0.879,
  0.902`; coberturas brutas `0.394, 0.324, 0.419, 0.257, 0.334`; únicas `0.101, 0.031,
  0.126, 0.084, 0.161`; solución alta `0.808 / 0.551` y baja `0.870 / 0.418`; tres
  decimales. De la Tabla 4 se comparan además media, desviación, mínimo y máximo de los
  cinco conjuntos calibrados (2 decimales).
- **Robustez**: `mod_robustez = si`, pero el estudio **no publica un escenario alternativo
  de umbrales ni de anclas**. Se buscaron «robust» y «sensitivity» en el texto completo el
  2026-08-11: las coincidencias son prosa de la discusión sobre la combinación de métodos
  —regresión, NCA, fsQCA y prueba de Mann-Whitney—, no una repetición del análisis con otros
  cortes. La comparación entra **prerregistrada `D-AMB`** con esa cita como `fuente`, y el
  barrido de anclas y umbrales del motor se informa como descripción.

- [ ] **Step 3: Adaptador, expectativas y prueba**

```r
adaptar_E008 <- function(ruta) {
  d <- calibraqca::leer_datos(ruta)$datos          # hoja Sheet1, 267 filas
  d$caso <- seq_len(nrow(d))
  anclas <- list(
    ICSM = calibraqca::definir_anclas(70.33, 53.25, 28.16, "distribucion muestral",
      "Anclas del indice integrado publicadas en la Tabla 4 del articulo."),
    AT   = calibraqca::definir_anclas(15.73, 11.01, 4.56, "distribucion muestral",
      "Anclas de actitud publicadas en la Tabla 4 del articulo."),
    SN   = calibraqca::definir_anclas(14.39, 6.92, 3.02, "distribucion muestral",
      "Anclas de norma subjetiva publicadas en la Tabla 4 del articulo."),
    PBC  = calibraqca::definir_anclas(13.93, 13.92, 9.29, "distribucion muestral",
      "Anclas de control conductual percibido publicadas en la Tabla 4; plena y cruce distan 0,01."),
    EI   = calibraqca::definir_anclas(14007.67, 2986.73, 392.33, "distribucion muestral",
      "Anclas de incentivo economico publicadas en la Tabla 4 del articulo.")
  )
  list(crudo = d[, c("caso", "ICSM", "AT", "SN", "PBC", "EI")], anclas = anclas)
}
```

La prueba calibra las cinco variables con `idm = 0.95`, compara media, desviación, mínimo y
máximo contra la Tabla 4, evalúa la proposición de necesidad, construye la tabla de verdad
con `consistencia = 0.8`, `pri = 0.6`, `frecuencia = 1` para `ICSM` y para `~ICSM`, y
compara la solución parsimoniosa y el ajuste contra la Tabla 7.

- [ ] **Step 4: Commit**

```bash
git add validation/manifiestos/E008.json validation/prerregistros/E008.md validation/expectativas/E008.csv validation/R/adaptador-E008.R validation/tests/testthat/test-replicacion-E008.R
git commit -m "test: replicar E008 contra sus tablas publicadas"
```

---

### Task 6: Replicar E026 — transformación digital y marco AMO (Nivel B)

**Files:** los cinco archivos de `E026`.

**Interfaces:**
- Consumes: `dataset.csv` dentro de `journal.pone.0315249.s001.zip` y las Tablas 3, 4, 5 y 6.
- Produces: comparaciones de `calibracion` —contrastada **contra las columnas calibradas del propio archivo**—, `necesidad`, `tabla_verdad`, `ajuste` y `robustez`. `minimizacion` es `no_evaluable`.

- [ ] **Step 1: Manifiesto con artefacto anidado**

El manifiesto declara el ZIP (`e076c63a2f8221f8ab33c74e9e6747d25e81afe4ebcf48f57ff41c744a28ac28`)
y, dentro, `dataset.csv` con su propio SHA-256
`4d8655ba5f66f95f544c073ecc8d4c229266ddf1352c3a8bd4c4af95c04a26ce` y 29.155 bytes. El
adaptador extrae a la caché y vuelve a verificar el hash del archivo interno.

- [ ] **Step 2: Prerregistro**

- **Archivo**: 14 columnas, 459 filas, sin BOM. Crudas: `STKCD` (identificador),
  `humancapital`, `lnexpor`, `tmt`, `absSA`, `localdigital`, `government`, `dtnew`.
  Calibradas publicadas por los autores, con dos decimales: `fhuman`, `fexplor`, `flocal`,
  `fgovern`, `fabs`, `fdtnew`.
- **Correspondencia con la Tabla 3**, verificada el 2026-08-11 comparando los valores de la
  primera fila con las anclas publicadas: `HC = humancapital → fhuman`;
  `IC = lnexpor → fexplor`; `TMT = tmt` (crisp `0/1`, la Tabla 3 marca `/` en el cruce y el
  archivo no trae columna calibrada: entra como condición crisp);
  `SA = absSA → fabs`; `DE = localdigital → flocal`; `GS = government → fgovern`;
  resultado `DT = dtnew → fdtnew`.
- **Anclas** (Tabla 3): `HC 0.34/0.18/0.09`, `IC 6.17/4.92/3.74`, `SA 4.14/3.91/3.67`,
  `DE 0.77/0.28/0.10`, `GS 18.00/16.00/15.00`, `DT 2.56/1.10/0.00`. Fuente
  `distribucion muestral`: el texto declara cuantiles 85, 50 y 15 del dato bruto. Se
  comparan además las anclas recomputadas desde las columnas crudas con las publicadas
  (2 decimales); una diferencia solo por definición de cuantil es `D-DEP` y se documenta
  con los dos valores.
- **Comparación de calibración**: `fsqca-calibrador` calibra las columnas crudas y el
  resultado se compara **fila a fila** con las seis columnas calibradas del archivo,
  tolerancia `0.005` (dos decimales publicados). Son 459 × 6 comparaciones; se registra el
  número de filas fuera de tolerancia por condición, no una sola cifra agregada.
- **Umbrales** (encabezado de la Tabla 5): `n.cut = 4`, `incl.cut = 0.8`, `pri.cut = 0.6`.
- **Robustez** (Tabla 6): dos escenarios publicados, `n.cut = 5` con `incl.cut = 0.8` y
  `n.cut = 4` con `incl.cut = 0.82`; ambos se ejecutan y se comparan sus consistencias,
  coberturas y `cobertura_solucion` (`0.286` y `0.218`) y `consistencia_solucion`
  (`0.794` y `0.815`), tres decimales.
- **`include`**: ausente ⇒ `mod_minimizacion = no_evaluable`. **No se compara ninguna
  solución.** La nota de la Tabla 5 distingue condiciones centrales de periféricas
  («● y ⨂ … condiciones centrales; ⚫ y ⊗ … condiciones periféricas»), es decir que lo
  publicado es la intermedia; no se sustituye por la parsimoniosa de la aplicación.
- **Expectativas**: Tabla 4 (24 consistencias y 24 coberturas de necesidad, 3 decimales)
  para `necesidad`; de la Tabla 5, `cobertura_solucion 0.324` y `consistencia_solucion
  0.790`, y de la Tabla 6 las de los dos escenarios, todas para `ajuste` y `robustez`
  **prerregistradas `D-AMB`** por proceder de la solución intermedia. Las cuatro
  configuraciones `H1, H2, H3a, H3b` y sus consistencias `0.804, 0.792, 0.861, 0.843`,
  coberturas brutas `0.156, 0.174, 0.038, 0.044` y únicas `0.084, 0.101, 0.022, 0.029` se
  transcriben en el prerregistro para exhibirlas junto a lo que produzca la aplicación, sin
  compararlas.

  La calibración de E026 sigue siendo la comparación más fuerte de toda la muestra —459 × 6
  membresías publicadas por los propios autores— y no depende del tipo de solución.

- [ ] **Step 3: Adaptador, expectativas y prueba**

```r
adaptar_E026 <- function(ruta_zip) {
  destino <- file.path(CACHE_ARTEFACTOS, "E026")
  utils::unzip(ruta_zip, files = "dataset.csv", exdir = destino)
  interno <- file.path(destino, "dataset.csv")
  stopifnot(digest::digest(file = interno, algo = "sha256") ==
    "4d8655ba5f66f95f544c073ecc8d4c229266ddf1352c3a8bd4c4af95c04a26ce")
  d <- calibraqca::leer_datos(interno)$datos       # 459 filas, 14 columnas
  list(
    id        = d$STKCD,
    crudo     = d[, c("humancapital", "lnexpor", "absSA", "localdigital",
                      "government", "dtnew")],
    crisp     = d[, "tmt", drop = FALSE],
    publicado = d[, c("fhuman", "fexplor", "fabs", "flocal", "fgovern", "fdtnew")]
  )
}
```

La prueba compara `calibrar()` de cada columna cruda con su columna publicada
(459 filas × 6 condiciones, tolerancia `0.005`), recomputa los cuantiles 85/50/15 y los
contrasta con la Tabla 3, y sigue con necesidad (Tabla 4) y la tabla de verdad
(`consistencia = 0.8`, `pri = 0.6`, `frecuencia = 4`). El ajuste (Tabla 5) y los dos
escenarios de robustez (Tabla 6) se ejecutan y se afirman con `codigo_de_la_fila()` sobre
filas `no_tipo_solucion`, que devuelven `D-AMB`. Las 459 × 6 comparaciones de calibración
van con `decidible = si` y **tienen que poder dar `D-APP`**: son las que ejercitan de
verdad a `calibrar()`.

- [ ] **Step 4: Commit**

```bash
git add validation/manifiestos/E026.json validation/prerregistros/E026.md validation/expectativas/E026.csv validation/R/adaptador-E026.R validation/tests/testthat/test-replicacion-E026.R
git commit -m "test: replicar E026 contra sus columnas calibradas y sus tablas"
```

---

### Task 7: Replicar E012 — mortalidad temprana por COVID-19 en 80 países (Nivel B)

**Files:** los cinco archivos de `E012` más `validation/transcripciones/E012-S2-membresias.csv`.

**Interfaces:**
- Consumes: `journal.pone.0282617.s001.xlsx`, la transcripción verificada de `journal.pone.0282617.s002.doc` y las Tablas 2, 3, 4, 6 y 7.
- Produces: comparaciones de los seis módulos, incluida la **única solución intermedia con expectativas direccionales publicadas** de toda la muestra.

- [ ] **Step 1: Manifiesto**

`journal.pone.0282617.s001.xlsx` (13.393 bytes,
`ce4bdff6e659f14dce5dd0669ebf92b319db2ef176c97c8f0c7a825495e00f20`) y
`journal.pone.0282617.s002.doc` (143.360 bytes,
`60b8dd40d1266527d7f3ccb331edd8ab111b935be5dd20c8d41e49275849152d`).

- [ ] **Step 2: Transcribir S2 y verificar la transcripción**

`journal.pone.0282617.s002.doc` es un documento OLE de Word («Composite Document File V2»,
comprobado con `file` el 2026-08-11) y su tabla no es legible por máquina en el CI. Se versiona
`validation/transcripciones/E012-S2-membresias.csv` con encabezado
`id,country,delayed,past_epidemic,elderly,density,income,yll`, atribución
(«PLOS ONE, CC BY 4.0, S2 Table de 10.1371/journal.pone.0282617»), fecha, hash del `.doc`
de origen y estas tres condiciones de aceptación, que van escritas en el propio archivo:

1. 80 filas cuyos nombres de país coinciden exactamente, y en el mismo orden, con la
   columna `Country` de `journal.pone.0282617.s001.xlsx`;
2. los dos valores que el texto publica —Argentina `yll = 0.921` y Algeria `yll = 0.081`—
   aparecen idénticos;
3. una segunda extracción independiente coincide celda a celda; cualquier celda ilegible se
   deja vacía y **no** se completa por inferencia, y toda comparación que la use es `D-AMB`.

- [ ] **Step 3: Prerregistro**

- **Archivo de datos**: hoja `dataset`; la fila 1 es el título «S1 Table. Dataset of 80
  countries.» y la cabecera real está en la fila 2; 80 filas. Columnas: `Country`,
  `A delayed public-health response`, `Past epidemic experience`,
  `Proportion of elderly in population`, `Population density`,
  `National income per capita`, `YLL rate`. El adaptador salta una fila y renombra a
  `delayed`, `past_epidemic`, `elderly`, `density`, `income`, `yll`.
- **Anclas** (Tabla 2, percentiles 95/50/5): `delayed 75 / 56.50 / 20.90`;
  `elderly 21.95 / 13.13 / 2.64`; `density 462.36 / 99.06 / 10.31`;
  `income 63703.50 / 12200 / 746.50`; `yll 1428.78 / 166.52 / 6.35`. `past_epidemic` es
  **crisp**: la Tabla 2 publica `1` y `0` y una barra en el cruce; entra sin calibrar.
  Fuente `distribucion muestral`.
- **Umbrales**: `incl.cut = 0.80`, `n.cut = 1` («we set the higher consistency threshold at
  0.80 and the frequency cutoff at 1»). **PRI: ausente**; se ejecuta con `pri = 0` y se
  documenta la sensibilidad con `pri = 0.70`.
- **`include`: declarado**. El párrafo «In producing the intermediate solutions…» fija que
  la **presencia** de respuesta tardía, de proporción de mayores y de experiencia previa
  contribuye al `YLL` alto, y su **ausencia** al `YLL` bajo; densidad y renta quedan sin
  expectativa («neither present nor absent»). Esas son las expectativas que recibe
  `minimizar()`, y por eso E012 es el único estudio cuya **solución intermedia** se compara
  numéricamente.
- **Expectativas**: dos memberships del texto (`Argentina 0.921`, `Algeria 0.081`,
  3 decimales) y la transcripción completa de S2 (2 decimales) para calibración; Tablas 3 y
  4 para las ocho configuraciones, sus consistencias y coberturas (2 decimales) y las
  soluciones (`0.79 / 0.63` para alto y `0.80 / 0.67` para bajo); Tablas 6 y 7 para
  robustez con `incl.cut` `0.85` y `0.90`.
- **Necesidad**: el artículo no publica una tabla de necesidad; `mod_necesidad = si` se
  sostiene sobre las afirmaciones del texto. Se ejecuta `analizar_necesidad()` y, a falta de
  valor publicado, la comparación es proposicional: ninguna condición alcanza el umbral que
  el estudio usa para declarar necesidad. Si el texto no fija ese umbral, la comparación es
  `D-AMB` y así se informa.

- [ ] **Step 4: Adaptador, expectativas y prueba**

```r
adaptar_E012 <- function(ruta_xlsx, ruta_transcripcion) {
  # La fila 1 de la hoja `dataset` es el titulo de la tabla, no la cabecera.
  d <- as.data.frame(readxl::read_excel(ruta_xlsx, sheet = "dataset", skip = 1))
  names(d) <- c("country", "delayed", "past_epidemic", "elderly", "density",
                "income", "yll")
  stopifnot(nrow(d) == 80L)
  publicado <- utils::read.csv(ruta_transcripcion, stringsAsFactors = FALSE)
  stopifnot(identical(publicado$country, d$country))
  list(crudo = d, publicado = publicado)
}
```

Las expectativas direccionales que recibe `minimizar()` para el `YLL` alto son la presencia
de `delayed`, `elderly` y `past_epidemic`, y `density` e `income` sin expectativa; para el
`YLL` bajo, las tres ausencias. `past_epidemic` entra crisp, sin calibrar.

- [ ] **Step 5: Commit**

```bash
git add validation/manifiestos/E012.json validation/prerregistros/E012.md validation/expectativas/E012.csv validation/transcripciones/E012-S2-membresias.csv validation/R/adaptador-E012.R validation/tests/testthat/test-replicacion-E012.R
git commit -m "test: replicar E012 con su solucion intermedia declarada"
```

---

### Task 8: Replicar E014 — piloto del impuesto al agua en diez áreas (Nivel B)

**Files:** los cinco archivos de `E014`.

**Interfaces:**
- Consumes: `journal.pone.0301031.s001.csv` y las Tablas 2, 3, 4 y 5.
- Produces: comparaciones de `calibracion` —declarada **no ejercitada por la aplicación**—, `necesidad`, `tabla_verdad` y `ajuste`. `minimizacion` y `robustez` son `no_evaluable`.

- [ ] **Step 1: Manifiesto**

`journal.pone.0301031.s001.csv`, 668 bytes, SHA-256
`e8ee154fec02a51a5e864f04a1cd5150dc119972e6b77b0568a1cdc39d5f9812`.

- [ ] **Step 2: Prerregistro, con la discrepancia documentada antes de ejecutar**

- **Archivo**: BOM UTF-8, 12 columnas, 10 filas. Encabezado literal
  `area, "UI ", TO, TR, TF, TC, WTR2, SE, TS, STR, WAT, TEC`. **La segunda columna se llama
  `UI ` con un espacio final**; el adaptador la referencia con ese nombre exacto y luego la
  renombra, sin `make.names()` silencioso.
- **Datos ya calibrados y calibración NO ejercitada.** `tipo_datos = conjuntos_calibrados`:
  el estudio no publica los valores brutos previos, así que la aplicación no puede calibrar
  nada. La comparación del archivo con la Tabla 2 es **coherencia entre dos artefactos de
  terceros**, y no ejecuta una sola línea de `fsqca-calibrador`. Por eso su fila lleva
  `comparacion = calibracion_no_ejercitada` y el informe la cuenta en una categoría propia:
  **módulo no ejercitado por la aplicación**, nunca como módulo de calibración reproducido.
  `test-consolidacion.R` comprueba que ninguna fila de E014 con módulo `calibracion` entre
  en el recuento de módulos reproducidos.
- **Correspondencia de columnas**, establecida el 2026-08-11 emparejando los valores de las
  diez áreas con la Tabla 2: `STR→C1` (estructura industrial), `WAT→C2` (dotación de agua),
  `TEC→C3` (nivel tecnológico), `TO→C4` (diseño del objeto imponible), `TR→C5` (diseño de
  tipos), `TF→C6` (exenciones), `TC→C7` (modelo de recaudación), `WTR2→C8` (situación de
  recaudación), `SE→C9` (efecto de ahorro de agua), `TS→C10` (supervisión). La columna
  `UI ` es el **resultado**, identificado por eliminación: la Tabla 2 no lo publica. Esa
  identificación se declara como inferencia del plan, no como dato del estudio.
- **Discrepancia prerregistrada**: de las 100 celdas comparables, **89 coinciden** con la
  Tabla 2 dentro de `0.005` y **11 no**: `BEIJING TR 0.00 vs 0.2`, `BEIJING TF 0.00 vs 0.2`,
  `BEIJING TS 0.2 vs 0.6`, `TIANJIN TS 0.2 vs 0.4`, `SHANXI TC 0.00 vs 0.2`,
  `SHANXI TS 0.2 vs 0.6`, `NEIMENG TC 0.00 vs 0.2`, `HENAN TC 0.00 vs 0.2`,
  `SICHUAN TO 0.00 vs 0.2`, `SHANXII TC 0.6 vs 0.8` y `NINGXIA TC 0.8 vs 0.6`. Quedan
  clasificadas `D-EST` **antes** de ejecutar nada; no se corrigen, no se elige la versión
  que convenga y el análisis se ejecuta con el archivo, que es el artefacto publicado como
  dato.
- **Umbrales**: `incl.cut = 0.75` y `n.cut = 1` («the frequency threshold is set to 1, and
  the original consistency threshold is set to 0.75»). Umbral de necesidad `0.9`.
  **PRI ausente** ⇒ `pri = 0` y sensibilidad documentada.
- **Expectativas**: Tabla 4 (diez consistencias y diez coberturas de necesidad,
  2 decimales) y Tabla 3 (dicotomización `0/1` de las diez condiciones en las diez áreas,
  igualdad exacta, 100 celdas), que son las que pueden dar `D-OK`. De la Tabla 5,
  `consistencia_solucion 0.91` y `cobertura_solucion 0.55` para el módulo `ajuste`,
  **prerregistradas `D-AMB`**.
- **`include`**: ausente ⇒ `mod_minimizacion = no_evaluable`. **No se compara ninguna
  solución**, y esta vez el estudio lo dice con todas las letras: «The intermediate solution
  with moderate complexity and strong rationality is selected as the analysis result from
  the three output solutions, and the core conditions and secondary conditions are
  distinguished by the simple solution (Table 5)». Las cuatro configuraciones `H1–H4` con
  sus consistencias `0.92, 1.00, 1.00, 0.83`, coberturas originales `0.25, 0.22, 0.14, 0.14`
  y únicas `0.13, 0.10, 0.06, 0.12` se transcriben en el prerregistro para exhibirlas, no
  para compararlas.
- **Robustez**: `no_evaluable`; el barrido del motor se informa como descripción.

- [ ] **Step 3: Adaptador, expectativas y prueba**

```r
adaptar_E014 <- function(ruta) {
  d <- as.data.frame(readr::read_csv(ruta, show_col_types = FALSE,
                                     name_repair = "minimal"))
  stopifnot(identical(names(d), c("area", "UI ", "TO", "TR", "TF", "TC",
                                  "WTR2", "SE", "TS", "STR", "WAT", "TEC")))
  data.frame(
    area = d$area,
    C1 = d$STR, C2 = d$WAT, C3 = d$TEC, C4 = d$TO, C5 = d$TR,
    C6 = d$TF, C7 = d$TC, C8 = d$WTR2, C9 = d$SE, C10 = d$TS,
    UI = d[["UI "]],                       # resultado, identificado por eliminacion
    stringsAsFactors = FALSE
  )
}
```

`name_repair = "minimal"` no es cosmético: sin él `readr` renombra `UI ` y la comprobación
de encabezado —que es la que detecta que el archivo cambió en origen— dejaría de morder. La
prueba compara primero las 100 celdas contra la Tabla 2 —fila
`calibracion_no_ejercitada`, con las once discrepancias ya prerregistradas como `D-EST`— y
sigue con necesidad (Tabla 4) y la dicotomización de la Tabla 3, que son las que sí ejecutan
el motor. El ajuste de la Tabla 5 se afirma con `codigo_de_la_fila()` sobre una fila
`no_tipo_solucion`, que devuelve `D-AMB`. No se compara ninguna solución.

- [ ] **Step 4: Commit**

```bash
git add validation/manifiestos/E014.json validation/prerregistros/E014.md validation/expectativas/E014.csv validation/R/adaptador-E014.R validation/tests/testthat/test-replicacion-E014.R
git commit -m "test: replicar E014 y dejar registrada su discrepancia de origen"
```

---

### Task 9: Replicar E015 — liquidez operativa y liderazgo femenino (Nivel B)

**Files:** los cinco archivos de `E015` más `validation/transcripciones/E015-S1-2018.csv` y `validation/transcripciones/E015-S1-2021.csv`.

**Interfaces:**
- Consumes: `journal.pone.0302210.s001.pdf` y las Tablas 1, 2, 3, 4 y 5.
- Produces: comparaciones de calibración, necesidad, tabla de verdad, minimización y ajuste. `robustez` es `no_evaluable`.

- [ ] **Step 1: Manifiesto y transcripción verificable**

El dato solo existe en PDF (4 páginas, dos tablas de 60 empresas). Se versionan dos CSV con
encabezado `empresa,WOB,BS,OBH,DQ,BD,CR,QR`, atribución («PLOS ONE, CC BY 4.0, S1 File de
10.1371/journal.pone.0302210»), fecha, SHA-256 del PDF de origen y esta condición de
aceptación escrita en el archivo: la media, la desviación típica, el mínimo y el máximo de
`WOB, BS, OBH, DQ, BD, CR` calculados sobre la transcripción reproducen la **Tabla 1** del
artículo con dos decimales, en los dos años. Es una verificación externa: si la
transcripción tiene un dígito mal, la Tabla 1 lo delata. Mientras esa comprobación no pase,
E015 queda **no ejecutable**.

- [ ] **Step 2: Prerregistro**

- **Casos**: 60 empresas por año, identificadas `1–60`; los dos años son dos análisis
  independientes, no una serie.
- **Resultado y condiciones**: modelo publicado `CR = f(WOB, BS, OBH, DQ, BD)`. La columna
  `QR` del PDF no forma parte del modelo y no se usa.
- **Anclas**: percentiles 95, 50 y 5 de cada variable, calculados sobre los 60 casos de cada
  año («The data is calibrated on the 95th, 50th, and 5th percentiles»), con
  `stats::quantile(type = 7)` y fuente `distribucion muestral`. El artículo **no** publica
  los valores de las anclas: no hay comparación de anclas, solo de resultados aguas abajo.
- **Umbrales**: `n.cut = 1`, `incl.cut = 0.85` («A frequency cutoff of 1 and a consistency
  cutoff of 0.85 were used in both analyses»). **PRI ausente** ⇒ `pri = 0` y sensibilidad.
- **Solución**: el artículo publica explícitamente la **más parsimoniosa** (Quine-McCluskey),
  que es la que se compara. No hay `include` ni solución intermedia que comparar.
- **Expectativas**: Tabla 2 (necesidad de presencia y ausencia en los dos años). **La
  Tabla 2 se publica en porcentajes enteros y así se guarda**: `esperado = 92`, no `0.92`,
  con `precision = decimales` y `decimales = 0`, de modo que `tolerancia_de()` devuelve
  `0.5` **puntos porcentuales**. El esquema de expectativas no tiene columna de escala, así
  que el adaptador multiplica por 100 la consistencia y la cobertura que produce la
  aplicación antes de comparar, y el prerregistro lo deja escrito. Guardar `0.92` con
  `d = 0` daría una tolerancia de `0.5` sobre una escala de `0` a `1`: aprobaría cualquier
  cosa. Tablas 3 y 4 (tablas de verdad de 2018 y 2021: cada fila con
  su vector `0/1`, su `f` entero y sus `Raw-consist`, `PRI-consist` y `SYM-consist` con tres
  decimales; igualdad exacta en el vector y en `f`); Tabla 5 (2018: `~BS*~DQ`, `~BS*OBH`,
  `~BS*BD` con coberturas `0.631/0.593/0.516`, únicas `0.029/0.050/0.023` y consistencias
  `0.805/0.767/0.762`, solución `0.756 / 0.813`; 2021: `WOB*~BS`, `OBH*~DQ`, `WOB*DQ` con
  `0.596/0.488/0.562`, `0.059/0.118/0.059`, `0.841/0.794/0.829`, solución `0.796 / 0.853`).

- [ ] **Step 3: Adaptador, expectativas y prueba**

```r
adaptar_E015 <- function(anio) {
  ruta <- sprintf("validation/transcripciones/E015-S1-%d.csv", anio)
  d <- utils::read.csv(ruta, comment.char = "#", stringsAsFactors = FALSE)
  stopifnot(nrow(d) == 60L,
            identical(names(d), c("empresa", "WOB", "BS", "OBH", "DQ", "BD",
                                  "CR", "QR")))
  percentiles <- function(x) stats::quantile(x, c(0.05, 0.5, 0.95), type = 7,
                                             names = FALSE)
  list(crudo = d[, c("empresa", "WOB", "BS", "OBH", "DQ", "BD", "CR")],
       anclas = lapply(c("WOB", "BS", "OBH", "DQ", "BD", "CR"),
                       function(v) percentiles(d[[v]])))
}
```

La atribución y la regla de aceptación viven en las líneas `#` de cabecera del propio CSV,
que `comment.char = "#"` salta. La prueba verifica primero la Tabla 1 sobre la
transcripción —si falla, E015 queda no ejecutable y no se compara nada más— y sigue con
necesidad (Tabla 2), las tablas de verdad (Tablas 3 y 4) y la solución más parsimoniosa
(Tabla 5), en los dos años por separado.

- [ ] **Step 4: Commit**

```bash
git add validation/manifiestos/E015.json validation/prerregistros/E015.md validation/expectativas/E015.csv validation/transcripciones/E015-S1-2018.csv validation/transcripciones/E015-S1-2021.csv validation/R/adaptador-E015.R validation/tests/testthat/test-replicacion-E015.R
git commit -m "test: replicar E015 desde su transcripcion verificada"
```

---

### Task 10: Replicar E001 — sensibilidad paramétrica en fsQCA (Nivel B)

**Files:** los cinco archivos de `E001`, o el registro de no ejecutable.

**Interfaces:**
- Consumes: el paquete CC0 `doi:10.7910/DVN/27100` y su script oficial.
- Produces: comparaciones de calibración, tabla de verdad, minimización, ajuste y robustez contra la **capa de referencia** del propio estudio. `necesidad` es `no_evaluable`.

- [ ] **Step 1: Abrir el paquete y superar la compuerta de identidad**

Run:

```bash
curl -sS -D - -o /dev/null "https://dataverse.harvard.edu/api/datasets/:persistentId/?persistentId=doi:10.7910/DVN/27100"
```

Expected: `HTTP 200` con JSON. Si vuelve `202` con `x-amzn-waf-action: challenge`, como el
2026-08-11, **la tarea se detiene aquí**: E001 se registra como **no ejecutable** en
`docs/validacion-integral.md` con la fecha, las rutas probadas y la cabecera recibida, no se
crea manifiesto y el corredor no tiene nada que omitir. No se sustituye el paquete por una
copia de otra procedencia ni se transcriben valores del artículo para simular la
replicación.

Con acceso, enumerar **todos** los archivos con su nombre servido, tamaño y suma publicada;
descargarlos a la caché y calcular su SHA-256 con `shasum -a 256`. La compuerta es exacta:
uno y solo uno de los archivos debe tener SHA-256
`58c75ec4d18f1914b0d442f40f19007375014140d7a2827afb0f7f11c8d60aae`, el script oficial
congelado en `docs/validacion/estudios.csv` el 2026-08-10. Si ninguno lo tiene, el paquete
cambió: se registra `D-EST`, se deja E001 no ejecutable y **no** se elige otro archivo por
parecido de nombre.

- [ ] **Step 2: Manifiesto y prerregistro con los nombres reales**

Solo después del Step 1 se escriben `validation/manifiestos/E001.json` y
`validation/prerregistros/E001.md` con los nombres de archivo tal como los sirve Dataverse,
sus hashes, la licencia CC0-1.0 (verificada en DataCite el 2026-08-11: `cc0-1.0`) y la
versión `2.0` del depósito. El prerregistro transcribe del script oficial, sin
interpretarlas, las anclas, los umbrales, el `include` si lo hay, el tipo de solución y los
barridos de anclas, `n.cut` y consistencia que el estudio ejecuta.

- [ ] **Step 3: Fijar la capa de referencia**

E001 es el único incluido cuyas expectativas no salen de una tabla impresa sino de su
**script oficial** (especificación §6: «valores esperados transcritos de la publicación o
producidos por su script oficial»). Por eso su tolerancia es `completa` = `1e-9`: el script
y la aplicación operan sobre los mismos datos con las mismas decisiones y no hay redondeo
de publicación de por medio. Se ejecuta el script en una sesión limpia, se guardan sus
salidas en la caché y las expectativas de `validation/expectativas/E001.csv` se generan
desde esas salidas, con `fuente` = nombre del archivo y objeto producido.

- [ ] **Step 4: Adaptador y prueba**

Los módulos comparados son `calibracion`, `tabla_verdad`, `minimizacion`, `ajuste` y
`robustez`. `necesidad` queda `no_evaluable` y así se informa. Los barridos del estudio se
comparan con `barrido_robustez()` escenario a escenario.

- [ ] **Step 5: Commit**

```bash
git add validation/manifiestos/E001.json validation/prerregistros/E001.md validation/expectativas/E001.csv validation/R/adaptador-E001.R validation/tests/testthat/test-replicacion-E001.R
git commit -m "test: replicar E001 contra su script oficial"
```

Si la tarea terminó en el Step 1, el commit es otro y no crea ninguno de esos archivos.
E001 se anota en `docs/validacion/no-ejecutables.csv`, con encabezado
`id_estudio,motivo,evidencia,fecha`, para que `test-consolidacion.R` pueda distinguir «no
ejecutable con evidencia» de «se me olvidó»: sin esa fila, el guardián falla al no encontrar
la expectativa de minimización que `estudios.csv` declara comparable.

```csv
id_estudio,motivo,evidencia,fecha
E001,deposito inaccesible,HTTP 202 con x-amzn-waf-action challenge en seis rutas de dataverse.harvard.edu,2026-08-11
```

```bash
git add docs/validacion-integral.md docs/validacion/no-ejecutables.csv
git commit -m "docs: registrar E001 como no ejecutable por bloqueo del deposito"
```

---

### Task 11: Consolidar resultados con denominadores separados

**Files:**
- Create: `validation/R/ejecutar-replicaciones.R`
- Create: `docs/validacion/replicaciones.csv`
- Create: `validation/tests/test-consolidacion.R`

**Interfaces:**
- Consumes: los manifiestos, expectativas y pruebas existentes.
- Produces: un CSV de resultados y los conteos que el informe usa sin recalcularlos a mano.

- [ ] **Step 1: Escribir la prueba de consolidación**

En `validation/tests/test-consolidacion.R`. Contenido exacto, ejecutado contra un
juego de datos de prueba y sometido a siete mutaciones antes de escribirlo aquí:

```r
source("validation/R/comun-replicacion.R")

leer <- function(x) utils::read.csv(x, stringsAsFactors = FALSE)

res  <- leer("docs/validacion/replicaciones.csv")
est  <- leer("docs/validacion/estudios.csv")
comp <- leer("docs/validacion/compuertas.csv")
noej <- leer("docs/validacion/no-ejecutables.csv")
inc  <- subset(est, decision == "incluir")

exp_todas <- do.call(rbind, lapply(
  list.files("validation/expectativas", pattern = "[.]csv$", full.names = TRUE),
  leer))
stopifnot(identical(names(exp_todas), COLUMNAS_EXPECTATIVAS))
stopifnot(identical(names(res), COLUMNAS_RESULTADOS))

# Nunca se compara un modulo que el estudio no declara.
for (i in seq_len(nrow(res))) {
  fila <- inc[inc$id == res$id_estudio[i], , drop = FALSE]
  stopifnot(nrow(fila) == 1L)
  stopifnot(fila[[paste0("mod_", res$modulo[i])]] == "si")
}

# Los denominadores no se mezclan.
stopifnot(all(res$nivel == "B"))
stopifnot(sum(inc$nivel == "A") == 0L)

# El dominio de modulos es cerrado: `agregacion` no cabe.
stopifnot(all(res$modulo %in% MODULOS))
stopifnot(all(exp_todas$modulo %in% MODULOS))
stopifnot(all(res$codigo %in% CODIGOS_DISCREPANCIA))
stopifnot(all(exp_todas$decidible %in% DECIDIBLE))

# Las compuertas viven aparte y una compuerta caida arrastra a su estudio.
stopifnot(identical(names(comp), COLUMNAS_COMPUERTAS))
stopifnot(all(comp$estado %in% c("pasa", "no_pasa", "no_aplica")))
for (id in comp$id_estudio[comp$estado == "no_pasa"]) {
  stopifnot(all(res$codigo[res$id_estudio == id] == "D-AMB"))
}

# El tipo de solucion solo excusa a los modulos que dependen de el. Marcar
# `no_tipo_solucion` en calibracion, necesidad o tabla de verdad absolveria a
# la aplicacion de un fallo suyo.
stopifnot(all(exp_todas$modulo[exp_todas$decidible == "no_tipo_solucion"] %in%
              MODULOS_DEPENDIENTES_DE_SOLUCION))

# Toda calibracion y toda necesidad con valor publicado tienen que poder dar
# D-OK: son las comparaciones que si ejercitan el motor.
cal_nec <- exp_todas[exp_todas$modulo %in% c("calibracion", "necesidad") &
                     nzchar(as.character(exp_todas$esperado)), ]
stopifnot(nrow(cal_nec) > 0L, all(cal_nec$decidible == "si"))

# La robustez de E009 mide el barrido del motor, no el tipo de solucion:
# tiene que poder salir D-APP si el barrido voltea un veredicto.
r9 <- exp_todas[exp_todas$id_estudio == "E009" & exp_todas$modulo == "robustez", ]
stopifnot(nrow(r9) > 0L, all(r9$decidible == "si"))

# Los cuatro estudios cuya minimizacion es comparable salen de estudios.csv,
# no de una lista escrita a mano. Cada uno tiene expectativa decidible o esta
# registrado como no ejecutable, con su evidencia.
for (id in inc$id[inc$mod_minimizacion == "si"]) {
  if (id %in% noej$id_estudio) {
    stopifnot(nzchar(noej$evidencia[noej$id_estudio == id]))
    next
  }
  m <- exp_todas[exp_todas$id_estudio == id & exp_todas$modulo == "minimizacion", ]
  stopifnot(nrow(m) > 0L, all(m$decidible == "si"))
}

# Y ninguno de los otros cinco puede traer fila de minimizacion.
for (id in inc$id[inc$mod_minimizacion == "no_evaluable"]) {
  stopifnot(!"minimizacion" %in% res$modulo[res$id_estudio == id])
  stopifnot(!"minimizacion" %in% exp_todas$modulo[exp_todas$id_estudio == id])
}

# E014 no ejercita la aplicacion en calibracion: no cuenta como reproducida.
e014 <- res[res$id_estudio == "E014" & res$modulo == "calibracion", ]
stopifnot(all(e014$comparacion == "calibracion_no_ejercitada"))
stopifnot(!any(e014$codigo == "D-OK"))

# Veredicto por estudio: propiedad, no forma. Pareja de casos opuestos.
sint <- data.frame(
  id_estudio = c("X", "X", "Y", "Z", "W"),
  codigo     = c("D-OK", "D-AMB", "D-OK", "D-APP", "D-EST"),
  stringsAsFactors = FALSE)
stopifnot(veredicto(sint, "X") == "reproduccion parcial")
stopifnot(veredicto(sint, "Y") == "reproducido")
stopifnot(veredicto(sint, "Z") == "no reproducido")
stopifnot(veredicto(sint, "W") == "reproduccion parcial")
stopifnot(veredicto(sint, "sin_filas") == "no ejecutable")

# Sobre los datos reales: ningun estudio con un D-APP o un D-AMB puede quedar
# como reproducido, y el veredicto de cada uno es uno de los cuatro.
for (id in unique(res$id_estudio)) {
  v <- veredicto(res, id)
  stopifnot(v %in% VEREDICTOS)
  if (any(res$codigo[res$id_estudio == id] %in% c("D-APP", "D-AMB", "D-EST"))) {
    stopifnot(v != "reproducido")
  }
}

cat("consolidacion: en verde\n")
```

- [ ] **Step 2: Implementar el corredor**

`validation/R/ejecutar-replicaciones.R` recorre `validation/manifiestos/*.json`, ejecuta el
adaptador y las comparaciones de cada estudio y escribe `docs/validacion/replicaciones.csv`
con las columnas de `COLUMNAS_RESULTADOS`. El corredor **falla** si un manifiesto no tiene
prueba, si una prueba no tiene manifiesto, si una comparación queda sin código o si aparece
un módulo que el estudio no declara.

- [ ] **Step 3: Calcular los veredictos por estudio**

Con las categorías de la especificación §9, aplicadas **solo a los módulos declarados**:
*Reproducido* (todo dentro de tolerancia y sin `D-APP`), *Reproducción parcial* (algún
`D-AMB` o no evaluable, ningún `D-APP`) y *No reproducido* (al menos un `D-APP` en
membresías, selección de filas, solución o ajuste).

El recuento por módulo distingue tres estados y no dos, porque `mod_* == "si"` significa
«el estudio publica algo comparable», no «la aplicación lo reprodujo»:

- **reproducido**: hay al menos una comparación `D-OK` y ninguna `D-APP`;
- **no decidible**: todas sus comparaciones son `D-AMB` —el ajuste de E009, E014, E025,
  E026 y E027, la robustez de E008 y E025, y la tabla de verdad de E025—;
- **no ejercitado por la aplicación**: la comparación no ejecuta el motor. Hoy solo cae aquí
  `calibracion_no_ejercitada` de E014.

Un módulo «no decidible» o «no ejercitado» **no suma** al recuento de módulos reproducidos
en ningún lugar del informe.

- [ ] **Step 4: Ejecutar**

Run:

```bash
Rscript --vanilla validation/R/ejecutar-replicaciones.R
Rscript --vanilla validation/tests/test-consolidacion.R
```

Expected: estado 0 en ambos.

- [ ] **Step 5: Commit**

```bash
git add validation/R/ejecutar-replicaciones.R validation/tests/test-consolidacion.R docs/validacion/replicaciones.csv
git commit -m "feat: consolidar resultados de replicacion por modulo"
```

---

### Task 12: Publicar el informe y alinear README y CITATION

**Files:**
- Create: `docs/validacion-integral.md`
- Modify: `README.md`
- Modify: `README.es.md`
- Modify: `CITATION.cff`
- Create: `validation/tests/test-informe-validacion.R`

**Interfaces:**
- Consumes: `docs/validacion/replicaciones.csv`, `estudios.csv` y `busqueda-ampliada.md`.
- Produces: el documento público y la corrección de toda afirmación que lo exceda.

- [ ] **Step 1: Escribir la prueba del informe**

En `validation/tests/test-informe-validacion.R`:

```r
doc <- paste(readLines("docs/validacion-integral.md", warn = FALSE), collapse = "\n")

# La declaracion de alcance va literal y completa.
stopifnot(grepl("0 estudios de Nivel A", doc, fixed = TRUE))
stopifnot(grepl("ninguno cuenta como validación integral", doc, fixed = TRUE))

# Prohibiciones de redaccion: la frase solo puede aparecer negada.
cuenta <- function(patron) {
  m <- gregexpr(patron, doc, fixed = TRUE)[[1L]]
  if (identical(as.integer(m), -1L)) 0L else length(m)
}
stopifnot(cuenta("validación externa integral") ==
          cuenta("No existe validación externa integral"))
stopifnot(cuenta("varias replicaciones completas") == 0L)

# Cada estudio incluido aparece con su nivel y sus modulos.
est <- utils::read.csv("docs/validacion/estudios.csv", stringsAsFactors = FALSE)
inc <- subset(est, decision == "incluir")
stopifnot(all(vapply(inc$id, function(x) grepl(x, doc, fixed = TRUE), logical(1))))

# Ninguna cifra del informe se escribe a mano.
res <- utils::read.csv("docs/validacion/replicaciones.csv", stringsAsFactors = FALSE)
stopifnot(nrow(res) > 0L)

for (r in c("README.md", "README.es.md")) {
  txt <- paste(readLines(r, warn = FALSE), collapse = "\n")
  stopifnot(!grepl("validada externamente", txt, fixed = TRUE))
}
```

- [ ] **Step 2: Redactar el informe**

`docs/validacion-integral.md` contiene, en este orden: la declaración de alcance literal; el
protocolo y sus tolerancias congeladas; la tabla de artefactos con hashes; una sección por
estudio con sus módulos declarados, sus comparaciones y su veredicto; la tabla de
compuertas previas; la tabla de discrepancias por código; los denominadores **separados**
—`Nivel A: 0 de 0 estudios, no evaluada`, y el recuento de Nivel B por módulo, con sus tres
estados: reproducido, no decidible y no ejercitado por la aplicación—; y los límites: la
minimización solo es comparable en E001, E008, E012 y E015; la muestra no es exhaustiva,
Dataverse global, GESIS y UK Data Service no fueron enumerables e ICPSR exigió credenciales.

- [ ] **Step 3: Corregir README y CITATION**

Toda afirmación de validación externa se limita a lo que el CSV sostiene. Si el proyecto
afirmaba o insinuaba validación con estudios publicados, se sustituye por la declaración de
alcance. `CITATION.cff` no gana coautores ni referencias por replicar un estudio.

- [ ] **Step 4: Ejecutar**

Run: `Rscript --vanilla validation/tests/test-informe-validacion.R`
Expected: estado 0.

- [ ] **Step 5: Commit**

```bash
git add docs/validacion-integral.md README.md README.es.md CITATION.cff validation/tests/test-informe-validacion.R
git commit -m "docs: publicar la validacion modular de Nivel B"
```

---

### Task 13: Corredor de CI sin omisiones

**Files:**
- Modify: `.github/workflows/pruebas.yml`
- Create: `validation/tests/test-sin-omisiones.R`

**Interfaces:**
- Consumes: el corredor y las pruebas de replicación.
- Produces: un trabajo que falla ante cualquier omisión, cualquier `D-APP` y cualquier artefacto que cambió en origen.

- [ ] **Step 1: Escribir el guardián de omisiones**

`validation/tests/test-sin-omisiones.R` falla ante cualquier omisión y, además, ante la
salida más tentadora de todas: que una prueba **redefina a mano** una constante del común en
vez de cargarlo. Si eso ocurriera, el dominio cerrado dejaría de seguir a
`comun-replicacion.R` y el guardián estaría mirando su propia copia. Contenido exacto,
ejecutado y mutado:

```r
# Ninguna prueba puede omitirse, y ninguna puede redefinir por su cuenta una
# constante del comun: si lo hiciera, el dominio cerrado dejaria de seguir a
# comun-replicacion.R y el guardian se quedaria mirando su propia copia.
PROHIBIDOS <- c("testthat::skip", "skip_if", "skip_on", "continue-on-error",
                "if (interactive())")
CONSTANTES <- c("MODULOS", "MODULOS_DEPENDIENTES_DE_SOLUCION", "DECIDIBLE",
                "VEREDICTOS", "CODIGOS_DISCREPANCIA", "COLUMNAS_EXPECTATIVAS",
                "COLUMNAS_RESULTADOS", "COLUMNAS_COMPUERTAS")
FUNCIONES <- c("codigo_de_la_fila", "veredicto", "tolerancia_de", "comparar",
               "obtener_artefacto")
SOURCE <- 'source("validation/R/comun-replicacion.R")'

archivos <- list.files("validation/tests", pattern = "[.]R$",
                       full.names = TRUE, recursive = TRUE)
stopifnot(length(archivos) > 0L)

for (f in archivos) {
  lineas <- readLines(f, warn = FALSE)
  texto <- paste(lineas, collapse = "\n")
  if (basename(f) != "test-sin-omisiones.R") {
    for (p in PROHIBIDOS) {
      if (grepl(p, texto, fixed = TRUE)) stop("Omision en ", f, ": ", p)
    }
  }
  usa <- any(vapply(c(CONSTANTES, FUNCIONES),
                    function(x) grepl(paste0("\\b", x, "\\b"), texto), logical(1)))
  if (usa && basename(f) != "test-sin-omisiones.R") {
    if (!grepl(SOURCE, texto, fixed = TRUE)) {
      stop("La prueba ", f, " usa el comun sin cargarlo: falta ", SOURCE,
           ". Redefinir la constante a mano romperia el dominio cerrado.",
           call. = FALSE)
    }
  }
  redefine <- grep(paste0("^\\s*(", paste(CONSTANTES, collapse = "|"), ")\\s*<-"),
                   lineas, value = TRUE)
  if (length(redefine) > 0 && basename(f) != "test-sin-omisiones.R") {
    stop("La prueba ", f, " redefine una constante del comun: ",
         paste(trimws(redefine), collapse = " | "), call. = FALSE)
  }
}
cat("sin omisiones y sin constantes redefinidas:", length(archivos), "pruebas\n")
```

Comprueba también que cada `validation/manifiestos/*.json` tenga su
`validation/expectativas/*.csv`, su `validation/R/adaptador-*.R` y su
`validation/tests/testthat/test-replicacion-*.R`, y al revés.

- [ ] **Step 1b: Escribir el verificador de la tabla de módulos**

`validation/tests/test-tabla-modulos-del-plan.R` sostiene la afirmación «copia literal» de
la tabla de módulos: compara las 54 celdas contra `docs/validacion/estudios.csv` y **aborta**
si alguna se desvía o si sobra o falta una fila. Es lo que un `print()` no puede hacer.

```r
# La tabla de modulos del plan dice ser copia literal de estudios.csv. Esto lo
# comprueba: no imprime, ABORTA. Un volcado con print() no puede fallar.
plan <- "docs/superpowers/plans/2026-08-11-replicaciones-seleccionadas.md"
lineas <- readLines(plan, warn = FALSE)
est <- utils::read.csv("docs/validacion/estudios.csv", stringsAsFactors = FALSE)
inc <- est[est$decision == "incluir", ]
inc <- inc[order(inc$id), ]
mods <- grep("^mod_", names(est), value = TRUE)
stopifnot(identical(mods, c("mod_calibracion", "mod_necesidad",
                            "mod_tabla_verdad", "mod_minimizacion",
                            "mod_ajuste", "mod_robustez")))

faltan <- character(0)
for (i in seq_len(nrow(inc))) {
  esperada <- paste0("| ", inc$id[i], " | ",
                     paste(unlist(inc[i, mods]), collapse = " | "), " |")
  if (!any(trimws(lineas) == esperada)) faltan <- c(faltan, esperada)
}
if (length(faltan) > 0) {
  stop("La tabla de modulos del plan no coincide con estudios.csv. Faltan:\n",
       paste(faltan, collapse = "\n"), call. = FALSE)
}

# Y ninguna fila de mas: la tabla tiene exactamente los estudios incluidos.
patron <- "^\\| E[0-9]{3} \\| (si|no_evaluable) \\|"
filas_tabla <- grep(patron, trimws(lineas), value = TRUE)
stopifnot(length(filas_tabla) == nrow(inc))

cat("tabla de modulos del plan: coincide con estudios.csv en",
    nrow(inc) * length(mods), "celdas\n")
```

- [ ] **Step 2: Añadir el trabajo `replicaciones`**

En `.github/workflows/pruebas.yml`, un trabajo nuevo con el mismo entorno que `testthat`
(`setup-r` 4.6.1, `setup-renv`, las mismas dependencias de sistema), que ejecuta:

```yaml
      - name: Contratos y guardianes
        run: |
          Rscript --vanilla validation/tests/test-contratos-replicacion.R
          Rscript --vanilla validation/tests/test-sin-omisiones.R
          Rscript --vanilla validation/tests/test-tabla-modulos-del-plan.R

      - name: Replicaciones
        run: |
          rm -f docs/validacion/replicaciones.csv docs/validacion/compuertas.csv
          Rscript --vanilla validation/R/ejecutar-replicaciones.R
          Rscript -e '
            for (f in c("docs/validacion/replicaciones.csv",
                        "docs/validacion/compuertas.csv")) {
              if (!file.exists(f)) stop("El corredor no produjo ", f, ".")
            }
            r <- as.data.frame(testthat::test_dir("validation/tests/testthat",
                                                  reporter = "silent"))
            fallos <- sum(r$failed) + sum(r$error)
            cat("PASAN   :", sum(r$passed), "\n")
            cat("FALLOS  :", fallos, "\n")
            cat("OMITIDAS:", sum(r$skipped), "\n")
            if (fallos > 0) stop("Hay replicaciones en rojo.")
            if (sum(r$skipped) > 0) stop("Hay pruebas omitidas: una prueba omitida es una prueba que no existe.")
          '

      - name: Consolidacion e informe
        run: |
          Rscript --vanilla validation/tests/test-consolidacion.R
          Rscript --vanilla validation/tests/test-informe-validacion.R
```

`rm -f` antes de correr no es decorativo: sin él, el paso siguiente podría estar leyendo el
CSV de la ejecución anterior y cantar verde con el corredor roto.

Sin `continue-on-error` en ningún paso ni en el trabajo. Una fuente caída deja el trabajo en
rojo con el mensaje del `obtener_artefacto()`, que es exactamente lo que se quiere: la
replicación no es reproducible hoy y el informe no puede decir lo contrario.

- [ ] **Step 3: Verificar**

Run:

```bash
Rscript --vanilla validation/tests/test-sin-omisiones.R
rg -n 'continue-on-error|skip_if|skip_on|testthat::skip' .github/workflows/pruebas.yml validation/
git diff --check
```

Expected: la primera termina en 0 y la segunda no encuentra nada fuera del propio guardián.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/pruebas.yml validation/tests/test-sin-omisiones.R
git commit -m "ci: correr las replicaciones sin omisiones"
```

---

## Autoauditoría del plan (Step 4 del plan anterior)

Comprobado antes del commit, el 2026-08-11:

- **Marcadores**: `rg -n 'TBD|TODO|XXX|FIXME|\bpendiente\b|\[por definir\]'` sobre este
  archivo solo se encuentra a sí mismo, y `rg -n '…'` deja únicamente citas literales
  abreviadas de títulos y párrafos, nunca una ruta, un nombre de archivo ni un valor. Donde falta un dato, hay una **declaración de
  ausencia** con qué se buscó, en qué URL y en qué fecha: agregación de E025 y E009, `PRI`
  de E012, E014, E015 y E027, `include` de siete estudios, anclas publicadas de E015 y
  nombres de archivo de E001.
- **Tolerancias posteriores**: todas las tolerancias derivan de la precisión publicada por
  la fuente citada y están fijadas antes de ejecutar. No hay ninguna tolerancia elegida
  «con holgura»; `tolerancia_de()` rechaza cualquier valor que no venga de la precisión.
- **Estudios sin licencia**: los nueve tienen licencia compatible verificada — ocho CC BY
  4.0 en el registro editorial de PLOS y E001 CC0-1.0 confirmada en DataCite el
  2026-08-11. No hay ningún estudio sin licencia en el plan.
- **Expectativas sin fuente**: cada fila de `validation/expectativas/<ID>.csv` lleva su
  columna `fuente` con la tabla o el párrafo exacto. Las de E008 sobre necesidad no son
  numéricas porque el estudio solo las publica en una figura, y así se declara.
- **Mezcla A/B**: el plan no planifica ningún módulo de Nivel A, la declaración de alcance
  es literal y obligatoria, `test-consolidacion.R` falla si aparece una fila con
  `nivel != "B"` o si se compara un módulo que el estudio no declara.
- **Rutas inexistentes**: las rutas que se leen ya existen en el repositorio
  (`docs/validacion/estudios.csv`, `pkg/calibraqca/`, `.github/workflows/pruebas.yml`); las
  demás son creaciones declaradas en la sección «Estructura de archivos» y en el bloque
  **Files** de su tarea.

### Segunda pasada, 2026-08-11 (revisión independiente)

La primera versión de este plan copió mal la tabla de módulos: seis celdas de E014, E025,
E026 y E027 no coincidían con `docs/validacion/estudios.csv`, y de ahí salían cuatro tareas
que planificaban comparaciones de minimización sobre estudios cuya selección congelada las
había declarado `no_evaluable`. La tabla se regeneró con el comando que ahora acompaña a la
sección y las cuatro tareas se reescribieron. Reglas que nacieron de ese error y que este
plan conserva porque valen más que el arreglo puntual:

- La selección congelada manda sobre el plan, nunca al revés. Cualquier tabla que diga ser
  copia literal de un CSV se genera con un comando, no a mano.
- **Una diferencia de tipo de solución nunca se clasifica `D-APP`.** Comparar la intermedia
  publicada con la parsimoniosa de la aplicación habría producido `D-APP` en cuatro
  estudios: cuatro acusaciones falsas contra el motor.
- Un módulo `si` en el CSV significa «el estudio publica algo comparable», no «la aplicación
  lo reprodujo». De ahí los tres estados del recuento: reproducido, no decidible y no
  ejercitado por la aplicación.
- Una tolerancia solo es correcta **en la escala en que está guardado el valor esperado**:
  `0.5 * 10^0` es media unidad, y sobre una proporción de 0 a 1 aprueba cualquier cosa.

### Tercera pasada, 2026-08-11 (el arreglo abrió tres puertas)

La corrección anterior cerró seis hallazgos y abrió otros tres, todos de la misma familia:
**el defecto no muere, se muda**. Se cerraron así, y cada aserción nueva se ejecutó contra
un juego de datos de prueba y se sometió a una mutación que la puso roja:

1. **El guardián no podía ejecutarse.** `test-consolidacion.R` usaba `MODULOS` y
   `COLUMNAS_COMPUERTAS` sin `source("validation/R/comun-replicacion.R")`: abortaba con
   `object 'COLUMNAS_EXPECTATIVAS' not found`. Se añadió el `source()`, y el guardián de
   omisiones ahora **prohíbe redefinir a mano** cualquier constante del común y exige el
   `source()` a toda prueba que lo use. Sin eso, el arreglo natural —copiar la constante—
   habría desconectado el dominio cerrado de su única fuente.
2. **El absorbedor podía absolver a la aplicación.** `codigo_por_tipo_de_solucion()` miraba
   el estudio y no el módulo: con una fila de `calibracion` de E026 devolvía `D-AMB` aunque
   el valor obtenido fuera `0.11` frente a `0.79`. Se sustituyó por `codigo_de_la_fila()`,
   que decide por fila, exige que `no_tipo_solucion` solo aparezca en los tres módulos que
   dependen de la solución, y aborta si alguien la usa en `calibracion`, `necesidad` o
   `tabla_verdad`. La **robustez de E009** salió del absorbedor: mide el barrido del motor y
   tiene que poder ser `D-APP`. Y la lista de estudios con minimización comparable dejó de
   escribirse a mano: sale de `mod_minimizacion == "si"` en `estudios.csv`.
3. **La copia literal no tenía quien la sostuviera.** El `print()` se sustituyó por
   `validation/tests/test-tabla-modulos-del-plan.R`, que compara las 54 celdas y aborta, y
   que corre en el CI.
4. **Una aserción que no podía fallar.** `stopifnot(is.logical(vapply(..., logical(1))))` es
   verdadera para cualquier contenido del CSV: `vapply(..., logical(1))` siempre devuelve
   `logical`. Era una aserción de FORMA donde hacía falta una de PROPIEDAD. Se sustituyó por
   `veredicto()`, función pura sobre la tabla, probada con la **pareja de casos opuestos**
   —un estudio con `D-AMB` que no puede quedar como reproducido y otro sin él que sí—.
5. **Un umbral llevado al dato, no al parámetro.** La prueba de contratos comparaba `0.9155`
   con `0.916` esperando `D-OK` a tres decimales: la diferencia en coma flotante es
   `0.0005000000000000004` y la aserción fallaba. Se movió el **parámetro**: la misma pareja
   de valores da `D-APP` con `decimales = 3` y `D-OK` con `decimales = 2`.
