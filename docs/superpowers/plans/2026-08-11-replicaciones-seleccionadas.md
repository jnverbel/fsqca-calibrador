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
  filas de tabla de verdad y soluciones normalizadas. **`d` no se declara: se cuenta sobre
  la cadena publicada.** `esperado` guarda el valor tal como lo imprime el estudio —`0.860`,
  no `0.86`—, se lee como texto y de esa cadena sale `d`. Un cero final es información: una
  columna `decimales` aparte es una segunda copia del mismo dato, y la copia se puede
  desviar (guardar `0.860` como `0.86` con `d = 2` multiplica la tolerancia por diez).
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
  la búsqueda, y la comparación que dependa de él se clasifica `D-AMB` **por la regla
  estructural de la sección siguiente**, nunca por una nota escrita al lado del dato.
- **Cada comparación prerregistrada está contada antes de ejecutar.** El manifiesto de cada
  estudio congela, módulo a módulo, **cuántas comparaciones tiene**, y ese número sale de
  contar las celdas de la tabla publicada, no de contar las filas que uno escribió después.
  Sin ese censo, la absolución más simple de todas —borrar la fila— no la ve nadie.

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

**Este plan no copia la tabla.** La copió una vez, con seis celdas mal, y el arreglo fue
añadir una prueba que demostrara que la copia era copia: una tabla a mano más un verificador
de la tabla cuesta más que no tener tabla. Los módulos de cada estudio salen de
`docs/validacion/estudios.csv` en el momento de usarlos —el corredor y los guardianes leen
el CSV, no este documento— y quien quiera verlos lo imprime:

```bash
Rscript --vanilla -e 'x <- read.csv("docs/validacion/estudios.csv"); i <- subset(x, decision == "incluir"); print(i[order(i$id), c("id", grep("^mod_", names(x), value = TRUE))], row.names = FALSE)'
```

Solo se planifican las celdas `si`; `no_evaluable` no se replica y se informa como tal.

**`minimizacion` es `si` en cuatro estudios y solo cuatro: E001, E008, E012 y E015.** Eso no
se escribe a mano en ningún guion: `test-contratos-replicacion.R` lo afirma en una línea
contra el CSV, que es lo único que hace falta sostener. En
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

- **Una diferencia atribuible al tipo de solución nunca se clasifica `D-APP`.** Eso no se
  decide comparando términos a ojo: lo decide `decidible = no_tipo_solucion`, cuya
  precondición es `mod_minimizacion == "no_evaluable"` en la selección congelada. Donde esa
  precondición no se cumple —E001, E008, E012 y E015— la solución **sí** es reproducible y no
  hay nada que excusar.
- **Esa excusa la lleva la FILA, no el estudio, y su precondición es estructural, no una
  palabra escrita en un texto libre.** La columna `decidible` de
  `validation/expectativas/<ID>.csv` admite exactamente tres valores:
  - `si`: se compara de verdad y puede salir `D-APP`.
  - `no_tipo_solucion`: solo en `minimizacion`, `ajuste` y `robustez`, **y solo si
    `estudios.csv` declara `mod_minimizacion == "no_evaluable"`** para ese estudio. Devuelve
    `D-AMB`.
  - `no_ejercitado`: solo en `calibracion`, **y solo si `estudios.csv` declara
    `tipo_datos == "conjuntos_calibrados"`** para ese estudio —hoy E014 y solo E014—. El
    estudio publica los conjuntos ya calibrados y no publica el bruto previo: la aplicación
    no calibra nada, así que la comparación no dice nada sobre el motor. Devuelve `D-EST`,
    nunca `D-OK`.

  Las dos precondiciones se resuelven contra la selección congelada. **Ninguna se satisface
  escribiendo algo en una celda de texto libre**, que es por donde el absorbedor se mudó
  cuatro veces. La marca `no_insumo_ausente` de la revisión anterior **desaparece**: no
  cubría ni un caso que `no_tipo_solucion` no cubriera —la robustez de E025 es el único, y
  su `mod_minimizacion` es `no_evaluable`— y su alcance era más ancho que el de la marca a
  la que sustituía, porque bastaba una línea en un CSV que nadie podía falsar.
- **`calibracion`, `necesidad` y `tabla_verdad` se calculan desde el artefacto verificado**,
  así que **ninguna fila suya admite un `decidible` distinto de `si`** —salvo `no_ejercitado`
  en la calibración de un estudio que no publica bruto—. Es lo que impide que un fallo real
  de `calibrar()` sobre las 459 × 6 membresías de E026 quede absuelto. La garantía es sobre
  el `decidible` de una fila que existe, y **no** dice que el módulo entero sea comparable:
  que un módulo sea comparable lo dice `estudios.csv`, y desde la auditoría de celdas del
  2026-08-13 `tabla_verdad` sólo está declarado en **E012 y E015**, los dos únicos estudios
  que publican una tabla de verdad de verdad —filas con su frecuencia, sus consistencias y
  sus casos—. Los demás publican la **tabla de soluciones**, que es `minimizacion` y
  `ajuste`. Hasta la revisión anterior esta frase decía «no admiten absolución de ninguna
  clase», que era una promesa más ancha que lo que el código sostiene.
- **Sin valor publicado no hay fila, y una fila sin valor aborta.** `esperado` vacío no
  devuelve `D-AMB`: **detiene el guardián**. Vaciar la celda era la absolución más barata que
  quedaba —`is.na(esperado)` daba `D-AMB` y nadie exigía que el valor existiera—. Un módulo
  declarado `si` en el que el estudio no publique **nada** comparable iría en
  `SIN_EXPECTATIVA_PUBLICADA`, que se comprueba en las dos direcciones: ahí tiene que haber
  **cero** filas y en cualquier otro módulo declarado **al menos una**. Hoy la lista está
  **vacía**, porque los dos casos que tenía —la tabla de verdad de E025 y la robustez de
  E008— resultaron ser exactamente lo que la auditoría de celdas comprobó: módulos que el
  estudio no publica, y eso se declara apagando la celda en `estudios.csv`, no listando una
  excepción al lado.
- **El código no se cree ni se escribe: se DERIVA.** `codigo_de_la_fila()` es una función
  total de la fila, el valor obtenido, la selección congelada y el estado de la compuerta, y
  `test-consolidacion.R` exige que el código escrito en `replicaciones.csv` sea exactamente
  el derivado, sin excepciones. **El registro `discrepancias-prerregistradas.csv` se
  elimina**: era otro texto libre decidiendo un código —bastaba una fila con un motivo y una
  fecha para apartarse del dato—, y su único caso real, la calibración no ejercitada de E014,
  ahora se deriva de `tipo_datos` en la selección congelada. Por eso los códigos bajan de
  seis a cuatro: `D-FMT` y `D-DEP` no tenían derivación y solo podían asignarse por esa
  puerta. Si al ejecutar aparece un `D-APP` que se sospecha de formato o de dependencia, se
  investiga y se narra en el informe con los dos valores; el CSV sigue diciendo `D-APP`
  hasta que el plan cambie en un commit propio. Es más ruidoso, y esa es la dirección segura.
- **La tolerancia sale del dato, y el dato tiene que ser uniforme dentro de su tabla.** No
  hay columna `decimales` que declarar: `tolerancia_de()` cuenta los decimales de la cadena
  `esperado`. `"92"` da `0.5` puntos porcentuales, `"0.92"` da `0.005` y `"0.860"` da
  `0.0005`. Eso cierra la *divergencia entre dos copias* de la precisión, pero **no** cierra
  el fondo: la tolerancia la fija una cadena que ningún artefacto del repositorio ancla al
  artículo, y `1.00` transcrito como `1` da media unidad de tolerancia y aprueba un `0.55`
  contra una necesidad perfecta. Ni siquiera hace falta mala fe: un round-trip de hoja de
  cálculo que quite ceros finales infla diez o cien veces las tolerancias de un archivo
  entero.

  Lo que sí se puede exigir sin conocimiento externo: **una tabla publicada imprime todas sus
  celdas con la misma precisión**, así que dentro de cada `(id_estudio, fuente)` el número de
  decimales de `esperado` es **constante**. Una fila que baja de tres a dos decimales es el
  exploit; un archivo al que le quitaron los ceros finales es el accidente; los dos chillan.
  Esta comprobación sustituye a `stopifnot(is.character(exp_todas$esperado))`, que era una
  aserción que no podía fallar: afirmaba una propiedad de `leer_csv()`, que fuerza
  `colClasses = "character"`.

  **La clave del grupo es `(id_estudio, fuente)`, y hacen falta DOS restricciones, no una.**
  Con `fuente` como única clave la comprobación se esquivaba sin inventar nada: bastaba **mudar
  la fila a la tabla hermana** del mismo estudio, impresa con menos decimales y en la misma
  escala —E025 publica la Tabla 8 a dos decimales y la Tabla 9 a tres—.
  Pero sustituir la clave por `modulo` **rompe con datos legítimos y abre otro agujero**, y las
  dos cosas están medidas: la `calibracion` de E012 saca dos membresías del texto a tres
  decimales y la transcripción de la S2 a dos, así que agrupar por módulo aborta el guardián; y
  E008 publica su Tabla 7 a tres decimales para `minimizacion` **y** para `ajuste`, de modo que
  quitarle un decimal solo a las filas de `ajuste` deja ese grupo uniforme y multiplica su
  tolerancia por diez.

  Las dos particiones **se cruzan**: `E008 Tabla 7` → `{minimizacion, ajuste}`,
  `E012 Tabla 3` → `{minimizacion, ajuste}` y `E015 Tabla 5` → `{minimizacion, ajuste}`, los
  tres sostenidos por la prosa de sus tareas. Por eso ninguna sustituye a la otra:

  - **uniformidad por `(id_estudio, fuente)`**: una tabla publicada imprime todas sus celdas
    con la misma precisión, la cite el módulo que la cite;
  - **pertenencia por módulo**: `fuente` se declara en el manifiesto **indexada por módulo**,
    así que una fila de `necesidad` no puede migrar a la `Tabla 8` porque esa tabla no está
    declarada para `necesidad`.

  Y el guardián exige aparte que la `fuente` del resultado sea la de su expectativa. **Lo que
  queda abierto**: los grupos de una sola fila no restringen nada, y una tabla en la que
  *todos* los valores terminan en cero pierde los ceros de forma uniforme y pasa.
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
- **`robustez` sólo está declarada en E001, E012 y E026** desde la auditoría de celdas del
  2026-08-13. En E001 y E012 la excusa `no_tipo_solucion` es **estructuralmente imposible**
  —su `mod_minimizacion` es `si`—, así que sus filas de robustez sólo pueden llevar
  `decidible = si` y **tienen que poder salir `D-APP`**: un barrido de umbrales que no
  reproduce el escenario alternativo publicado sería un defecto de `fsqca-calibrador`. En
  E026 sí cabe `no_tipo_solucion`, porque los dos escenarios de su Tabla 6 son soluciones
  intermedias. La aserción que hasta esta revisión sostenía esa propiedad —«la robustez de
  E009 lleva `decidible = si`»— **desaparece con el módulo**: E009 no publica ninguna cifra
  alternativa (varía PRI `0.80`→`0.85` y frecuencia `3`→`4` y no publica nada), así que su
  `mod_robustez` es `no_evaluable` y no tiene filas que exigir. El barrido del motor se sigue
  ejecutando en E009 y se informa como **descripción**, sin comparación.
- **Qué estudios tienen minimización comparable no se escribe a mano**: sale de
  `mod_minimizacion == "si"` en `docs/validacion/estudios.csv` (E001, E008, E012 y E015).
- **«No ejecutable» no es un botón.** Un estudio solo puede declararse no ejecutable en su
  manifiesto si está en `ESTUDIOS_NO_EJECUTABLES`, hoy `"E001"` y nada más, y el guardián lo
  comprueba en las dos direcciones: quien está ahí **tiene** que declararlo y quien no está
  **no puede**. Además, un manifiesto no ejecutable no puede tener artefactos: absolver un
  estudio entero exigiría borrar los SHA-256 que el trabajo de campo verificó. El registro
  `docs/validacion/no-ejecutables.csv` desaparece —era una fila de texto libre que absolvía
  un estudio completo, el absorbedor más ancho de todos— y su contenido vive en el
  manifiesto, que es la ficha de procedencia del estudio.

## Censo de comparaciones

Es la pieza que faltaba, y la que cierra la mudanza más simple: **borrar la fila**. Hasta la
revisión anterior nada contaba cuántas expectativas debía tener cada estudio, así que quitar
una comparación incómoda —o quitar el estudio entero— dejaba el CI en verde y **subía** el
veredicto.

El manifiesto de cada estudio congela, en un bloque `comparaciones`, cuántas comparaciones
tiene cada módulo declarado. `test-consolidacion.R` exige:

1. **Un manifiesto por estudio incluido, ni uno más ni uno menos.** El conjunto sale de
   `estudios.csv`, no de lo que haya en el directorio.
2. **Las claves de `comparaciones` son exactamente los módulos `mod_* == "si"`** de ese
   estudio, otra vez contra la selección congelada.
3. **`n` filas en `validation/expectativas/<ID>.csv` y `n` filas en
   `docs/validacion/replicaciones.csv`** para cada módulo, y `n = 0` solo donde
   `SIN_EXPECTATIVA_PUBLICADA` lo admite.
4. **Biyección por nombre**: cada expectativa tiene exactamente una fila de resultado y cada
   resultado exactamente una expectativa, sin duplicados. El `if (nrow(f) != 1L) next` del
   recálculo —que dejaba pasar una fila de resultado con una `comparacion` inventada— es
   ahora un `stop()`.
5. **Cada estudio ejecutable tiene sus cuatro archivos**: manifiesto, expectativas,
   adaptador y prueba. Borrar la prueba de un estudio es otra forma de borrar la fila.

El número no sale de contar las filas escritas: sale de **contar las celdas de la tabla
publicada** antes de escribirlas, en el Step 1 de la tarea de cada estudio. Si al
transcribirlas no coincide, sobra o falta una fila, no sobra el conteo. Y el informe publica
ese conteo junto a su fuente, de modo que una reducción se ve en el documento y no solo en
un diff.

## Compuertas previas (no son módulos)

`MODULOS` es un dominio cerrado de seis nombres. La verificación de la **agregación de ítem
a constructo** no es ninguno de ellos: es una **compuerta previa**, sin fila en
`docs/validacion/replicaciones.csv`. Se registra en `docs/validacion/compuertas.csv` con
encabezado `id_estudio,compuerta,fuente,estado,detalle`.

**La compuerta era un absorbedor por estudio, y encima automatizado.** Bastaba dejarla en
`no_pasa` para que **todas** las filas de ese estudio pasaran a `D-AMB`, sin contradicción
que ningún guardián pudiera detectar, porque el guardián recalculaba lo mismo. Y era peor de
lo que parecía: **quien construye los constructos que la compuerta contrasta contra la tabla
publicada es `calibraqca::promediar_constructos()`, código de la propia aplicación**. Si esa
función tiene un defecto, la compuerta cae y al caer absuelve las comparaciones de necesidad
de E009 y E025 —las que sí muerden— con el CI en verde. La premisa que este plan escribía,
«el estudio queda como no reproducible por información insuficiente, no como fallo de la
aplicación», era **falsa**: nada distinguía «la regla de agregación que hipotetiza el plan es
la equivocada» de «nuestra media está rota».

**La compuerta pierde todo poder sobre los códigos.** No es un argumento de
`codigo_de_la_fila()` —cuya firma es exactamente `fila, obtenido, estudios`, afirmado en la
prueba de contratos—, no absuelve a ningún estudio y no existe `COMPUERTA_ABSUELVE`. Es un
**dato que el informe publica** junto al veredicto. Queda:

- Existe **exactamente** para los tres estudios cuyo constructo hay que armar desde los
  ítems: `COMPUERTAS_AGREGACION = c("E009", "E025", "E027")`. Una fila de compuerta para
  cualquier otro estudio aborta el guardián.
- **`no_pasa` es AMBIGUO, y el plan lo dice en vez de prometer lo contrario.**
  `ESTADOS_COMPUERTA = c("pasa", "no_pasa", "no_aplica")`. La revisión anterior prometía
  distinguir «la regla de agregación que propone el plan es la equivocada» de
  «`promediar_constructos()` está roto» calculando la media dos veces, con esa función y con
  `rowMeans()` de base R. **Esa promesa era falsa y se retira.** Medido el motor real
  —`pkg/calibraqca/R/agregacion.R:14-27`—, `promediar_constructos()` **es**
  `rowMeans(x, na.rm = TRUE)` más la regla `PROPORCION_MINIMA_ITEMS <- 0.5`: sobre datos
  completos las dos son idénticas bit a bit, y la única divergencia posible es una fila con
  menos de la mitad de sus ítems. El discriminador estaba muerto, y dejarlo escrito habría
  publicado como culpa del plan lo que fuera culpa del motor. Una promesa en prosa con el
  discriminador muerto es peor que no tener discriminador.
- Una compuerta caída **no cambia ningún código**. Las comparaciones de ese estudio se
  ejecutan y se registran como salgan; el informe publica el estado junto al veredicto y
  **declara la ambigüedad con todas las letras**: una compuerta en `no_pasa` significa que la
  media de ítems no reproduce la tabla publicada, y que el plan **no puede decir** si eso
  viene de su hipótesis de agregación o de `promediar_constructos()`.

## Estructura de archivos

- `validation/R/comun-replicacion.R`: descarga verificada, tolerancias, comparador y códigos `D-*`.
- `docs/validacion/compuertas.csv`: estado de las compuertas previas de agregación.
- `validation/manifiestos/<ID>.json`: procedencia (archivo servido, bytes, SHA-256, licencia y fecha), **censo de comparaciones por módulo**, **`fuentes` por módulo** —el dominio cerrado de la columna `fuente` de las expectativas— y, si el depósito no se pudo abrir, el bloque `no_ejecutable` con su evidencia.
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
- Consumes: las tolerancias congeladas y los códigos `D-*` de la especificación §6 y §8, y la selección congelada de `docs/validacion/estudios.csv`.
- Produces: `leer_csv()`, `decimales_de()`, `tolerancia_de()`, `comparar()`, `codigo_de_la_fila()`, `veredicto()`, `exigir_declarado()`, `obtener_artefacto()` y los esquemas de manifiesto, expectativas, resultados y compuertas.

**Esta tarea ya no crea ningún registro auxiliar.** Los tres CSV de la revisión anterior
—`validation/ausencias.csv`, `validation/discrepancias-prerregistradas.csv` y
`docs/validacion/no-ejecutables.csv`— desaparecen. Los tres eran lo mismo con distinto
nombre: un texto libre con poder sobre un código, sobre una fila o sobre un estudio entero.
Lo que documentaban vive ahora donde no decide nada o donde se puede comprobar: las
ausencias, con su localizador, en `validation/prerregistros/<ID>.md`; el censo y la no
ejecutabilidad, en el manifiesto del estudio.

- [ ] **Step 1: Escribir la prueba de los contratos antes que el código**

Crear `validation/tests/test-contratos-replicacion.R`. Contenido exacto, ejecutado y
sometido a mutación antes de escribirlo aquí:

```r
source("validation/R/comun-replicacion.R")

stopifnot(identical(CODIGOS_DISCREPANCIA,
                    c("D-OK", "D-EST", "D-AMB", "D-APP")))
stopifnot(identical(MODULOS, c("calibracion", "necesidad", "tabla_verdad",
                               "minimizacion", "ajuste", "robustez")))
stopifnot(!"agregacion" %in% MODULOS)
stopifnot(identical(COLUMNAS_EXPECTATIVAS, c(
  "id_estudio", "modulo", "comparacion", "esperado", "precision",
  "decidible", "fuente")))
stopifnot(!"decimales" %in% COLUMNAS_EXPECTATIVAS)
stopifnot(identical(COLUMNAS_RESULTADOS, c(
  "id_estudio", "nivel", "modulo", "comparacion", "esperado", "obtenido",
  "tolerancia", "codigo", "fuente", "fecha")))
stopifnot(identical(COLUMNAS_COMPUERTAS, c("id_estudio", "compuerta", "fuente",
                                           "estado", "detalle")))

# Las listas cerradas tienen tamano fijo: crecer una es un cambio de dos
# lineas en dos archivos, no una celda mas en un CSV. Tras la auditoria de
# celdas del 2026-08-13 la primera queda VACIA: sus dos entradas eran
# `E025:tabla_verdad` y `E008:robustez`, y esos dos modulos ya no estan
# declarados —la seleccion los congelo en `no_evaluable`—, asi que una entrada
# suya seria una excepcion que nadie consulta.
stopifnot(length(SIN_EXPECTATIVA_PUBLICADA) == 0L)
stopifnot(length(ESTUDIOS_NO_EJECUTABLES) == 1L)
stopifnot(length(COMPUERTAS_AGREGACION) == 3L)
stopifnot(identical(ESTADOS_COMPUERTA, c("pasa", "no_pasa", "no_aplica")))
# La compuerta no puede absolver porque no entra en la derivacion del codigo.
stopifnot(identical(names(formals(codigo_de_la_fila)),
                    c("fila", "obtenido", "estudios")))

# 1. La tolerancia sale de la CADENA publicada: "0.860" y "0.86" no son el
#    mismo dato, y no hay columna `decimales` que declarar.
stopifnot(decimales_de("0.860") == 3L)
stopifnot(decimales_de("0.86") == 2L)
stopifnot(decimales_de("92") == 0L)
stopifnot(inherits(try(decimales_de("no calculado"), silent = TRUE), "try-error"))
stopifnot(inherits(try(decimales_de(NA), silent = TRUE), "try-error"))
stopifnot(inherits(try(decimales_de(character(0)), silent = TRUE), "try-error"))

stopifnot(tolerancia_de("completa", NA) == 1e-9)
stopifnot(tolerancia_de("exacta", NA) == 0)
stopifnot(tolerancia_de("decimales", "0.860") == 0.0005)
stopifnot(tolerancia_de("decimales", "0.86") == 0.005)
stopifnot(tolerancia_de("decimales", "92") == 0.5)
stopifnot(inherits(try(tolerancia_de("holgada", "0.86"), silent = TRUE),
                   "try-error"))

# Pareja de casos opuestos sobre la MISMA diferencia (0,0045). Leer el CSV
# como numerico convierte "0.860" en "0.86" y la pareja se vuelve una sola.
stopifnot(comparar(0.8555, "0.860", tolerancia_de("decimales", "0.860"))$codigo
          == "D-APP")
stopifnot(comparar(0.8555, "0.86", tolerancia_de("decimales", "0.86"))$codigo
          == "D-OK")
stopifnot(identical(as.character(as.numeric("0.860")), "0.86"))

# El umbral se prueba moviendo el PARAMETRO, nunca llevando el dato al limite.
stopifnot(comparar(0.9157, "0.916", tolerancia_de("decimales", "0.916"))$codigo
          == "D-OK")
stopifnot(comparar(0.9152, "0.916", tolerancia_de("decimales", "0.916"))$codigo
          == "D-APP")
stopifnot(comparar(0.9152, "0.92", tolerancia_de("decimales", "0.92"))$codigo
          == "D-OK")

# Un valor no numerico es un error, no un D-AMB.
stopifnot(inherits(try(comparar("no calculado", "0.916", 5e-4), silent = TRUE),
                   "try-error"))
stopifnot(inherits(try(comparar(0.9, "", 5e-4), silent = TRUE), "try-error"))

est <- leer_csv("docs/validacion/estudios.csv")
inc <- est[est$decision == "incluir", , drop = FALSE]
stopifnot(nrow(inc) == 9L, all(inc$nivel == "B"))

fila <- function(id, modulo, esperado, decidible, fuente = "Tabla X",
                 comparacion = "c", precision = "decimales") {
  data.frame(id_estudio = id, modulo = modulo, comparacion = comparacion,
             esperado = esperado, precision = precision, decidible = decidible,
             fuente = fuente, stringsAsFactors = FALSE)
}
codigo <- function(f, obtenido) codigo_de_la_fila(f, obtenido, inc)

# 2. El ajuste de un estudio cuya minimizacion la seleccion congelo como
#    no_evaluable no culpa al motor; su calibracion y su necesidad si muerden.
amb <- fila("E025", "ajuste", "0.915", "no_tipo_solucion")
stopifnot(codigo(amb, 0.915) == "D-AMB", codigo(amb, 0.100) == "D-AMB")

cal <- fila("E026", "calibracion", "0.79", "si",
            fuente = "columna fhuman de dataset.csv")
stopifnot(codigo(cal, 0.79) == "D-OK", codigo(cal, 0.11) == "D-APP")

siempre <- setdiff(MODULOS, MODULOS_DEPENDIENTES_DE_SOLUCION)
stopifnot(length(siempre) == 3L,
          identical(siempre, c("calibracion", "necesidad", "tabla_verdad")))
for (m in siempre) {
  f <- fila("E026", m, "5", "no_tipo_solucion",
            comparacion = "filas_sobre_incl_cut", precision = "exacta")
  stopifnot(inherits(try(codigo(f, 19), silent = TRUE), "try-error"))
}

# 3. La seleccion congelada se congela AQUI: apagar una celda `si` a
#    `no_evaluable` borraba el modulo del censo, del manifiesto y del informe
#    —indistinguible de una limitacion genuina— y 35 de 44 pasaban en verde.
#    Auditada celda a celda contra los articulos el 2026-08-13, la matriz baja
#    de 44 `si` a 34: `tabla_verdad` estaba en `si` en los NUEVE —el unico
#    modulo con pleno— y en siete de ellos ninguna tabla publicada lo sostenia.
CONGELADO <- c(
  "E001 si no_evaluable no_evaluable si si si",
  "E008 si si no_evaluable si si no_evaluable",
  "E009 no_evaluable si no_evaluable no_evaluable si no_evaluable",
  "E012 si si si si si si",
  "E014 si si no_evaluable no_evaluable si no_evaluable",
  "E015 si si si si si no_evaluable",
  "E025 si si no_evaluable no_evaluable si no_evaluable",
  "E026 si si no_evaluable no_evaluable si si",
  "E027 si si no_evaluable no_evaluable si no_evaluable")
o <- inc[order(inc$id), , drop = FALSE]
stopifnot(identical(
  paste(o$id, apply(o[, paste0("mod_", MODULOS)], 1L, paste, collapse = " ")),
  CONGELADO))
for (id in c("E008", "E012", "E015")) {
  f <- fila(id, "ajuste", "0.808", "no_tipo_solucion")
  stopifnot(inherits(try(codigo(f, 0.1), silent = TRUE), "try-error"))
  g <- fila(id, "minimizacion", "3", "si", precision = "exacta")
  stopifnot(codigo(g, 3) == "D-OK", codigo(g, 2) == "D-APP")
}

# 4. `no_ejercitado` exige que la seleccion congelada declare que el estudio
#    publica conjuntos YA calibrados, y solo cabe en calibracion.
stopifnot(identical(inc$id[inc$tipo_datos == "conjuntos_calibrados"], "E014"))
ej <- fila("E014", "calibracion", "100", "no_ejercitado",
           comparacion = "celdas_coincidentes_Tabla2", precision = "exacta")
stopifnot(codigo(ej, 89) == "D-EST", codigo(ej, 100) == "D-EST")
mal_modulo <- fila("E014", "necesidad", "0.90", "no_ejercitado")
stopifnot(inherits(try(codigo(mal_modulo, 0.1), silent = TRUE), "try-error"))
mal_estudio <- fila("E026", "calibracion", "0.79", "no_ejercitado")
stopifnot(inherits(try(codigo(mal_estudio, 0.11), silent = TRUE), "try-error"))

# 5. Una expectativa sin valor publicado aborta, no devuelve D-AMB: vaciar la
#    celda era la sexta mudanza del absorbedor. En los tres `decidible`.
for (d in DECIDIBLE) {
  m <- if (identical(d, "no_ejercitado")) "calibracion" else "ajuste"
  i <- if (identical(d, "no_ejercitado")) "E014" else "E025"
  for (v in c("", "   ")) {
    stopifnot(inherits(try(codigo(fila(i, m, v, d), 0.11), silent = TRUE),
                       "try-error"))
  }
}

# 6. La necesidad de un estudio con compuerta de agregacion muerde igual: la
#    compuerta no participa en la derivacion del codigo.
cal9 <- fila("E009", "necesidad", "0.902", "si")
stopifnot(codigo(cal9, 0.902) == "D-OK", codigo(cal9, 0.100) == "D-APP")

# 7. La trampa del vector vacio: `stopifnot(logical(0))` aprueba.
stopifnot(length(NULL == "si") == 0L)
stopifnot(inherits(try(exigir_declarado(NULL, "x"), silent = TRUE), "try-error"))
stopifnot(inherits(try(exigir_declarado(NA, "x"), silent = TRUE), "try-error"))
stopifnot(inherits(try(exigir_declarado(character(0), "x"), silent = TRUE),
                   "try-error"))
stopifnot(inherits(try(exigir_declarado("no_evaluable", "x"), silent = TRUE),
                   "try-error"))
exigir_declarado("si", "x")
sin_declarar <- fila("E009", "calibracion", "0.79", "si")   # no_evaluable
stopifnot(inherits(try(codigo(sin_declarar, 0.79), silent = TRUE), "try-error"))
cero_filas <- fila("E026", "calibracion", "0.79", "si")[0, , drop = FALSE]
stopifnot(inherits(try(codigo(cero_filas, 0.79), silent = TRUE), "try-error"))

# 8. Veredicto por estudio: pareja de casos opuestos sobre datos sinteticos.
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

# Los otros tres son `setdiff(MODULOS, MODULOS_DEPENDIENTES_DE_SOLUCION)`: se
# calculan antes de minimizar. No hay segunda constante que vaciar.
MODULOS_DEPENDIENTES_DE_SOLUCION <- c("minimizacion", "ajuste", "robustez")

# Cuatro codigos, y los cuatro se DERIVAN. No hay via para escribir uno a mano.
CODIGOS_DISCREPANCIA <- c("D-OK", "D-EST", "D-AMB", "D-APP")

VEREDICTOS <- c("reproducido", "reproduccion parcial", "no reproducido",
                "no ejecutable")

COLUMNAS_EXPECTATIVAS <- c("id_estudio", "modulo", "comparacion", "esperado",
                           "precision", "decidible", "fuente")
COLUMNAS_RESULTADOS <- c("id_estudio", "nivel", "modulo", "comparacion",
                         "esperado", "obtenido", "tolerancia", "codigo",
                         "fuente", "fecha")
COLUMNAS_COMPUERTAS <- c("id_estudio", "compuerta", "fuente", "estado",
                         "detalle")

# Los dos motivos que NO comparan, con precondicion en la seleccion congelada:
#   no_tipo_solucion  modulo dependiente de la solucion Y mod_minimizacion ==
#                     "no_evaluable"; no_ejercitado: modulo `calibracion` Y
#                     tipo_datos == "conjuntos_calibrados".
DECIDIBLE <- c("si", "no_tipo_solucion", "no_ejercitado")

# Excepciones cerradas a «todo modulo declarado tiene al menos una
# comparacion»: aqui cero filas, y al menos una en todo lo demas. Vacia desde
# la auditoria de celdas del 2026-08-13: sus dos entradas —`E025:tabla_verdad`
# y `E008:robustez`— dejaron de ser modulos declarados, porque justamente lo
# que la auditoria comprobo es que el estudio no publica nada comparable ahi, y
# eso se dice apagando la celda, no listando una excepcion. La constante se
# queda: es el sitio donde iria `E012:necesidad` si su texto resultara no fijar
# el umbral con el que declara la necesidad (Task 7).
SIN_EXPECTATIVA_PUBLICADA <- character(0)

# Unicos estudios que pueden declararse `no_ejecutable` en su manifiesto, en
# las dos direcciones. Sin esto seria un boton para absolver un estudio entero.
ESTUDIOS_NO_EJECUTABLES <- "E001"

# Los tres estudios Likert cuyo constructo hay que armar desde los items...
COMPUERTAS_AGREGACION <- c("E009", "E025", "E027")

# La compuerta NO absuelve a nadie: es un dato que el informe publica, no un
# codigo. Y `no_pasa` es AMBIGUO por construccion: no distingue «la regla de
# agregacion que propone el plan es la equivocada» de «promediar_constructos()
# esta roto». La ronda anterior prometia distinguirlo calculando la media dos
# veces, con esa funcion y con rowMeans(); medido el motor real
# (pkg/calibraqca/R/agregacion.R:14-27), promediar_constructos() ES
# rowMeans(x, na.rm = TRUE) mas la regla de PROPORCION_MINIMA_ITEMS, asi que
# sobre datos completos las dos son identicas y el discriminador esta muerto.
# Prometerlo era peor que no tenerlo: publicaria como culpa del plan lo que
# fuera culpa del motor. El informe declara la ambiguedad.
ESTADOS_COMPUERTA <- c("pasa", "no_pasa", "no_aplica")

# Todo CSV se lee como TEXTO: de la cadena `esperado` sale la tolerancia, y
# leerla como numero convierte "0.860" en 0.86 y la multiplica por diez.
leer_csv <- function(ruta) {
  utils::read.csv(ruta, stringsAsFactors = FALSE, colClasses = "character",
                  check.names = FALSE)
}

# Decimales de la CADENA publicada: "0.860" tres, "0.86" dos, "92" cero.
decimales_de <- function(esperado) {
  if (length(esperado) != 1L || is.na(esperado)) {
    stop("Valor esperado ausente.", call. = FALSE)
  }
  txt <- trimws(as.character(esperado))
  if (!grepl("^-?[0-9]+([.][0-9]+)?$", txt)) {
    stop("El valor esperado no es un numero publicado: '", txt, "'.",
         call. = FALSE)
  }
  if (!grepl("[.]", txt)) return(0L)
  nchar(sub("^.*[.]", "", txt))
}

tolerancia_de <- function(precision, esperado) {
  switch(precision,
    completa  = 1e-9,
    decimales = 0.5 * 10^(-decimales_de(esperado)),
    exacta    = 0,
    stop("Precision no admitida: ", precision,
         ". Se admite completa, decimales o exacta.", call. = FALSE))
}

# Sin rama NA: un valor no numerico es un error del circuito, no una
# ambiguedad del estudio. La rama NA => D-AMB absolvia vaciando una celda.
comparar <- function(obtenido, esperado, tolerancia) {
  o <- suppressWarnings(as.numeric(obtenido))
  e <- suppressWarnings(as.numeric(esperado))
  if (!is.finite(o) || !is.finite(e)) {
    stop("Comparacion con un valor no numerico: esperado = '", esperado,
         "', obtenido = '", obtenido, "'.", call. = FALSE)
  }
  d <- abs(o - e)
  list(codigo = if (d <= tolerancia) "D-OK" else "D-APP", diferencia = d)
}

# `stopifnot(logical(0))` aprueba: NULL == "si" es un vector vacio, no FALSE.
exigir_declarado <- function(x, contexto) {
  if (length(x) != 1L || is.na(x) || !identical(as.character(x), "si")) {
    stop("Modulo no declarado por la seleccion congelada: ", contexto,
         call. = FALSE)
  }
  invisible(TRUE)
}

# Funcion TOTAL de la fila, el obtenido, la seleccion congelada y la compuerta.
codigo_de_la_fila <- function(fila, obtenido, estudios) {
  if (nrow(fila) != 1L) {
    stop("codigo_de_la_fila() exige exactamente una fila, recibio ",
         nrow(fila), ".", call. = FALSE)
  }
  if (!fila$modulo %in% MODULOS) {
    stop("Modulo fuera del dominio cerrado: ", fila$modulo, call. = FALSE)
  }
  if (!fila$decidible %in% DECIDIBLE) {
    stop("Valor de `decidible` no admitido: ", fila$decidible, call. = FALSE)
  }
  e <- estudios[estudios$id == fila$id_estudio, , drop = FALSE]
  if (nrow(e) != 1L) {
    stop("Estudio fuera de la seleccion congelada: ", fila$id_estudio,
         call. = FALSE)
  }
  exigir_declarado(e[[paste0("mod_", fila$modulo)]],
                   paste(fila$id_estudio, fila$modulo))
  # Vaciar la celda era la sexta mudanza: `is.na(esperado)` daba D-AMB.
  if (!nzchar(trimws(fila$esperado))) {
    stop("Expectativa sin valor publicado: ", fila$id_estudio, "/",
         fila$comparacion, ". Si el estudio no publica nada que comparar, la ",
         "fila no existe y su modulo va en SIN_EXPECTATIVA_PUBLICADA.",
         call. = FALSE)
  }
  if (identical(fila$decidible, "no_tipo_solucion")) {
    if (!fila$modulo %in% MODULOS_DEPENDIENTES_DE_SOLUCION) {
      stop("`no_tipo_solucion` en un modulo que no depende de la solucion: ",
           fila$id_estudio, "/", fila$modulo, ".", call. = FALSE)
    }
    if (!identical(e$mod_minimizacion, "no_evaluable")) {
      stop("`no_tipo_solucion` en ", fila$id_estudio, " (", fila$comparacion,
           "): la seleccion congelada declara su minimizacion comparable, ",
           "asi que su solucion SI es reproducible.", call. = FALSE)
    }
    return("D-AMB")
  }
  if (identical(fila$decidible, "no_ejercitado")) {
    if (!identical(fila$modulo, "calibracion")) {
      stop("`no_ejercitado` solo cabe en calibracion: ", fila$id_estudio, "/",
           fila$modulo, ".", call. = FALSE)
    }
    if (!identical(e$tipo_datos, "conjuntos_calibrados")) {
      stop("`no_ejercitado` en ", fila$id_estudio,
           ", que no publica conjuntos ya calibrados.", call. = FALSE)
    }
    return("D-EST")
  }
  comparar(obtenido, fila$esperado,
           tolerancia_de(fila$precision, fila$esperado))$codigo
}

# Funcion pura: se prueba con la pareja de casos sinteticos opuestos.
veredicto <- function(res, id) {
  r <- res[res$id_estudio == id, , drop = FALSE]
  if (nrow(r) == 0L) return("no ejecutable")
  if (any(r$codigo == "D-APP")) return("no reproducido")
  if (any(r$codigo %in% c("D-AMB", "D-EST"))) return("reproduccion parcial")
  "reproducido"
}

# Descarga fuera del repositorio y verifica el hash: sin el, error.
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

En `docs/validacion/diccionario-replicaciones.md`, definir el manifiesto —`artefactos`,
`comparaciones` (censo por módulo) y **`fuentes` (dominio cerrado de `fuente`, indexado por
módulo, con las mismas claves que `comparaciones`)**—, cada columna de
`validation/expectativas/<ID>.csv`, de `docs/validacion/replicaciones.csv` y de
`docs/validacion/compuertas.csv`; el bloque `comparaciones` del manifiesto; el dominio
cerrado de `modulo` (los seis nombres canónicos), el de `precision`
(`completa`, `decimales`, `exacta`), el de `decidible` (`si`, `no_tipo_solucion`,
`no_ejercitado`, los dos con precondición comprobable contra `estudios.csv`) y el de
`codigo`:

- `D-OK`: equivalencia dentro de la tolerancia prerregistrada.
- `D-EST`: la comparación no ejercita la aplicación —el estudio publica conjuntos ya
  calibrados— y por tanto no puede aprobar ni acusar al motor.
- `D-AMB`: el estudio no publica lo necesario para decidir. **No cuenta como aprobación.**
- `D-APP`: defecto o decisión no documentada de `fsqca-calibrador`.

`D-FMT` y `D-DEP` **salen del dominio**: no había forma de derivarlos, así que solo podían
asignarse escribiéndolos a mano en un registro de excepciones, que es exactamente el
mecanismo que este plan retira. Una diferencia que se sospeche de formato o de versión de
dependencia se registra `D-APP` y se narra en el informe con los dos valores y la evidencia;
reclasificarla exige cambiar este plan en un commit propio, no una celda en un CSV.

El diccionario documenta también, con su justificación y su localizador, las tres listas
cerradas del común: `SIN_EXPECTATIVA_PUBLICADA`, `ESTUDIOS_NO_EJECUTABLES` y
`COMPUERTAS_AGREGACION`. Las tres se comprueban en **las dos direcciones** y tienen su tamaño
afirmado en la prueba de contratos: crecer una es un cambio visible de dos líneas en dos
archivos, no una celda más en un CSV.

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
- Consumes: `journal.pone.0291870.s001.csv` y las Tablas 8, 9 y 10 de la publicación.
- Produces: la compuerta de agregación y comparaciones de `calibracion`, `necesidad` y `ajuste`. `minimizacion`, `tabla_verdad` y `robustez` son `no_evaluable`.

- [ ] **Step 1: Escribir el manifiesto, con el censo contado sobre las tablas**

El bloque `comparaciones` se escribe **antes** que las expectativas y contando las celdas de
la tabla publicada, no las filas escritas. Para E025: la Tabla 8 publica media, desviación
típica, mínimo y máximo de las siete variables (`4 × 7 = 28`) más el `n` de casos ⇒ **29**;
la Tabla 9 publica consistencia y cobertura de necesidad para las seis condiciones en
presencia y en ausencia (`2 × 2 × 6`) ⇒ **24**; la Tabla 10 publica consistencia y cobertura
de la solución ⇒ **2**. Si al transcribir la tabla el conteo no cuadra, sobra o falta
una fila: el conteo no se ajusta al resultado.

**No hay bloque de `tabla_verdad` ni de `robustez`**, y no porque tengan censo `0`: desde la
auditoría de celdas del 2026-08-13 no están declarados. El artículo no publica tabla de
verdad —la Tabla 10 son configuraciones ya minimizadas, con núcleo y periferia y sin conteo
de casos— y lo que se leía como robustez es la **validez predictiva** de la Tabla 11, que
parte la muestra usando «identical cutoff points for both sets of samples»: no varía ningún
parámetro, que es justo lo contrario de un análisis de sensibilidad. Las claves de
`comparaciones` son exactamente los `mod_* == "si"`, así que declarar cualquiera de los dos
aborta el guardián.

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
  ],
  "comparaciones": {
    "calibracion": 29,
    "necesidad": 24,
    "ajuste": 2
  },
  "fuentes": {
    "calibracion": ["Tabla 8"], "necesidad": ["Tabla 9"],
    "ajuste": ["Tabla 10"]
  }
}
```

`fuentes` es el dominio cerrado de la columna `fuente`, **indexado por módulo**: cada
expectativa solo puede citar una tabla declarada **para su módulo**. Sus claves son las mismas
que las de `comparaciones`. Una lista puede tener más de una tabla —E015 saca su
`tabla_verdad` de las Tablas 3 y 4, E012 su `robustez` de las Tablas 6 y 7 y su `calibracion`
del texto y de la S2— y puede estar vacía donde el censo es `0`.

Las claves de `comparaciones` son exactamente los módulos que `estudios.csv` declara `si` para
E025;
`minimizacion`, `tabla_verdad` y `robustez` no aparecen porque son `no_evaluable`.
El manifiesto de cada estudio se escribe
en su propia tarea y no se vuelve a tocar: cualquier cambio posterior a `comparaciones` va
en un commit propio, con la tabla recontada.

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
  en `no_pasa`, que es **ambiguo por construcción**: no distingue si falla la hipótesis de
  agregación del plan o `promediar_constructos()`. **No cambia el código de ninguna fila**:
  las comparaciones de E025 se ejecutan y se registran como salgan, y el informe publica el
  estado junto al veredicto, con la ambigüedad declarada. Esta compuerta **no** promueve
  E025 a Nivel A: la regla la pone este plan, no los autores.
- **Anclas** (Tabla 8, idénticas para las siete variables): plena `5.00`, cruce `3.50`,
  nula `1.00`; fuente de ancla `teoria` («Based on the suggestions made by Fiss»,
  sección «Calibration»). `idm = 0.95`: la Tabla 8 publica mín. `0.05` y máx. `0.95` para
  las siete variables, que es la convención de fs/QCA 3.0, el programa que el artículo
  declara haber usado.
- **Corrección del 0,50**: no declarada por el estudio. Se ejecuta la del motor (`+0.001`) y
  se registra en el informe. Si alguna comparación cambia al desactivarla, **el código no
  cambia**: el informe publica los dos valores junto a esa comparación. Una sensibilidad es
  una descripción, no un código; convertirla en código exigiría una vía para escribirlo a
  mano, que es el mecanismo que este plan retiró.
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
- **Robustez**: `mod_robustez = no_evaluable` desde la auditoría de celdas del 2026-08-13.
  **El estudio no publica ningún análisis de sensibilidad.** Lo que este plan tomaba por
  robustez es la **validez predictiva** (Tabla 11 y sección «Predictive validity»): partición
  aleatoria en submuestra y muestra de reserva y dos modelos de la submuestra
  —`M1: FUN*PU*PEOU*ATTs` con cobertura bruta `0.8035`, única `0.4796` y consistencia
  `0.9306`; `M2: ~FUN*AES*~EXP*~PU*PEOU*ATTs` con `0.3435`, `0.0195` y `0.9817`; solución
  `0.8230 / 0.9305`—, y el artículo declara literalmente que se usaron «**identical cutoff
  points** for both sets of samples». Eso es la **negación** del criterio: no hay parámetro
  variado que comparar. A la partición le faltaba además todo —semilla, tamaño y lista de
  casos de cada mitad; se buscó en «Predictive validity» el 2026-08-11 y solo consta
  «randomly divided into holdout samples and subsamples»—, así que la fila `D-AMB` que este
  plan prerregistraba estaba de más: sin módulo declarado **no hay fila**. Los ocho valores
  de la Tabla 11 y los de la Fig 3 (consistencia `0.937`, cobertura `0.784`, que además son
  de figura) se transcriben en el prerregistro para exhibirlos, no para compararlos. El
  barrido de anclas y umbrales del paso 7 del motor se ejecuta y se informa como descripción.

- [ ] **Step 3: Escribir las expectativas**

`validation/expectativas/E025.csv` (extracto exacto del encabezado y de las primeras filas;
se completa con las 7 medias y 7 desviaciones de la Tabla 8, las 12 consistencias y 12
coberturas de la Tabla 9 y las dos cifras de la Tabla 10). **No hay ninguna fila
`modulo = minimizacion`, `modulo = tabla_verdad` ni `modulo = robustez`**: la selección
congeló los tres como `no_evaluable`.

**Aviso para quien monte el corpus**: este bloque y el `comparaciones` del manifiesto **no
casan entre sí y no deben casar**. El manifiesto declara `calibracion: 29` y `necesidad: 24`
—contados sobre las tablas publicadas— y aquí se muestran 5 y 2 filas, porque esto es un
extracto. El censo se **deriva de la tabla publicada**, nunca se copia del extracto:
copiarlo lo bajaría de 29 a 5 en silencio.

```csv
id_estudio,modulo,comparacion,esperado,precision,decidible,fuente
E025,calibracion,media_fs_FUN,0.69,decimales,si,Tabla 8
E025,calibracion,de_fs_FUN,0.20,decimales,si,Tabla 8
E025,calibracion,min_fs_PIs,0.05,decimales,si,Tabla 8
E025,calibracion,max_fs_PIs,0.95,decimales,si,Tabla 8
E025,calibracion,n_casos,225,exacta,si,Tabla 8
E025,necesidad,consistencia_fs_ATTs,0.952,decimales,si,Tabla 9
E025,necesidad,cobertura_fs_ATTs,0.860,decimales,si,Tabla 9
E025,ajuste,consistencia_solucion,0.915,decimales,no_tipo_solucion,Tabla 10
E025,ajuste,cobertura_solucion,0.881,decimales,no_tipo_solucion,Tabla 10
```

No hay columna `decimales`: `cobertura_fs_ATTs` vale `0.860` y no `0.86` porque así lo
publica la Tabla 9, y de esa cadena salen los tres decimales de su tolerancia. El CSV se lee
con `colClasses = "character"` —`leer_csv()` en el común— y el guardián lo comprueba: si
alguien lo leyera como numérico, el cero final desaparecería y la tolerancia se
multiplicaría por diez.

Las de calibración y necesidad llevan `decidible = si`: **pueden dar `D-APP`** y son las que
ejercitan el motor. Las de ajuste llevan `no_tipo_solucion`, que solo pasa porque
`estudios.csv` declara `mod_minimizacion = no_evaluable` para E025.

**`tabla_verdad`**: `mod_tabla_verdad = no_evaluable`. La celda estuvo en `si` porque el
estudio declara los tres umbrales, no porque publique la tabla, y la auditoría del 2026-08-13
la apagó: no hay tabla de verdad impresa en el artículo ni en su suplemento —se buscó en las
Tablas 1–11 y en «Sufficient conditions analysis» el 2026-08-11, y el S1 File es un CSV de
225 respuestas de encuesta—. **Sin módulo declarado no hay ni fila ni entrada de censo**, y
declarar `tabla_verdad` en el manifiesto de E025 aborta el guardián. `minimizar()` y
`construir_tabla_verdad()` se ejecutan igual porque la cadena lo exige aguas abajo, y el
informe publica el número de filas, sus frecuencias y sus consistencias como **descripción**,
sin fingir una comparación. No se inventa una cuenta de filas a partir de las seis
configuraciones de la Tabla 10: ese número no es el mismo objeto — precisamente confundir los
dos objetos es lo que mantuvo la celda en `si` en siete de los nueve incluidos.

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
source("validation/R/comun-replicacion.R")

esperado <- function(comparacion) {
  e <- leer_csv("validation/expectativas/E025.csv")
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
  # La prueba NO afirma que salga D-OK: comprueba que la cadena PRODUCE un
  # numero. Quien escribe `obtenido` en replicaciones.csv es el corredor, y
  # quien deriva el codigo es codigo_de_la_fila(). Una prueba que exigiera
  # D-OK convertiria un defecto real de la aplicacion en CI rojo, y esa es
  # exactamente la presion que fabrico seis absorbedores en cuatro rondas.
  expect_true(is.finite(mean(fs)))
})
```

`calibrar()` se llama **aquí**, en la prueba, no en el adaptador: el adaptador solo lee y
mapea, y `test-sin-omisiones.R` lo exige con una lista blanca —`leer_datos`,
`definir_mapeo`, `definir_anclas`, `promediar_constructos`— sobre los archivos
`validation/R/adaptador-*.R`. Un adaptador que produjera el número comparado sería el sitio
perfecto para fabricarlo, y nadie lo estaba mirando.

Las demás pruebas del archivo, con la misma forma: `de_fs_*`, `min/max`, `n_casos` y las
doce consistencias y coberturas de necesidad con `analizar_necesidad()`, que son las
comparaciones que sí pueden dar `D-OK`; y el ajuste con `diagnosticar_suficiencia()`, que se
ejecuta y **se afirma como `D-AMB`**, no como `D-OK`. `construir_tabla_verdad(...,
consistencia = 0.80, pri = 0.75, frecuencia = 3)` se llama para poder seguir la cadena, pero
**no tiene ninguna fila de comparación**: su módulo es `no_evaluable`.

```r
est <- leer_csv("docs/validacion/estudios.csv")
inc <- est[est$decision == "incluir", , drop = FALSE]

test_that("el ajuste de E025 no es decidible y se registra asi", {
  fila <- esperado("consistencia_solucion")         # decidible = no_tipo_solucion
  obtenido <- ajuste_de_la_app                      # solucion que la app si produce
  expect_equal(codigo_de_la_fila(fila, obtenido, inc), "D-AMB")
})

test_that("la calibracion y la necesidad de E025 si muerden", {
  expect_equal(codigo_de_la_fila(esperado("media_fs_FUN"), 0.6903, inc), "D-OK")
  expect_equal(codigo_de_la_fila(esperado("media_fs_FUN"), 0.1000, inc), "D-APP")
})
```

`codigo_de_la_fila()` vive en `comun-replicacion.R` y devuelve `D-AMB` **solo** cuando la
fila lo declara y el módulo es uno de los tres que dependen de la solución; con
`calibracion` o `necesidad` compara de verdad, y si alguien intentara marcarlas
`no_tipo_solucion` la función aborta.

**Qué afirma una prueba de replicación y qué no.** Afirma **propiedades del proceso**: que el
artefacto resuelve su hash, que el adaptador devuelve la forma declarada, que cada
comparación prerregistrada produjo un número finito, y —con valores sintéticos— que
`codigo_de_la_fila()` da `D-OK` y `D-APP` en la pareja de casos opuestos. **No afirma que la
aplicación reproduzca el estudio.** Ese es el resultado del experimento, no una condición de
la prueba: se registra en `replicaciones.csv`, baja el veredicto de ese estudio y se publica
en `docs/validacion-integral.md`.

- [ ] **Step 6: Ejecutar y registrar**

Run: `Rscript --vanilla -e 'testthat::test_file("validation/tests/testthat/test-replicacion-E025.R")'`
Expected: estado 0 **haya o no discrepancias**. Un `D-APP` no pone la prueba en rojo: se
registra en `docs/validacion/replicaciones.csv`, baja el veredicto de E025 a «no reproducido»
y se publica. Y **no** se corrige tocando la tolerancia ni el prerregistro.

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
- Produces: la compuerta de agregación y comparaciones de `calibracion`, `necesidad` y `ajuste`. `minimizacion`, `tabla_verdad` y `robustez` son `no_evaluable`.

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
  y ninguna en `replicaciones.csv`: `agregacion` no es un módulo canónico. La compuerta no
  absuelve nada —ninguna lo hace ya—, pero aquí además **la regla la declaran los autores**,
  así que si la media de los ítems no reproduce la Tabla 8 la diferencia es un candidato a
  `D-APP` sin matices: aquí ni siquiera cabe la lectura «la hipótesis del plan era otra»,
  porque la hipótesis no es del plan. Es el único de los tres donde `no_pasa` no es ambiguo.
- **Anclas**: plena `4`, cruce `3`, nula `2` para las siete variables (Tabla 8), con
  membresías `0.95 / 0.5 / 0.05` declaradas en el texto ⇒ `idm = 0.95`. Fuente de ancla
  `teoria`. Corrección declarada por el estudio: `+0.001` a las membresías iguales a `0.50`.
- **Umbrales**: `incl.cut = 0.8`, `n.cut = 3` (sección de suficiencia). **PRI: ausente.**
  Se buscó «PRI» y «proportional reduction» en el texto completo el 2026-08-11: cero
  coincidencias. Se ejecuta con `pri = 0` y se hace la sensibilidad con `pri = 0.70`; si la
  tabla de verdad cambia entre ambas, el informe publica las dos y lo dice junto a la
  comparación. El código sigue siendo el que deriven `esperado` y `obtenido` de la corrida
  prerregistrada, la de `pri = 0`.
- **`include`**: ausente ⇒ `mod_minimizacion = no_evaluable`. **No se compara ninguna
  solución**: la Tabla 10 es la intermedia —«The complex solution lacked explanatory value,
  while the parsimonious and intermediate solutions successfully made a distinction between
  the core and peripheral conditions»— y no se sustituye por la parsimoniosa.
- **Tabla de verdad**: `mod_tabla_verdad = no_evaluable` desde la auditoría de celdas del
  2026-08-13. Lo único publicado es esa Tabla 10 de soluciones; se inventariaron las 13
  tablas del artículo y sus tres suplementos y ninguno contiene una tabla de verdad. Se
  construye igualmente para poder minimizar y se informa como descripción, **sin fila de
  comparación y sin clave en el censo**.
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
a lo que produzca la aplicación, sin compararlas. El censo de E027 queda, por tanto, en tres
claves: `calibracion`, `necesidad` y `ajuste`.

- [ ] **Step 4: Adaptador y prueba**

Igual forma que E025: `definir_mapeo()` con los siete constructos y sus ítems reales
(`VG` = `VG2, VG4, VG5, VG6, VG9, VG10`; `MU` = `MU3, MU4, MU5, MU6`;
`IR` = `IR2, IR3, IR6, IR7, IR8`; `CS`, `PE`, `QEU`, `LE` con sus cinco ítems),
`escala = c(1, 5)`, `LE` con rol `resultado`. La prueba resuelve primero la compuerta de
agregación (Tabla 8) y solo después la cadena calibración → necesidad → tabla de verdad →
ajuste, en la que la tabla de verdad se ejecuta sin comparar. El ajuste se afirma con
`codigo_de_la_fila()` sobre una fila con
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
- Produces: comparaciones de necesidad y ajuste, y nada más. `mod_calibracion`, `mod_minimizacion`, `mod_tabla_verdad` y `mod_robustez` son `no_evaluable`, así que el censo de E009 tiene exactamente dos claves.

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
  es un módulo canónico. **Si falla, no pasa nada con los códigos**: las comparaciones de
  E009 se ejecutan y se registran como salgan. La versión anterior de este plan decía que el
  estudio quedaba «no reproducible por información insuficiente, **no como fallo de la
  aplicación**», y eso era una premisa falsa: quien construye los constructos que la
  compuerta contrasta contra la Tabla 5 es `promediar_constructos()`, código de
  `fsqca-calibrador`. Y el plan **no puede** distinguir las dos causas: esa función es
  `rowMeans(x, na.rm = TRUE)` más la regla del 50 % de ítems, así que compararla con
  `rowMeans()` sobre datos completos da lo mismo por construcción. El estado es `no_pasa` a
  secas y el informe declara la ambigüedad, sin tocar ningún código.
- **Cuantiles**: `stats::quantile(..., type = 7)`, el de R. La elección se prerregistra
  porque fs/QCA puede usar otra definición. Si aparece una diferencia, se registra `D-APP` y
  el informe muestra el valor con los dos tipos y la conclusión; **no hay un código que la
  degrade en el CSV**, porque el único mecanismo posible para asignarlo era escribirlo a mano
  y ese mecanismo es el absorbedor. Reclasificarla exige cambiar este plan.
- **Calibración**: `mod_calibracion = no_evaluable`. La compuerta de anclas se ejecuta como
  verificación de la agregación, **no** se informa como módulo de calibración reproducido.
- **Umbrales**: `incl.cut = 0.8`, `pri.cut = 0.8`, `n.cut = 3`, `+0.001` al `0.50`
  (sección de suficiencia; fsQCA 4.0).
- **Expectativas**: Tabla 8 (necesidad, alto y bajo nivel de `EI`, 24 consistencias y 24
  coberturas, 3 decimales) para el módulo `necesidad`, que es el único de E009 que puede dar
  `D-OK` —y desde la auditoría de celdas, el único que ejercita el motor con veredicto—.
  Del módulo **ajuste**, `consistencia_solucion` `0.923` y `0.929` y
  `cobertura_solucion` `0.625` y `0.391` de la Tabla 9, **prerregistrados `D-AMB`**: el
  artículo declara que «This study primarily relies on the intermediate solution» y no
  publica su `include`. Las siete configuraciones de la Tabla 9 no entran como expectativas:
  `mod_minimizacion` es `no_evaluable`, y no se sustituye la intermedia por la parsimoniosa.
- **Tabla de verdad**: `mod_tabla_verdad = no_evaluable` desde la auditoría de celdas del
  2026-08-13. El artículo publica sólo la Tabla 9, que son soluciones; la única aparición de
  «truth table» está en la nota de calibración que suma `0.001` a los valores de `0.5`, y S1
  a S4 se revisaron sin encontrarla. Se construye para poder seguir la cadena y se informa
  como descripción, sin comparación.
- **Robustez**: `mod_robustez = no_evaluable` desde la misma auditoría. La sección
  «Robustness tests» varía dos parámetros —PRI `0.80`→`0.85` y frecuencia `3`→`4`— y **no
  publica una sola cifra alternativa**, así que no hay nada que comparar. El barrido de
  anclas del motor se ejecuta y se informa como **descripción**.

  **Lo que se pierde con ese apagado, dicho en voz alta.** Hasta esta revisión, la fila de
  robustez de E009 era la única del plan que medía el barrido del **motor** —la estabilidad
  de los veredictos de necesidad de la Tabla 8 ante el desplazamiento de anclas—, llevaba
  `decidible = si` y `test-consolidacion.R` lo exigía en una línea, precisamente porque
  `mod_minimizacion` de E009 es `no_evaluable` y sin esa aserción la excusa
  `no_tipo_solucion` habría absuelto un defecto real. **Esa aserción desaparece con el
  módulo**, y no se sustituye por otra: de los tres estudios que conservan `robustez`, en
  E001 y E012 la excusa es estructuralmente imposible —`mod_minimizacion` es `si`—, así que
  la propiedad se mantiene sola; en E026 los dos escenarios de la Tabla 6 son soluciones
  intermedias y forzarlos a `decidible = si` sería fabricar un `D-APP` por tipo de solución.
  Queda escrito aquí para que nadie lo lea como un descuido.

- [ ] **Step 3: Adaptador, expectativas y prueba**

Misma forma que E025: `definir_mapeo(columna_id = "No", encuestados_por_caso = "uno",
escala = c(1, 7), ...)` con los siete constructos y sus ítems reales —`MSC` = `MSC1–MSC10`,
`TC` = `TC1–TC5`, `SF` = `SF1–SF6`, `TT` = `TT1–TT4`, `IP` = `IP1–IP3`, `MG` = `MG1–MG3` y
`EI` = `EI1–EI6` con rol `resultado`—. El primer bloque de la prueba es la compuerta de
agregación contra la Tabla 5, con las dos medias; los bloques siguientes se evalúan pase o
no pase, y ninguno cambia de código por el estado de la compuerta.

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
- Produces: comparaciones de `calibracion`, `necesidad`, `minimizacion` y `ajuste`. `tabla_verdad` y `robustez` son `no_evaluable` desde la auditoría de celdas del 2026-08-13.

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
  compatibles con parsimoniosa ⊆ intermedia, eso **no** se resuelve escribiendo `D-AMB`: el
  `mod_minimizacion` de E008 es `si`, así que ninguna fila suya admite `no_tipo_solucion`. Se
  registra `D-APP`, el informe lo explica con los dos conjuntos de términos, y si la
  conclusión fuera que la selección congelada clasificó mal a E008, eso se arregla en la
  selección, no en un código.
- **Expectativas de ajuste y minimización** (Tabla 7): cinco configuraciones, `CPSM1–CPSM3`
  para alto `ICSM` y `CPSM4–CPSM5` para bajo; consistencias `0.832, 0.893, 0.831, 0.879,
  0.902`; coberturas brutas `0.394, 0.324, 0.419, 0.257, 0.334`; únicas `0.101, 0.031,
  0.126, 0.084, 0.161`; solución alta `0.808 / 0.551` y baja `0.870 / 0.418`; tres
  decimales. De la Tabla 4 se comparan además media, desviación, mínimo y máximo de los
  cinco conjuntos calibrados (2 decimales).
- **Tabla de verdad**: `mod_tabla_verdad = no_evaluable` desde la auditoría de celdas del
  2026-08-13. El artículo publica sólo la Table 7 «Configurations analysis» —soluciones ya
  minimizadas, con ● y ⊗ y filas de consistencia y coberturas—, ni siquiera usa la expresión
  «truth table», y S1 Appendix, S2 Code y S3 Data se revisaron sin encontrarla. Se construye
  con `consistencia = 0.8`, `pri = 0.6`, `frecuencia = 1` para `ICSM` y para `~ICSM` porque
  la minimización lo exige, y se informa como descripción: **sin fila y sin clave de censo**.
- **Robustez**: `mod_robustez = no_evaluable` desde la misma auditoría. La §4.4.4
  «Robustness analysis» son dos frases y **cero cifras alternativas**: varía la consistencia
  de `0.8` a `0.85` y afirma que «configurations… are identical to the subset of original
  results». Se buscaron además «robust» y «sensitivity» en el texto completo el 2026-08-11 y
  el resto son prosa de la discusión sobre la combinación de métodos —regresión, NCA, fsQCA y
  Mann-Whitney—. Hasta esta revisión el par `E008:robustez` era una de las dos entradas de
  `SIN_EXPECTATIVA_PUBLICADA`, con censo `0`; ahora no hay módulo que declarar, así que la
  entrada sobra y **la lista queda vacía**. El barrido de anclas y umbrales del motor se
  informa como descripción. Nunca cupo aquí `no_tipo_solucion`: `mod_minimizacion` de E008 es
  `si`, así que su solución sí es reproducible y ninguna fila suya puede excusarse con el
  tipo de solución.

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
con `consistencia = 0.8`, `pri = 0.6`, `frecuencia = 1` para `ICSM` y para `~ICSM` **sin
compararla**, y compara la solución parsimoniosa y el ajuste contra la Tabla 7.

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
- Produces: comparaciones de `calibracion` —contrastada **contra las columnas calibradas del propio archivo**—, `necesidad`, `ajuste` y `robustez`. `minimizacion` y `tabla_verdad` son `no_evaluable`.

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
  (2 decimales); una diferencia se registra `D-APP` y se documenta con los dos valores y con
  la definición de cuantil de cada uno, para que el informe muestre la causa sin que el CSV
  la degrade.
- **Comparación de calibración**: `fsqca-calibrador` calibra las columnas crudas y el
  resultado se compara **fila a fila** con las seis columnas calibradas del archivo,
  tolerancia `0.005` (dos decimales publicados). Son 459 × 6 comparaciones; se registra el
  número de filas fuera de tolerancia por condición, no una sola cifra agregada.
- **Umbrales** (encabezado de la Tabla 5): `n.cut = 4`, `incl.cut = 0.8`, `pri.cut = 0.6`.
- **Tabla de verdad**: `mod_tabla_verdad = no_evaluable` desde la auditoría de celdas del
  2026-08-13. El artículo publica sólo la Tabla 5, que son soluciones, y el S1 Dataset es
  `dataset.csv` con 459 casos, no una tabla de verdad. Se construye para poder minimizar y se
  informa como descripción, **sin fila y sin clave de censo**.
- **Robustez** (Tabla 6): **se mantiene en `si`**, y es una de las tres que sobreviven a la
  auditoría junto con las de E001 y E012, porque aquí sí hay cifras alternativas publicadas.
  Dos escenarios, `n.cut = 5` con `incl.cut = 0.8` y
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
(`consistencia = 0.8`, `pri = 0.6`, `frecuencia = 4`), esta última sin comparar. El ajuste
(Tabla 5) y los dos
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
3. una segunda extracción independiente coincide celda a celda. **Una celda ilegible detiene
   la Task 7**: no se completa por inferencia y no se escribe una transcripción con huecos,
   porque una comparación con un `obtenido` vacío aborta el guardián. Si la celda es
   irrecuperable, lo que cambia es el censo —esa comparación no se prerregistra— y queda
   escrito en el manifiesto, con su localizador en el prerregistro.

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
  el estudio usa para declarar necesidad. **Si el texto no fija ese umbral no hay expectativa
  publicable**, y entonces `E012:necesidad` entra en `SIN_EXPECTATIVA_PUBLICADA` con su
  localizador, en el mismo commit que lo descubra —es un cambio de dos líneas en dos
  archivos, a la vista—. Lo que no se hace es resolverlo escribiendo un `D-AMB`.

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
- Consumes: `journal.pone.0301031.s001.csv` y las Tablas 2, 4 y 5.
- Produces: comparaciones de `calibracion` —declarada **no ejercitada por la aplicación**—, `necesidad` y `ajuste`. `minimizacion`, `tabla_verdad` y `robustez` son `no_evaluable`.

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
  `decidible = no_ejercitado`, y el informe la cuenta en una categoría propia: **módulo no
  ejercitado por la aplicación**, nunca como módulo de calibración reproducido. La fila
  guarda `esperado = 100` celdas coincidentes y `obtenido = 89`, y **su código `D-EST` se
  deriva**: `no_ejercitado` devuelve `D-EST` con cualquier valor obtenido, porque una
  comparación que no ejecuta el motor no puede aprobarlo ni acusarlo. La precondición no es
  una nota escrita al lado, es `tipo_datos == "conjuntos_calibrados"` en la selección
  congelada, que hoy vale para E014 y solo para E014; marcar `no_ejercitado` en cualquier
  otro estudio, o en cualquier módulo que no sea `calibracion`, aborta.

  Esto suprime `validation/discrepancias-prerregistradas.csv`, que existía **solo** para
  esta fila y cuyo precio era una puerta abierta: cualquier código podía apartarse del dato
  con un motivo y una fecha escritos a mano.
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
- **Tabla de verdad**: `mod_tabla_verdad = no_evaluable` desde la auditoría de celdas del
  2026-08-13, y este es el caso en que la celda descansaba en el **rótulo**: la Table 3 se
  titula «Truth table», pero su contenido es una matriz **caso × condición** —las diez
  provincias por nombre × `C1`--`C10`— **sin número de casos, sin consistencia, sin PRI y sin
  columna de resultado**. Una tabla de verdad tiene configuraciones, no casos.
- **Expectativas**: Tabla 4 (diez consistencias y diez coberturas de necesidad,
  2 decimales), que son las que pueden dar `D-OK`. De la Tabla 5,
  `consistencia_solucion 0.91` y `cobertura_solucion 0.55` para el módulo `ajuste`,
  **prerregistradas `D-AMB`**.

  **Las 100 celdas de la Table 3 se quedan sin módulo, y esto es una decisión sin tomar.**
  Hasta esta revisión eran las expectativas de `tabla_verdad` de E014; con el módulo apagado
  ya no pueden serlo, y no se reasignan por su cuenta: el objeto que publican —la
  dicotomización `0/1` de las diez condiciones— se parece a una comprobación de
  `calibracion`, pero la `calibracion` de E014 es `no_ejercitado` (`D-EST`) porque el estudio
  no publica el bruto previo, así que meterlas ahí las convertiría en `D-EST` y no en la
  comparación que muerde que hoy son. Mientras no se decida, **no se prerregistran**: se
  transcriben en `validation/prerregistros/E014.md` y el informe las exhibe junto a lo que
  produzca la aplicación. Cambiarlo exige un commit propio sobre este plan.
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
sigue con necesidad (Tabla 4), que es la única de E014 que ejecuta el motor con veredicto.
La dicotomización de la Tabla 3 se calcula y se exhibe, pero **no se compara**: su módulo,
`tabla_verdad`, es `no_evaluable`. El ajuste de la Tabla 5 se afirma con
`codigo_de_la_fila()` sobre una fila `no_tipo_solucion`, que devuelve `D-AMB`. No se compara
ninguna solución.

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
transcripción tiene un dígito mal, la Tabla 1 lo delata. **Mientras esa comprobación no pase,
la Task 9 no continúa y la transcripción se rehace**: E015 no se puede declarar no ejecutable
—no está en `ESTUDIOS_NO_EJECUTABLES`, y su artefacto tiene SHA-256 verificado—, porque lo
que ha fallado no es el depósito, es el trabajo de transcripción.

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
  con `precision = decimales`, de modo que `tolerancia_de()` cuenta cero decimales en la
  cadena `"92"` y devuelve `0.5` **puntos porcentuales**. El esquema de expectativas no tiene
  columna de escala, así que el adaptador multiplica por 100 la consistencia y la cobertura
  que produce la aplicación antes de comparar, y el prerregistro lo deja escrito. Guardar
  `0.92` daría `0.005`, que es lo correcto en esa otra escala. Quitar la columna `decimales`
  cerró la *divergencia entre dos copias* de la precisión, **no** el problema de fondo: la
  tolerancia sigue saliendo de una cadena que ningún artefacto del repositorio ancla al
  artículo, y transcribir `1.00` como `1` da media unidad de tolerancia y aprueba un `0.55`
  contra una necesidad perfecta. Lo que lo acota es la comprobación de **uniformidad de
  decimales** dentro de cada `(id_estudio, fuente)` de la sección «Regla de tipo de solución
  y de ajuste». Tablas 3 y 4 (tablas de verdad de 2018 y 2021: cada fila con
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
- Produces: comparaciones de calibración, minimización, ajuste y robustez contra la **capa de referencia** del propio estudio. `necesidad` y `tabla_verdad` son `no_evaluable`.

- [ ] **Step 1: Abrir el paquete y superar la compuerta de identidad**

Run:

```bash
curl -sS -D - -o /dev/null "https://dataverse.harvard.edu/api/datasets/:persistentId/?persistentId=doi:10.7910/DVN/27100"
```

Expected: `HTTP 200` con JSON. Si vuelve `202` con `x-amzn-waf-action: challenge`, como el
2026-08-11, **la tarea se detiene aquí**: se escribe el manifiesto de E001 **sin artefactos**
y con el bloque `no_ejecutable`, y no se crean ni expectativas, ni adaptador, ni prueba. No
se sustituye el paquete por una copia de otra procedencia ni se transcriben valores del
artículo para simular la replicación.

```json
{
  "id_estudio": "E001",
  "nivel": "B",
  "doi": "10.1093/pan/mpu016",
  "licencia": "CC0-1.0",
  "fecha_verificacion": "2026-08-11",
  "artefactos": [],
  "comparaciones": {
    "calibracion": 0, "minimizacion": 0, "ajuste": 0, "robustez": 0
  },
  "fuentes": {
    "calibracion": [], "minimizacion": [], "ajuste": [], "robustez": []
  },
  "no_ejecutable": {
    "motivo": "deposito inaccesible",
    "evidencia": "HTTP 202 con x-amzn-waf-action challenge en seis rutas de dataverse.harvard.edu",
    "fecha": "2026-08-11"
  }
}
```

Eso solo pasa el guardián porque `ESTUDIOS_NO_EJECUTABLES` contiene `"E001"` y nada más, y
porque el manifiesto **no tiene artefactos**: un estudio con SHA-256 verificado no puede
declararse no ejecutable. Si el bloqueo del WAF se levanta, quitar E001 de esa constante es
un cambio de una línea en `comun-replicacion.R` y otro en la prueba de contratos, visible en
su propio commit; y a partir de ahí el guardián exige manifiesto con artefactos,
expectativas, adaptador y prueba, porque `mod_minimizacion` de E001 es `si`.

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

Los módulos comparados son `calibracion`, `minimizacion`, `ajuste` y `robustez`.
`necesidad` queda `no_evaluable` y así se informa, y `tabla_verdad` también desde la
auditoría de celdas del 2026-08-13: **el artículo no publica ninguna tabla** —su aparato
empírico son ocho figuras, y «truth table» sólo aparece en §2.2, p. 24, describiendo el
método—, y ninguno de los 144 archivos del depósito, listados vía DataCite el 2026-08-11, es
una tabla de verdad: son datos crudos, guiones y salidas de sensibilidad. Los barridos del
estudio se comparan con `barrido_robustez()` escenario a escenario: la robustez de E001 se
mantiene porque el artículo entero es un barrido de frecuencia, umbrales de inclusión y
anclas.

**Y una tensión que este plan no resuelve.** E001 es el único incluido cuya capa de
referencia no es una tabla impresa sino su script oficial (Step 3), y el depósito lleva
bloqueado desde el 2026-08-11, así que la enumeración de sus 144 archivos se hizo por
metadatos de DataCite —tamaños y formatos, **sin nombres**— y no abriéndolos. Si el bloqueo
del WAF se levanta y el script resulta emitir una tabla de verdad, si eso reabre la celda es
una decisión **de la selección congelada**, no de este plan: se arregla en
`docs/validacion/estudios.csv` y en su firma, en un commit propio.

- [ ] **Step 5: Commit**

```bash
git add validation/manifiestos/E001.json validation/prerregistros/E001.md validation/expectativas/E001.csv validation/R/adaptador-E001.R validation/tests/testthat/test-replicacion-E001.R
git commit -m "test: replicar E001 contra su script oficial"
```

Si la tarea terminó en el Step 1, el commit es otro y no crea ninguno de esos archivos: solo
el manifiesto con su bloque `no_ejecutable`.

```bash
git add validation/manifiestos/E001.json docs/validacion-integral.md
git commit -m "docs: registrar E001 como no ejecutable por bloqueo del deposito"
```

---

### Task 11: Consolidar resultados con denominadores separados

**Files:**
- Create: `validation/R/ejecutar-replicaciones.R`
- Create: `docs/validacion/replicaciones.csv`
- Create: `docs/validacion/compuertas.csv`
- Create: `validation/tests/test-consolidacion.R`

**Interfaces:**
- Consumes: los manifiestos con su censo, las expectativas y las pruebas existentes.
- Produces: un CSV de resultados y los conteos que el informe usa sin recalcularlos a mano.

- [ ] **Step 1: Escribir la prueba de consolidación**

En `validation/tests/test-consolidacion.R`. Contenido exacto, ejecutado contra un juego de
datos de prueba sobre los nueve estudios reales y sometido a treinta y nueve mutaciones antes de
escribirlo aquí:

```r
source("validation/R/comun-replicacion.R")

est  <- leer_csv("docs/validacion/estudios.csv")
inc  <- est[est$decision == "incluir", , drop = FALSE]
res  <- leer_csv("docs/validacion/replicaciones.csv")
comp <- leer_csv("docs/validacion/compuertas.csv")

stopifnot(nrow(inc) > 0L, nrow(res) > 0L)
stopifnot(identical(names(res), COLUMNAS_RESULTADOS))
stopifnot(all(res$codigo %in% CODIGOS_DISCREPANCIA))
stopifnot(all(res$modulo %in% MODULOS))

# Los denominadores no se mezclan.
stopifnot(all(res$nivel == "B"), sum(inc$nivel == "A") == 0L)

# Las compuertas solo existen para los tres estudios que arman constructos
# desde los items, y NO absuelven a nadie: son un dato que el informe publica.
stopifnot(identical(names(comp), COLUMNAS_COMPUERTAS))
stopifnot(all(comp$estado %in% ESTADOS_COMPUERTA),
          all(comp$compuerta == "agregacion"),
          setequal(comp$id_estudio, COMPUERTAS_AGREGACION),
          nrow(comp) == length(COMPUERTAS_AGREGACION))

# CENSO. Sin el, la absolucion mas simple de todas es borrar la fila y nadie
# lo ve. El conjunto de manifiestos y el de modulos de cada manifiesto salen
# de la seleccion congelada, no de lo que alguien haya escrito.
manifiestos <- list.files("validation/manifiestos", pattern = "[.]json$",
                          full.names = TRUE)
stopifnot(setequal(sub("[.]json$", "", basename(manifiestos)), inc$id),
          length(manifiestos) == nrow(inc))

expectativas <- list.files("validation/expectativas", pattern = "[.]csv$",
                           full.names = TRUE)
exp_todas <- do.call(rbind, lapply(expectativas, leer_csv))
stopifnot(nrow(exp_todas) > 0L)
stopifnot(identical(names(exp_todas), COLUMNAS_EXPECTATIVAS))
stopifnot(all(nzchar(trimws(exp_todas$esperado))))
# De la cadena `esperado` sale la tolerancia, y ningun artefacto del repositorio
# la ancla al articulo. Lo que si se puede exigir: una tabla publicada imprime
# todas sus celdas con la misma precision, asi que dentro de cada
# (id_estudio, fuente) el numero de decimales es constante. Una fila que baja
# de 3 a 2 decimales es el exploit; un archivo al que un round-trip de hoja de
# calculo le quito los ceros finales es el accidente, y multiplica por diez las
# tolerancias sin que nada chille. La clave es (id_estudio, fuente), que es la
# tabla impresa: un modulo puede sacar valores de dos tablas con precisiones
# distintas —la calibracion de E012 sale del texto a 3 decimales y de la S2 a
# 2— y agrupar por modulo aborta con datos legitimos. Que `fuente` no viaje de
# un modulo a otro lo impide el manifiesto, unas lineas mas abajo: las dos
# restricciones hacen falta porque las dos particiones se CRUZAN.
con_dec <- exp_todas[exp_todas$precision == "decimales", , drop = FALSE]
stopifnot(nrow(con_dec) > 0L)
for (g in split(vapply(con_dec$esperado, decimales_de, integer(1)),
                paste(con_dec$id_estudio, con_dec$fuente))) {
  stopifnot(length(g) > 0L, length(unique(g)) == 1L)
}
stopifnot(all(exp_todas$decidible %in% DECIDIBLE),
          all(exp_todas$modulo %in% MODULOS),
          all(exp_todas$precision %in% c("completa", "decimales", "exacta")),
          all(nzchar(trimws(exp_todas$fuente))))

ejecutables <- character(0)
for (i in seq_len(nrow(inc))) {
  id <- inc$id[i]
  m <- jsonlite::fromJSON(file.path("validation/manifiestos",
                                    paste0(id, ".json")),
                          simplifyVector = FALSE)
  stopifnot(identical(m$id_estudio, id))

  declarados <- MODULOS[vapply(
    MODULOS, function(k) identical(inc[[paste0("mod_", k)]][i], "si"),
    logical(1))]
  stopifnot(length(declarados) > 0L)
  stopifnot(setequal(names(m$comparaciones), declarados),
            length(m$comparaciones) == length(declarados))

  n <- vapply(declarados, function(k) as.integer(m$comparaciones[[k]]),
              integer(1))
  stopifnot(!any(is.na(n)), all(n >= 0L))

  ruta_exp <- file.path("validation/expectativas", paste0(id, ".csv"))
  e <- exp_todas[exp_todas$id_estudio == id, , drop = FALSE]
  r <- res[res$id_estudio == id, , drop = FALSE]

  # Absolver un estudio entero exigiria borrar el SHA-256 que el trabajo de
  # campo confirmo: un manifiesto no ejecutable no puede tener artefactos.
  if (id %in% ESTUDIOS_NO_EJECUTABLES) {
    stopifnot(!is.null(m$no_ejecutable))
  } else {
    stopifnot(is.null(m$no_ejecutable))
  }
  if (!is.null(m$no_ejecutable)) {
    stopifnot(length(m$artefactos) == 0L,
              nzchar(m$no_ejecutable$evidencia), nzchar(m$no_ejecutable$fecha),
              all(n == 0L), !file.exists(ruta_exp),
              nrow(e) == 0L, nrow(r) == 0L)
    stopifnot(veredicto(res, id) == "no ejecutable")
    next
  }
  ejecutables <- c(ejecutables, id)
  stopifnot(length(m$artefactos) > 0L, file.exists(ruta_exp))
  stopifnot(all(vapply(m$artefactos,
                       function(a) is.character(a$sha256) &&
                                   nchar(a$sha256) == 64L, logical(1))))
  stopifnot(all(e$id_estudio == id), all(e$modulo %in% declarados),
            all(r$modulo %in% declarados))
  # `fuente` agrupa la uniformidad de decimales, asi que no puede ser texto
  # libre ni viajar de un modulo a otro: una fila de `necesidad` mudada a la
  # `Tabla 8` hermana, impresa con menos decimales, quedaba en un grupo
  # uniforme. Se declara en el manifiesto POR MODULO.
  stopifnot(setequal(names(m$fuentes), declarados))
  for (mo in declarados) {
    stopifnot(all(e$fuente[e$modulo == mo] %in% unlist(m$fuentes[[mo]])))
  }

  # Cuenta congelada, modulo a modulo, en las dos direcciones. Cero solo donde
  # la lista cerrada lo admite; al menos una en todo lo demas.
  for (mo in declarados) {
    cero_admitido <- paste0(id, ":", mo) %in% SIN_EXPECTATIVA_PUBLICADA
    if (cero_admitido) {
      stopifnot(n[[mo]] == 0L)
    } else {
      stopifnot(n[[mo]] >= 1L)
    }
    stopifnot(sum(e$modulo == mo) == n[[mo]],
              sum(r$modulo == mo) == n[[mo]])
  }

  # Biyeccion por nombre entre expectativas y resultados.
  clave <- function(d) paste(d$modulo, d$comparacion, sep = "|")
  stopifnot(anyDuplicated(clave(e)) == 0L, anyDuplicated(clave(r)) == 0L,
            setequal(clave(e), clave(r)),
            nrow(e) == sum(n), nrow(r) == sum(n))
}
stopifnot(setequal(sub("[.]csv$", "", basename(expectativas)), ejecutables))
stopifnot(setequal(unique(res$id_estudio), ejecutables))

# Y los cuatro archivos de cada estudio ejecutable existen, ni uno mas ni uno
# menos: borrar la prueba de un estudio es otra forma de borrar la fila.
ids_de <- function(dir, patron) {
  sub(patron, "\\1", list.files(dir, pattern = patron))
}
stopifnot(setequal(ids_de("validation/R", "^adaptador-(E[0-9]{3})[.]R$"),
                   ejecutables))
stopifnot(setequal(ids_de("validation/tests/testthat",
                          "^test-replicacion-(E[0-9]{3})[.]R$"), ejecutables))

# El codigo no se cree: se recalcula, y nada permite apartarse del recalculo.
for (i in seq_len(nrow(res))) {
  f <- exp_todas[exp_todas$id_estudio == res$id_estudio[i] &
                 exp_todas$modulo == res$modulo[i] &
                 exp_todas$comparacion == res$comparacion[i], , drop = FALSE]
  if (nrow(f) != 1L) {
    stop("La fila de resultado ", res$id_estudio[i], "/", res$modulo[i], "/",
         res$comparacion[i], " no tiene exactamente una expectativa (",
         nrow(f), ").", call. = FALSE)
  }
  if (!identical(res$fuente[i], f$fuente)) {
    stop("La `fuente` del resultado ", res$id_estudio[i], "/",
         res$comparacion[i], " no es la de su expectativa.", call. = FALSE)
  }
  if (!identical(res$esperado[i], f$esperado)) {
    stop("El `esperado` del resultado ", res$id_estudio[i], "/",
         res$comparacion[i], " ('", res$esperado[i],
         "') no es el de su expectativa ('", f$esperado, "').", call. = FALSE)
  }
  obtenido <- suppressWarnings(as.numeric(res$obtenido[i]))
  if (!is.finite(obtenido)) {
    stop("`obtenido` no numerico en ", res$id_estudio[i], "/",
         res$comparacion[i], ": '", res$obtenido[i], "'.", call. = FALSE)
  }
  recalculado <- codigo_de_la_fila(f, obtenido, inc)
  if (!identical(res$codigo[i], recalculado)) {
    stop("El codigo de ", res$id_estudio[i], "/", res$comparacion[i],
         " esta escrito como ", res$codigo[i], " y los datos dan ",
         recalculado, ".", call. = FALSE)
  }
}

# AQUI VIVIA la aserción de la robustez de E009 —`decidible == "si"`, la unica
# fila del plan capaz de acusar al motor por un barrido—, y se retira SIN
# sustituto porque la auditoria de celdas del 2026-08-13 dejo `mod_robustez` de
# E009 en `no_evaluable`: varia PRI y frecuencia y no publica ni una cifra.
#
# No se pone otra en su lugar, y conviene saber por que. El sustituto obvio
# —exigir `decidible == "si"` a la robustez de E001 y E012— NO PUEDE FALLAR, por
# dos vias independientes: E001 esta en `ESTUDIOS_NO_EJECUTABLES`, asi que
# aporta cero filas y `all(character(0) == "si")` es TRUE por vacuidad; y E012
# no puede llevar otra cosa, porque con `modulo == "robustez"`
# `no_tipo_solucion` aborta —su `mod_minimizacion` es `si`—, `no_ejercitado`
# aborta —el modulo no es `calibracion`— y `DECIDIBLE` solo tiene esos tres
# valores. Una tautologia con aspecto de guardian es peor que ningun guardian.
# La propiedad se quedo sin portador: el unico estudio con `robustez = si` y
# `minimizacion = no_evaluable` es E026, y ahi la excusa es legitima. Lo que
# queda es el parrafo «Lo que se pierde con ese apagado, dicho en voz alta» de
# la Task 4, que es documentacion y no finge ser otra cosa.

# E014 no ejercita la aplicacion en calibracion: no cuenta como reproducida.
e014 <- res[res$id_estudio == "E014" & res$modulo == "calibracion", ]
stopifnot(nrow(e014) > 0L, all(e014$codigo == "D-EST"))

cat("consolidacion: en verde —", nrow(res), "comparaciones sobre",
    length(ejecutables), "estudios ejecutables\n")
```

- [ ] **Step 2: Implementar el corredor**

`validation/R/ejecutar-replicaciones.R` recorre `validation/manifiestos/*.json`, ejecuta el
adaptador y las comparaciones de cada estudio y escribe `docs/validacion/replicaciones.csv`
con las columnas de `COLUMNAS_RESULTADOS`. El corredor **falla** si un manifiesto no tiene
prueba, si una prueba no tiene manifiesto, si una comparación queda sin código o si aparece
un módulo que el estudio no declara.

El corredor escribe **también** `docs/validacion/compuertas.csv`, con una fila por estudio de
`COMPUERTAS_AGREGACION`: compara los promedios por constructo contra la tabla publicada del
estudio y anota `pasa`, `no_pasa` o `no_aplica`, con las cifras de las dos en `detalle`. El CI
le hace `rm -f` a ese archivo y exige que reaparezca, así que el corredor tiene que
producirlo; hasta la revisión anterior el plan no lo decía en ninguna parte.

**El corredor no escribe el código: lo pide a `codigo_de_la_fila()`**, con la misma llamada
que el guardián repite después. Y no escribe `esperado` ni `fuente`: los copia de la
expectativa, carácter a carácter, porque el guardián compara las dos cadenas. Lo único que el
corredor produce por su cuenta es `obtenido`.

- [ ] **Step 3: Calcular los veredictos por estudio**

Con las categorías de la especificación §9, aplicadas **solo a los módulos declarados**:
*Reproducido* (todo dentro de tolerancia y sin `D-APP`), *Reproducción parcial* (algún
`D-AMB` o no evaluable, ningún `D-APP`) y *No reproducido* (al menos un `D-APP` en
membresías, selección de filas, solución o ajuste).

El recuento por módulo distingue tres estados y no dos, porque `mod_* == "si"` significa
«el estudio publica algo comparable», no «la aplicación lo reprodujo»:

- **reproducido**: hay al menos una comparación `D-OK` y ninguna `D-APP`;
- **no decidible**: todas sus comparaciones son `D-AMB` —el ajuste de E009, E014, E025,
  E026 y E027, y la robustez de E026—, o no tiene ninguna porque el estudio no publica nada
  comparable, caso que hoy no se da en ningún módulo declarado y por eso
  `SIN_EXPECTATIVA_PUBLICADA` está vacía: los dos que había —la tabla de verdad de E025 y la
  robustez de E008— dejaron de estar declarados en la auditoría de celdas del 2026-08-13;
- **no ejercitado por la aplicación**: la comparación no ejecuta el motor. Hoy solo cae aquí
  la calibración de E014, por `decidible = no_ejercitado`.

Un módulo «no decidible» o «no ejercitado» **no suma** al recuento de módulos reproducidos
en ningún lugar del informe.

El informe publica además, por estudio y módulo, **el conteo prerregistrado del manifiesto
junto a su fuente**. Es lo que convierte una poda en algo visible en el documento y no solo
en un diff: si mañana el ajuste de E008 pasa de dos comparaciones a una, el informe lo dice.

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
source("validation/R/comun-replicacion.R")
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

# El informe no se cree: se GENERA desde el CSV y los manifiestos. Sin esto
# podia decir «E025: reproducido» con un D-APP registrado, y era la unica
# sancion que quedaba tras sacar el D-APP del CI.
res <- leer_csv("docs/validacion/replicaciones.csv")
inc <- subset(leer_csv("docs/validacion/estudios.csv"), decision == "incluir")
# Una clave, UNA linea. `exige_exacto()` pedia que ALGUNA linea terminara con
# el valor y nada impedia publicar ademas la ancha: bastaba dejar las dos, y
# eso alcanzaba tambien al censo, que es la mitigacion central de la Task 12.
# `unico()` cierra de golpe la forma prefijo y la forma linea duplicada, en las
# cuatro familias y sin dos anclas distintas que alguien pueda unificar.
lineas <- readLines("docs/validacion-integral.md", warn = FALSE)
unico <- function(clave, valor) {
  # APARICIONES, no lineas: `grep()` cuenta una linea que lleva la clave dos
  # veces como una sola, y `endsWith` solo mira el final, asi que el ataque de
  # publicar el valor viejo y el nuevo cabia entero en UNA linea —incluido el
  # censo, que es la mitigacion central de la Task 12— y el lector veia el viejo.
  apar <- vapply(gregexpr(clave, lineas, fixed = TRUE),
                 function(m) if (m[1L] == -1L) 0L else length(m), integer(1))
  if (sum(apar) != 1L) {
    stop("El informe publica ", sum(apar), " apariciones de '", clave,
         "'; tiene que publicar exactamente una.", call. = FALSE)
  }
  if (!endsWith(lineas[apar == 1L], paste0(clave, valor))) {
    stop("El informe dice otra cosa que el CSV en '", clave, "': el CSV da '",
         valor, "'.", call. = FALSE)
  }
}
unico("D-APP registrados: ", sum(res$codigo == "D-APP"))
for (i in seq_len(nrow(inc))) {
  unico(paste0(inc$id[i], ": "), veredicto(res, inc$id[i]))
  man <- jsonlite::fromJSON(sprintf("validation/manifiestos/%s.json", inc$id[i]),
                            simplifyVector = FALSE)
  for (k in names(man$comparaciones)) {
    unico(sprintf("%s/%s: ", inc$id[i], k), man$comparaciones[[k]])
    fu <- paste(unlist(man$fuentes[[k]]), collapse = ", ")
    unico(sprintf("%s/%s/fuentes: ", inc$id[i], k),
          if (nzchar(fu)) fu else "(ninguna)")
  }
}
# La ambiguedad de `no_pasa` es una promesa del plan: el informe la declara.
stopifnot(grepl("no distingue si falla la hipótesis de agregación o el motor",
                doc, fixed = TRUE))

for (r in c("README.md", "README.es.md")) {
  txt <- paste(readLines(r, warn = FALSE), collapse = "\n")
  stopifnot(!grepl("validada externamente", txt, fixed = TRUE))
}
cat("informe: coincide con", nrow(res), "comparaciones del CSV\n")
```

- [ ] **Step 2: Redactar el informe**

`docs/validacion-integral.md` contiene, en este orden: la declaración de alcance literal; el
protocolo y sus tolerancias congeladas; la tabla de artefactos con hashes; una sección por
estudio con sus módulos declarados, sus comparaciones y su veredicto; la tabla de
compuertas previas; la tabla de discrepancias por código; los denominadores **separados**
—`Nivel A: 0 de 0 estudios, no evaluada`, y el recuento de Nivel B por módulo, con sus tres
estados: reproducido, no decidible y no ejercitado por la aplicación—; y los límites: la
minimización solo es comparable en E001, E008, E012 y E015, la **tabla de verdad solo en
E012 y E015** y la **robustez solo en E001, E012 y E026** —los demás publican la tabla de
soluciones, no la de verdad, y llaman robustez a un párrafo sin cifras—; la muestra no es
exhaustiva, Dataverse global, GESIS y UK Data Service no fueron enumerables e ICPSR exigió
credenciales.

**El informe no se redacta: se genera desde `docs/validacion/replicaciones.csv` y los
manifiestos**, y `test-informe-validacion.R` lo comprueba exigiendo que aparezcan **literales**
cuatro familias de cadenas construidas desde esos archivos: `<ID>: <veredicto>` por estudio,
`D-APP registrados: <n>`, `<ID>/<módulo>: <n>` para todo el censo y
`<ID>/<módulo>/fuentes: <lista>` para el dominio de `fuente` de cada módulo. Sin eso, el
informe era la única sanción que quedaba tras sacar el `D-APP` del CI y **nada lo ataba al
CSV**: podía decir «E025: reproducido» con un `D-APP` registrado y las cuatro pruebas en verde.
Y hace que bajar un conteo, o ampliar el dominio de un módulo, obligue a cambiar el documento
público.

**El formato de esas cadenas es parte del contrato, no un detalle del generador**, y la regla
es **una sola para las cuatro familias**: la clave aparece **exactamente una vez en todo el
documento** y **la línea que la lleva termina en el valor**. Nada de anclas distintas para el
número y para el texto —esa distinción existió dos revisiones y se retiró: contra texto el
ancla numérica degradaba a comprobación de prefijo—. De ahí que la línea de `fuentes` tenga que
salir exactamente así:

- las tablas separadas por **coma y espacio** (`, `);
- **en el orden en que están en el manifiesto**, no alfabético;
- y `(ninguna)` cuando la lista está vacía —los módulos cuyo censo es `0`—;
- y **nada detrás**: la línea termina en la última tabla.

Y **nada detrás** vale igual para las otras tres: `- E025/necesidad: 2` pasa y
`- E025/necesidad: 2 comparaciones` **no**. `unico()` cuenta **apariciones, no líneas** —con
`gregexpr()`—, porque contando líneas el ataque cabía entero en una: publicar
`- E008/calibracion: 4 comparaciones prerregistradas; censo vigente E008/calibracion: 3`
dejaba una poda real en verde y el lector veía el `4`. Eso acota la redacción: ninguna frase
del documento puede contener `E025: `, `E025/necesidad: `, `E025/necesidad/fuentes: ` ni
`D-APP registrados: ` fuera de su línea generada.

**Y aquí está el techo del guardián, dicho para que nadie lo confunda con una garantía:**
`unico()` ata **la línea generada** al CSV y **no puede atar la prosa que la rodea**. Un
informe puede publicar la línea correcta y contradecirla en el párrafo de al lado —«E008 se
reprodujo entero: las 11 comparaciones coinciden»—, o repetir la clave con un carácter
distinto —dos puntos por coma, un espacio duro en vez de un espacio—, y las pruebas seguirán
en verde. **La defensa contra eso es que un humano lea el documento, no el CI**, y por eso el
informe no se publica sin revisión: lo que el CI garantiza es que las cifras generadas son las
del CSV, no que el texto que las envuelve diga la verdad.

Si la primera ejecución falla por una coma, lo que se corrige es el generador, nunca la
comprobación.

Además, junto a la tabla de compuertas, el informe **declara la ambigüedad de `no_pasa` con
esta frase literal**, que `test-informe-validacion.R` exige igual que exige la declaración de
alcance: «un `no_pasa` es ambiguo por construcción, es decir que **no distingue si falla la
hipótesis de agregación o el motor**». Sin esa aserción la ambigüedad era una promesa escrita
en seis sitios del plan y en ninguno del documento público.

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
- Produces: un trabajo que falla ante cualquier omisión, cualquier incoherencia del proceso y cualquier artefacto que cambió en origen — y que **sigue verde cuando un estudio no se reproduce**.

- [ ] **Step 1: Escribir el guardián de omisiones**

`validation/tests/test-sin-omisiones.R` recorre **todo `validation/`, no solo las pruebas**
—un `skip` se esconde mejor en un adaptador o en el corredor que en un test— y además el
flujo de CI, para que `continue-on-error` no pueda colarse en el YAML. Prohíbe redefinir una
constante del común con `<-`, `=`, `<<-` o `assign()` **esté donde esté en la línea**: el
patrón anterior estaba anclado al principio y `local({ MODULOS <<- ... })` pasaba en verde.
Y prohíbe que un adaptador calcule lo que se compara.

Tres huecos medidos y cerrados en esta pasada, todos de la misma forma —el guardián miraba
la escritura literal y no la propiedad—:

1. **`patron` y `patron_assign` se construían sólo con `CONSTANTES`**, así que las
   `FUNCIONES` quedaban fuera y se podía redefinir `tolerancia_de()` en un adaptador o en
   una prueba. Es justo la palanca ×10: `tolerancia_de <- function(...) 10 * ...` aprueba
   cualquier comparación del circuito sin tocar ni un dato. Los dos patrones se construyen
   ahora con `NOMBRES_DEL_COMUN <- c(CONSTANTES, FUNCIONES)`.
2. **`PROHIBIDOS` casaba con `fixed = TRUE`**, de modo que `if(interactive())` sin espacio
   —o `testthat :: skip`— no se detectaba. Se comparan las dos cadenas con los espacios y
   tabuladores quitados.
3. **`SIN_ADJUNTAR` no cubría los espacios de nombres.** `asNamespace`, `loadNamespace`,
   `attachNamespace` y el `get(..., envir = asNamespace("calibraqca"))` esquivaban la lista
   blanca del adaptador sin escribir `::` ni `library()`. Los tres nombres entran en la
   lista.

Contenido exacto, ejecutado y mutado:

```r
# Ninguna omision en NINGUN archivo de validation/ ni en el YAML del CI: un
# `skip` se esconde mejor en un adaptador que en un test. Ninguna redefinicion
# de una constante del comun, ESTE DONDE ESTE en la linea: el patron anclado
# al principio dejaba pasar `local({ MODULOS <<- ... })`. Y ningun adaptador
# que calcule lo que se compara: el adaptador solo prepara la entrada.
PROHIBIDOS <- c("testthat::skip", "skip_if", "skip_on", "continue-on-error",
                "if (interactive())")
CONSTANTES <- c("MODULOS", "MODULOS_DEPENDIENTES_DE_SOLUCION", "DECIDIBLE",
                "VEREDICTOS", "CODIGOS_DISCREPANCIA", "COLUMNAS_EXPECTATIVAS",
                "COLUMNAS_RESULTADOS", "COLUMNAS_COMPUERTAS",
                "SIN_EXPECTATIVA_PUBLICADA", "ESTUDIOS_NO_EJECUTABLES",
                "COMPUERTAS_AGREGACION", "ESTADOS_COMPUERTA")
FUNCIONES <- c("codigo_de_la_fila", "veredicto", "tolerancia_de", "comparar",
               "obtener_artefacto", "decimales_de", "leer_csv",
               "exigir_declarado")
# Lo unico que un adaptador puede llamar del paquete: leer y mapear.
ADAPTADOR_PERMITE <- c("leer_datos", "definir_mapeo", "definir_anclas",
                       "promediar_constructos")
# Sin esto la lista blanca es ciega: `library(calibraqca)` y una llamada sin
# `::` la esquivan en una linea.
SIN_ADJUNTAR <- c("library(", "require(", "getFromNamespace", "getExportedValue",
                  ":::", "asNamespace", "loadNamespace", "attachNamespace")
# `get("calibrar", envir = asNamespace("calibraqca"))` esquivaba la lista blanca
# sin escribir `::` ni `library()`: queda cubierto por `asNamespace`.
SOURCE <- 'source("validation/R/comun-replicacion.R")'
YO <- "test-sin-omisiones.R"

# Los nombres del comun que ningun otro archivo puede redefinir. Las FUNCIONES
# entran aqui, no solo las CONSTANTES: lo que se escapaba era `tolerancia_de`,
# que es justo la palanca x10 —redefinirla multiplica por diez la tolerancia de
# todo el circuito y ninguna comparacion se pone roja—.
NOMBRES_DEL_COMUN <- c(CONSTANTES, FUNCIONES)

# `fixed = TRUE` no ve `if(interactive())` sin espacio, ni `testthat :: skip`.
# Se comparan las dos cadenas con TODOS los espacios y tabuladores quitados.
sin_espacios <- function(x) gsub("[ \t]+", "", x)

archivos <- c(list.files("validation", full.names = TRUE, recursive = TRUE),
              ".github/workflows/pruebas.yml")
archivos <- archivos[file.exists(archivos)]
stopifnot(length(archivos) > 1L)
stopifnot(any(grepl("^validation/R/adaptador-", archivos)))
stopifnot(".github/workflows/pruebas.yml" %in% archivos)

orden <- order(nchar(NOMBRES_DEL_COMUN), decreasing = TRUE)
patron <- paste0("(^|[^[:alnum:]._])(", paste(NOMBRES_DEL_COMUN[orden],
                                              collapse = "|"),
                 ")[ \t]*(<<-|<-|=(?!=))")
patron_assign <- paste0("assign[ \t]*\\([ \t]*[\"'](",
                        paste(NOMBRES_DEL_COMUN[orden], collapse = "|"), ")")

for (f in archivos) {
  if (basename(f) == YO) next
  lineas <- readLines(f, warn = FALSE)
  texto <- paste(lineas, collapse = "\n")
  texto_apretado <- sin_espacios(texto)

  for (p in PROHIBIDOS) {
    if (grepl(sin_espacios(p), texto_apretado, fixed = TRUE)) {
      stop("Omision en ", f, ": ", p, call. = FALSE)
    }
  }

  if (!grepl("[.]R$", f)) next

  usa <- any(vapply(NOMBRES_DEL_COMUN,
                    function(x) grepl(paste0("\\b", x, "\\b"), texto),
                    logical(1)))
  es_el_comun <- identical(basename(f), "comun-replicacion.R")
  if (usa && !es_el_comun && !grepl(SOURCE, texto, fixed = TRUE)) {
    stop("El archivo ", f, " usa el comun sin cargarlo: falta ", SOURCE, ".",
         call. = FALSE)
  }
  if (es_el_comun) next

  redefine <- grep(patron, lineas, value = TRUE, perl = TRUE)
  asignadas <- grep(patron_assign, lineas, value = TRUE, perl = TRUE)
  if (length(redefine) + length(asignadas) > 0) {
    stop("El archivo ", f, " redefine una constante del comun: ",
         paste(trimws(c(redefine, asignadas)), collapse = " | "), call. = FALSE)
  }

  for (a in SIN_ADJUNTAR) {
    if (grepl(a, texto, fixed = TRUE)) {
      stop("El archivo ", f, " adjunta un paquete con ", a, ": toda llamada ",
           "va calificada con `::`, o la lista blanca del adaptador es ciega.",
           call. = FALSE)
    }
  }

  if (grepl("^validation/R/adaptador-", f)) {
    llamadas <- unique(regmatches(
      texto, gregexpr("calibraqca::[A-Za-z_.]+", texto))[[1L]])
    prohibidas <- setdiff(sub("^calibraqca::", "", llamadas),
                          ADAPTADOR_PERMITE)
    if (length(prohibidas) > 0) {
      stop("El adaptador ", f, " calcula lo que se compara: ",
           paste(prohibidas, collapse = ", "),
           ". Un adaptador prepara la entrada; quien produce el numero es la ",
           "prueba, a la vista.", call. = FALSE)
    }
  }
}
cat("sin omisiones, sin constantes redefinidas y sin adaptadores que calculen:",
    length(archivos), "archivos\n")
```

**No hay `Step 1b`.** El verificador de la tabla de módulos del plan desaparece con la tabla:
31 líneas de prueba para sostener 11 de tabla copiada, cuando el CSV se puede imprimir. Lo
único que esa tabla sostenía y que sigue haciendo falta —que la minimización sea comparable
en cuatro estudios y solo cuatro— es una línea de `test-contratos-replicacion.R` contra
`estudios.csv`.

- [ ] **Step 2: Añadir el trabajo `replicaciones`**

En `.github/workflows/pruebas.yml`, un trabajo nuevo con el mismo entorno que `testthat`
(`setup-r` 4.6.1, `setup-renv`, las mismas dependencias de sistema), que ejecuta:

```yaml
      - name: Contratos y guardianes
        run: |
          Rscript --vanilla validation/tests/test-contratos-replicacion.R
          Rscript --vanilla validation/tests/test-sin-omisiones.R

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
            # Un fallo de testthat aqui es un fallo de PROCESO: un artefacto que
            # cambio en origen, un adaptador que no devuelve la forma declarada,
            # una comparacion que no produjo un numero. Ninguna prueba afirma
            # que la aplicacion reproduzca el estudio, asi que un D-APP no llega
            # nunca a este contador.
            if (fallos > 0) stop("El proceso de replicacion esta roto.")
            if (sum(r$skipped) > 0) stop("Hay pruebas omitidas: una prueba omitida es una prueba que no existe.")
            res <- utils::read.csv("docs/validacion/replicaciones.csv")
            cat("D-APP registrados:", sum(res$codigo == "D-APP"), "\n")
          '

      - name: Consolidacion e informe
        run: |
          Rscript --vanilla validation/tests/test-consolidacion.R
          Rscript --vanilla validation/tests/test-informe-validacion.R
```

**Ningún paso se pone rojo porque un estudio no se reproduzca.** El CI corta ante
incoherencias del proceso —censo que no cuadra, biyección rota, código que no deriva de los
datos, omisiones, constantes redefinidas, artefacto que cambió en origen— y **no** ante un
`D-APP`, que es un resultado científico: se registra, baja el veredicto de ese estudio y se
publica en `docs/validacion-integral.md`. El último `cat` lo deja a la vista en el registro
del trabajo sin condicionar su estado.

Hasta la revisión anterior las dos mitades del plan se contradecían: la prueba ejemplar de la
Task 2 exigía `D-OK` y este paso cortaba con «Hay replicaciones en rojo», mientras la Task 2
Step 6 y `test-consolidacion.R` daban por hecho que un `D-APP` se registra y baja el
veredicto. Con un defecto real de la aplicación, la única forma de dejar el CI verde era
alguna de las mudanzas conocidas. **Esa contradicción era la presión que fabricó seis
absorbedores en cuatro rondas**, y quitarla es lo que hace que los guardianes tengan sentido:
si no hay nada que ganar absolviendo, el guardián deja de ser una carrera.

`rm -f` antes de correr no es decorativo: sin él, el paso siguiente podría estar leyendo el
CSV de la ejecución anterior y cantar verde con el corredor roto.

Lo que el `rm -f` **no** protege, y conviene saberlo, son los archivos versionados que el
corredor no regenera: `validation/expectativas/*.csv` y los manifiestos. Ahí es donde vivía
la absolución, y por eso el censo tiene que estar en el manifiesto y comprobarse en las dos
direcciones: la defensa de esos archivos no es el CI, es `test-consolidacion.R`.

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
  nombres de archivo de E001. **Desde la décima pasada (2026-08-13) hay además dos asuntos
  sin resolver, nombrados donde tocan**: a qué módulo van las 100 celdas de la Table 3 de
  E014 (Task 8), si `E015:calibracion` tiene alguna expectativa publicable (Task 9 y cierre
  de la décima pasada) y la auditoría de `E012:necesidad`, declarada en esa misma pasada.
  Ninguno se resuelve escribiendo una celda.
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
   **(Superado: la tabla de módulos y `test-tabla-modulos-del-plan.R` desaparecieron en la
   quinta pasada —31 líneas de prueba para sostener 11 de tabla copiada—, así que ese
   archivo no existe y no corre en ningún CI. Lo único que la tabla sostenía y sigue
   haciendo falta es una línea de `test-contratos-replicacion.R` contra `estudios.csv`.
   Este párrafo describe el diseño de la tercera pasada, no el vigente.)**
4. **Una aserción que no podía fallar.** `stopifnot(is.logical(vapply(..., logical(1))))` es
   verdadera para cualquier contenido del CSV: `vapply(..., logical(1))` siempre devuelve
   `logical`. Era una aserción de FORMA donde hacía falta una de PROPIEDAD. Se sustituyó por
   `veredicto()`, función pura sobre la tabla, probada con la **pareja de casos opuestos**
   —un estudio con `D-AMB` que no puede quedar como reproducido y otro sin él que sí—.
5. **Un umbral llevado al dato, no al parámetro.** La prueba de contratos comparaba `0.9155`
   con `0.916` esperando `D-OK` a tres decimales: la diferencia en coma flotante es
   `0.0005000000000000004` y la aserción fallaba. Se movió el **parámetro**: la misma pareja
   de valores da `D-APP` con `decimales = 3` y `D-OK` con `decimales = 2`.

### Cuarta pasada, 2026-08-11 (matar la mudanza, no el síntoma)

El absorbedor murió por estudio y renació por fila: `no_sin_fuente` absolvía en cualquier
módulo con solo escribir «ausente» en un texto libre. Es la cuarta vez en esta rama que el
mismo defecto cambia de sitio, y las cuatro con las pruebas en verde. Esta pasada no le
añade otra condición: le quita el mecanismo.

- **Ninguna marca del dato absuelve por sí sola.** Quedan dos motivos y los dos tienen
  precondición comprobable contra un artefacto que ya existe: `no_tipo_solucion` se valida
  contra `mod_minimizacion` en `estudios.csv`, y `no_insumo_ausente` contra una fila
  completa de `validation/ausencias.csv`. La palabra escrita en `fuente` ya no decide nada.
  **(Superado: `no_insumo_ausente` y `validation/ausencias.csv` no existen desde la quinta
  pasada. Este párrafo describe el diseño de la cuarta, no el vigente.)**
- **Tres módulos no admiten absolución de ninguna clase.** `calibracion`, `necesidad` y
  `tabla_verdad` se calculan desde el artefacto verificado: si el artefacto está, el insumo
  está.
- **Sin expectativa publicada no hay fila**, hay una ausencia registrada con localizador.
  Una fila absuelta es una comparación que finge existir.
- **El código no se escribe, se recalcula.** Y si difiere del dato, exige una discrepancia
  prerregistrada con motivo y fecha. Esto cierra la presión que el propio plan creaba: un
  guardián que exige `D-AMB` empuja a degradar un `D-APP` legítimo.
- **La tolerancia no se infla desde el dato.** `decimales` tiene que corresponder al valor
  guardado.
- **`stopifnot(logical(0))` aprueba.** Toda comprobación sobre una celda que podría no
  existir pasa por `exigir_declarado()`, que muere con `NULL`, con `NA` y con longitud
  distinta de uno.
- **El guardián de omisiones mira todo `validation/` y el YAML del CI**, y prohíbe redefinir
  una constante del común con `<-`, `=`, `<<-` o `assign()`.

Dónde puede mudarse ahora: quedan dos columnas que viajan con el dato y que ningún artefacto
externo puede falsar, `obtenido` y `motivo`. La primera la escribe el corredor y el CI la
regenera desde cero —`rm -f` antes de correr—, así que una edición a mano no sobrevive a una
corrida; la segunda es texto para el lector y ya no decide ningún código. La siguiente
revisión debería empezar por ahí.

### Quinta pasada, 2026-08-11 (contar lo que debe existir, y quitar 400 líneas)

La cuarta pasada miró dónde se escribía un código y no dónde se **borraba una fila**. El
defecto se mudó por sexta vez, a la forma más simple de todas: quitar la comparación
incómoda. Bastaba omitir una línea de `docs/validacion/replicaciones.csv` para que el
veredicto de E008 **subiera** de «no reproducido» a «reproducido» con el CI en verde, y
borrar `validation/expectativas/E026.csv` entero dejaba a E026 en «no ejecutable», también
en verde. El `rm -f` del CI no protegía nada de eso: regenera los resultados, pero las
expectativas y los registros están versionados.

Lo que esta pasada añade es **una sola idea**: el manifiesto de cada estudio congela cuántas
comparaciones tiene cada módulo, y ese censo se comprueba contra la selección congelada en
las dos direcciones. Con eso caen a la vez las seis mudanzas conocidas. Lo demás es
**quitar**:

- **`no_insumo_ausente` y `validation/ausencias.csv` desaparecen.** No cubrían ni un caso
  que `no_tipo_solucion` no cubriera y su alcance era más ancho: barriendo los 9 × 6 pares
  estudio-módulo, absolvía 27 frente a 15, incluidos los cuatro estudios cuya solución sí es
  reproducible.
- **`validation/discrepancias-prerregistradas.csv` desaparece.** Existía para una sola fila,
  la calibración no ejercitada de E014, y a cambio dejaba escribir cualquier código a mano
  con un motivo y una fecha. Ese caso ahora se deriva de `tipo_datos` en la selección
  congelada, y por eso `D-FMT` y `D-DEP` salen del dominio: no tenían derivación.
- **`docs/validacion/no-ejecutables.csv` desaparece.** Era el absorbedor más ancho de todos
  —una fila absolvía un estudio entero— y su contenido vive en el manifiesto, donde la lista
  cerrada `ESTUDIOS_NO_EJECUTABLES` y la exigencia de no tener artefactos lo acotan.
- **La columna `decimales` desaparece, y con ella `decimales_coherentes()`.** La tolerancia
  se cuenta sobre la cadena publicada. Es recorte y arreglo a la vez: cerraba a medias la
  inflación por ceros finales, porque `0.860` leído como número es `0.86`.
- **`MODULOS_SIEMPRE_DECIDIBLES` desaparece**: era el complemento exacto de
  `MODULOS_DEPENDIENTES_DE_SOLUCION` dentro de los seis módulos, y una constante que se puede
  vaciar convierte en muda a la prueba que la recorre.
- **La tabla de módulos y `test-tabla-modulos-del-plan.R` desaparecen.** Una tabla copiada a
  mano más una prueba que demuestra que es copia cuesta más que imprimir el CSV.

Y una **séptima mudanza** que este plan buscó antes de entregar y cerró aquí mismo: el
**adaptador** era el sitio perfecto para fabricar el número comparado —nadie lo miraba— y la
**compuerta de agregación** era un absorbedor por estudio que convertía todas las filas en
`D-AMB` con una palabra en un CSV. El adaptador queda restringido a leer y mapear con una
lista blanca; la compuerta, a tres estudios, y solo absuelve en los dos cuya regla de
agregación no publica el artículo.

Dónde puede mudarse ahora, con el mismo criterio de nombrarlo en vez de callarlo:

1. **El censo se puede reducir editando el manifiesto.** Borrar una comparación exige hoy
   tres cambios coordinados —resultado, expectativa y conteo—, todos visibles en el diff y
   el último en la ficha de procedencia del estudio. Ningún artefacto del repositorio puede
   recontar la tabla de un artículo, así que ahí termina lo que el código puede sostener; por
   eso el informe publica el conteo junto a su fuente, para que la reducción se vea también
   en el documento.
2. **El corredor escribe `obtenido`.** Si el corredor lo copiara de `esperado`, todo cuadra.
   Es una defensa de proceso —el CI regenera el CSV— y de lectura humana, no de código.
3. **Un adaptador puede fabricar un número con aritmética propia.** La lista blanca impide
   que llame al motor, no que invente. Solo lo ve quien lo lea.

### Sexta pasada, 2026-08-11 (quitarle al verde su precio)

La quinta pasada contó lo que debe existir y cerró seis mudanzas, pero dejó tres agujeros y
—lo importante— **no tocó la causa**. Esta pasada empieza por la causa.

**La causa.** El plan no tenía camino verde para un `D-APP` legítimo: la prueba ejemplar de
la Task 2 exigía `D-OK` y el CI cortaba con «Hay replicaciones en rojo», mientras el resto
del plan daba por hecho que un `D-APP` se registra y baja el veredicto. Las dos mitades no
podían ser ciertas a la vez, así que ante un defecto real de la aplicación **la única forma
de dejar el CI verde era alguna de las mudanzas**. Eso es lo que fabricó seis absorbedores en
cuatro rondas: no descuido, sino un incentivo escrito en el plan.

Resolución: **un `D-APP` es un resultado científico, no un fallo de proceso.** El CI se pone
rojo ante incoherencias del proceso —censo que no cuadra, biyección rota, código que no
deriva de los datos, omisiones, constantes redefinidas, artefacto cambiado en origen— y
**no** ante un estudio que no se reproduce. Una prueba de replicación afirma propiedades del
proceso y **no** que la aplicación reproduzca el estudio; el `D-APP` se registra, baja el
veredicto y se publica. Si no hay nada que ganar absolviendo, el guardián deja de ser una
carrera.

**La octava mudanza: la compuerta de agregación.** Era el absorbedor por estudio otra vez, y
automatizado: una celda en `no_pasa` convertía todas las filas en `D-AMB` sin contradicción
detectable, y quien construye los constructos que la compuerta contrasta es
`promediar_constructos()`, código de la propia aplicación. **La compuerta pierde todo poder
sobre los códigos**; `codigo_de_la_fila()` pierde su parámetro y `COMPUERTA_ABSUELVE`
desaparece. La media se calcula dos veces —con esa función y con `rowMeans()` de base R— y el
estado distingue `no_pasa_regla` (la hipótesis del plan es la equivocada) de `no_pasa_app`
(defecto de `fsqca-calibrador`), que es la pareja de casos opuestos que faltaba: hasta ahora
solo existía el caso en que hay que callar.

**La tolerancia, de verdad esta vez.** Quitar la columna `decimales` cerró la divergencia
entre dos copias, no el fondo: `0.860` guardado como `0.86` en las dos copias, o `1.00`
transcrito como `1`, siguen inflando la tolerancia diez o cien veces, y lo segundo aprueba un
`0.55` contra una necesidad perfecta. Sin conocimiento externo solo se puede exigir una cosa,
y basta para los dos casos: **una tabla publicada imprime todas sus celdas con la misma
precisión**, así que dentro de cada `(id_estudio, fuente)` el número de decimales es
constante. Sustituye a `stopifnot(is.character(exp_todas$esperado))`, que afirmaba una
propiedad de `leer_csv()` y no podía fallar.

**La lista blanca del adaptador se esquivaba con una línea**: `library(calibraqca)` y la
llamada sin `::`. Ningún archivo de `validation/` puede adjuntar un paquete —`library(`,
`require(`, `getFromNamespace`, `getExportedValue`, `:::`—, así que toda llamada va
calificada y la lista blanca vuelve a ver.

**Y una incoherencia que sobraba**: este plan garantizaba que `tabla_verdad` «no admite
absolución de ninguna clase» y a la vez metía `E025:tabla_verdad` en
`SIN_EXPECTATIVA_PUBLICADA`. La garantía es sobre el `decidible` de una fila que existe;
decir que el módulo entero era comparable era una promesa más ancha de lo que el código
sostiene. Reescrita.

También se fue el bucle final de veredictos sobre los datos reales: era una tautología sobre
`veredicto()`, y la pareja de casos opuestos ya vive en la prueba de contratos.

Dónde puede mudarse ahora:

1. **El censo sigue siendo editable** en tres cambios coordinados. Sin cambios desde la
   quinta pasada, y sin solución dentro del repositorio.
2. **La uniformidad de decimales no ata la cadena al artículo.** Un grupo de una sola fila no
   restringe nada, y una tabla en la que *todos* los valores terminan en cero pierde los ceros
   de forma uniforme y pasa.
3. **`no_pasa_regla` frente a `no_pasa_app` lo mide el corredor**, y ningún guardián puede
   recomputarlo. Ya no absuelve a nadie, así que mentir ahí solo desinforma al lector del
   informe; pero desinforma. *(La séptima pasada retira esa distinción entera: no era
   medible.)*

### Séptima pasada, 2026-08-11 (cerrar las claves de texto libre y la promesa muerta)

Cuatro cosas, y tres de ellas son la misma de siempre con otro disfraz.

1. **La clave del grupo de tolerancia era texto libre.** La uniformidad de decimales agrupa
   por `(id_estudio, fuente)`, y `fuente` se escribía en la fila: dos celdas de la misma línea
   —`"0.860"` → `"0.86"` y `"Tabla 9"` → `"Tabla 9 (cobertura)"`— dejaban a esa fila sola en
   su grupo, con el censo cuadrado, la biyección intacta y el diff con aspecto de corrección
   editorial. Es la novena mudanza y es literalmente el patrón que esta rama lleva persiguiendo
   desde `no_sin_fuente`. **`fuente` pasa a ser un dominio cerrado declarado en el manifiesto**
   (`"fuentes": [...]`), y el resultado tiene que citar la misma que su expectativa.
2. **La selección congelada no la congelaba ninguna prueba.** De las 44 celdas `mod_* == "si"`,
   35 podían apagarse a `no_evaluable` —con la poda coordinada que el censo exige— y salir en
   verde, incluidas todas las de `necesidad` salvo E009 y todas las de `tabla_verdad`. Y esta
   vía **esquivaba la mitigación publicada del censo**: al dejar de estar declarado el módulo,
   su línea desaparece del manifiesto y del informe, indistinguible de una limitación genuina.
   Las 44 celdas quedan fijadas en `test-contratos-replicacion.R` como tabla de valores
   esperados, el mismo mecanismo que ya anclaba `mod_minimizacion`.
3. **El informe era la única sanción de un `D-APP` y nada lo ataba al CSV.** Podía decir
   «E025: reproducido» con un `D-APP` registrado y las cuatro pruebas en verde. Ahora
   `test-informe-validacion.R` **genera** desde `replicaciones.csv` y los manifiestos las
   cadenas que el documento debe contener —`<ID>: <veredicto>`, `D-APP registrados: <n>` y
   `<ID>/<módulo>: <n>`— y exige que aparezcan literales. Eso convierte además la mitigación
   del censo de decorativa en real: bajar un conteo obliga a cambiar el documento público.
4. **La doble media no discriminaba, y no existía.** Medido el motor real,
   `promediar_constructos()` **es** `rowMeans(x, na.rm = TRUE)` más `PROPORCION_MINIMA_ITEMS`:
   sobre datos completos las dos medias coinciden bit a bit, así que `no_pasa_app` era
   inalcanzable y toda caída de compuerta se habría publicado como culpa del plan, incluida la
   que fuera culpa del motor. Y la doble media solo vivía en prosa. **Se retira la promesa**:
   `ESTADOS_COMPUERTA` colapsa a `pasa | no_pasa | no_aplica`, `no_pasa` se declara **ambiguo
   por construcción** y el informe lo explica. Una promesa con el discriminador muerto es peor
   que no tener discriminador.

De paso: `registrar()`, que la prueba ejemplar de la Task 2 llamaba sin estar definida en
ningún bloque —y esa prueba es la plantilla que copian los ocho estudios—, se retira; y el
corredor gana por escrito la obligación de producir `docs/validacion/compuertas.csv`, que el
CI le borraba y le exigía sin que el plan lo dijera en ninguna parte.

Dónde puede mudarse ahora:

1. **El censo y la fuente se pueden mover a la vez.** Con `fuente` cerrada hacen falta cuatro
   cambios coordinados —el valor, la `fuente` de la expectativa, la del resultado y la entrada
   en `fuentes` del manifiesto— para fabricarse un grupo. Sigue siendo posible; ningún
   artefacto del repositorio puede recontar la tabla de un artículo.
2. **Siete de los veinticinco grupos son de una sola fila** y ahí la uniformidad es inerte de
   nacimiento, entre ellos las dos únicas comparaciones de `necesidad` con `decidible = si` de
   E008 y E014. Ya no se pueden fabricar, pero los que había siguen ahí.
3. **`no_pasa` es ambiguo y así se publica.** El plan ya no puede decir si una compuerta caída
   acusa a su propia hipótesis o al motor.

### Octava pasada, 2026-08-12 (la décima mudanza, y quitar la clave de texto)

Tres cosas, y la primera vuelve a ser la misma de siempre.

1. **La décima mudanza: no hacía falta inventar una fuente, bastaba citar la tabla hermana.**
   La séptima pasada cerró el dominio de `fuente` para que nadie pudiera escribir
   «Tabla 9 (cobertura)», pero **nada ataba `fuente` a `modulo`**, así que una fila de
   `necesidad` de E025 podía mudarse a su Tabla 8 —dos decimales en vez de tres, misma escala,
   fuente perfectamente legítima— y quedar en un grupo internamente uniforme, con la tolerancia
   multiplicada por diez, el manifiesto sin tocar y cuatro líneas de diff.
   **El cierre quita en vez de añadir**: la clave del grupo pasa a ser `(id_estudio, modulo)`,
   que es un dominio cerrado de seis nombres, y con eso `"fuentes": [...]` **sobra y se
   elimina** del manifiesto. Agrupar por módulo es además más estricto —los grupos son la unión
   de los que había, luego hay menos singletons— y disuelve de paso dos problemas de la ronda
   anterior: la contradicción entre las filas de `ajuste` de E025 (`"Tabla 10 (solucion
   intermedia)"`) y el `fuentes[]` de su propio manifiesto, y el campo sin documentar que
   habría hecho abortar la Task 11 con los siete manifiestos restantes. `fuente` vuelve a ser
   lo que debía ser: el localizador que lee un humano, sin poder sobre nada.
2. **`exige()` casaba subcadenas y solo comprobaba presencia.** «2» es prefijo de «24», así que
   bajar el censo de 24 a 2 dejaba el documento público intacto y en verde —justo la mitigación
   que la pasada anterior había convertido «de decorativa en real»—, y un veredicto falso podía
   convivir con el verdadero. Ahora el patrón va **anclado** (al número le sigue un no-dígito o
   el fin de línea) y se compara **línea a línea**; y para cada estudio se **prohíbe** que
   aparezca cualquier veredicto distinto del que dan los datos.
   **(Superado: ese ancla y `prohibe()` se retiraron en la undécima pasada, y desde la
   duodécima hay una sola regla —`unico()`, apariciones y final de línea— para las cuatro
   familias. Este punto describe el diseño de la séptima, no el vigente.)**
3. **La ambigüedad de `no_pasa` era una promesa sin guardián**: escrita en seis sitios del plan
   y en ninguno del documento público. Un `stopifnot` de distancia, ya puesto.

Efecto colateral que no busqué: **M-L2 pasa de verde a roja.** El límite que esta rama
arrastraba desde la cuarta pasada —borrar resultado, expectativa y conteo a la vez— lo muerde
ahora la atadura del informe, porque el documento público sigue declarando el censo y el
recuento de `D-APP` viejos.

Dónde puede mudarse ahora:

1. **El censo sigue siendo editable si además se reescribe el informe**, que es lo que M-L2 ya
   no consigue con el documento intacto. Ningún artefacto del repositorio puede recontar la
   tabla de un artículo: ahí termina lo que el código sostiene.
2. **La uniformidad por módulo puede ser demasiado estricta con datos reales.** Si un estudio
   publica dos tablas del mismo módulo con precisiones distintas, la comprobación fallará con
   datos legítimos y habrá que decidir entre relajarla o partir el módulo. No lo he visto en
   los nueve estudios tal como el plan los describe, pero solo se sabrá al ejecutar.
3. **Una tabla cuyos valores publicados terminen todos en cero** los pierde de forma uniforme y
   pasa. Sin cambios.

### Novena pasada, 2026-08-12 (añadir la restricción que faltaba, no sustituir la que había)

Una sola línea, y el error de fondo es mío: la octava pasada **sustituyó** la clave del grupo
en vez de **añadir** la restricción que faltaba. Eso rompió una cosa y abrió otra.

1. **La clave nueva abortaba con datos legítimos.** La `calibracion` de E012 saca dos
   membresías del texto a tres decimales y la transcripción de la S2 a dos —está mandado en la
   Task 7—, así que agrupar por `(id_estudio, modulo)` deja `test-consolidacion.R` en rojo y
   las Tasks 11-13 no se pueden ejecutar. **La clave vuelve a `(id_estudio, fuente)`**, que es
   la tabla impresa.
2. **La undécima mudanza.** E008 publica su Tabla 7 a tres decimales y de ella salen
   `minimizacion` y `ajuste`: quitarle un decimal **solo a las filas de `ajuste`** dejaba ese
   grupo uniforme, multiplicaba su tolerancia por diez y subía el veredicto de E008 de «no
   reproducido» a «reproducido». La clave por fuente sí lo caza, porque la Tabla 7 sigue
   citada a tres decimales desde `minimizacion`.
3. **Y la pieza que de verdad faltaba**: `fuentes` vuelve al manifiesto **indexado por
   módulo**. Eso es lo que cierra el hallazgo original —una fila de `necesidad` no puede migrar
   a la `Tabla 8` porque esa tabla no está declarada para `necesidad`— sin tocar la clave del
   grupo. Y esta versión sí es cierta en los datos, a diferencia de «una sola fuente por
   módulo».

**Y una afirmación mía que era falsa, corregida por lo que se mide.** Escribí dos veces que los
grupos por módulo «son la unión de los que había, luego hay menos singletons». Eso exigiría que
`fuente` refine a `modulo`, y **las dos particiones se cruzan**: `E008 Tabla 7` →
`{minimizacion, ajuste}`, `E012 Tabla 3` → `{minimizacion, ajuste}` y `E015 Tabla 5` →
`{minimizacion, ajuste}`. Era la premisa que hacía parecer innecesaria la restricción que
quité, y la escribí sin medirla: exactamente el defecto que esta rama persigue.

Menor: `hay()` interpolaba su argumento dentro de un patrón de expresión regular. **Esta
retrospectiva afirmó en su día que el arreglo estaba puesto, y no lo estaba**: el guion que lo
aplicaba abortó antes de llegar a esa línea y no volví a comprobarlo contra el árbol. Se aplicó
de verdad en la novena pasada, con `\Q…\E` y `perl = TRUE`, y con los tres casos ausentes
midiendo `FALSE` donde antes daban `TRUE` o un error de compilación del patrón.

Dónde puede mudarse ahora:

1. **Los grupos de una sola fila siguen sin restringir nada.** Con la pertenencia por módulo ya
   no se pueden fabricar, pero los que existen de nacimiento siguen ahí.
2. **Una tabla cuyos valores publicados terminen todos en cero** los pierde de forma uniforme y
   pasa. Sin cambios desde la sexta pasada.
3. **`fuentes` es un dato del manifiesto**, así que ampliar la lista de un módulo —declarar la
   `Tabla 8` para `necesidad` y mudar la fila allí— es un cambio de una línea en la ficha de
   procedencia. Ningún artefacto del repositorio puede decir qué tablas publica un artículo,
   así que ese límite no se puede cerrar por código. La novena pasada **publicó `fuentes` en el
   informe** para que ampliar la lista obligara a cambiar el documento público; **la décima
   descubrió que esa exigencia no mordía**, porque comprobaba un valor de texto con el ancla
   numérica del censo y degradaba a prefijo: bastaba publicar el dominio ancho antes de
   ampliarlo. La comprobación contra el final de línea cierra **la forma prefijo**; la forma
   «publicar las dos líneas a la vez» seguía verde, y esa la cierra `unico()` en la undécima
   pasada exigiendo que cada clave aparezca **una sola vez**.

### Décima pasada, 2026-08-13 (auditar el DATO, no el circuito que lo protege)

Nueve pasadas endurecieron el circuito que impide **degradar** una celda de la selección
congelada. Ninguna comprobó que las celdas fueran **ciertas**. Y no lo eran: auditadas una a
una contra los artículos originales, **diez de las 44 estaban mal**, y la matriz baja a 34.

`mod_tabla_verdad` estaba en `si` en los **nueve** incluidos —el único módulo con pleno, que
es exactamente la forma que debería haber levantado la sospecha— y en **siete** de ellos
ninguna tabla del artículo lo sostiene. El patrón es siempre el mismo, y explica por qué
nueve evaluaciones independientes cometieron el mismo error: el artículo **describe** la
tabla de verdad al explicar el método, y publica **sólo la tabla de soluciones**, que son
configuraciones ya minimizadas con su consistencia y sus coberturas. Eso es `minimizacion` y
`ajuste`, y se contó dos veces. La variante de forma es E014, cuya Table 3 lleva el rótulo
«Truth table» sobre una matriz caso × condición sin casos, sin consistencia, sin PRI y sin
resultado: la celda descansaba en el **título**, no en el contenido.

Cayeron también tres celdas de `mod_robustez`. Dos eran prosa sin cifras —E008 varía la
consistencia de `0.8` a `0.85` y afirma que las configuraciones son idénticas; E009 varía PRI
y frecuencia y no publica nada—; la tercera, E025, es peor de leer: su Tabla 11 es **validez
predictiva** por partición muestral y el artículo dice que usó «identical cutoff points for
both sets of samples», que es la negación del criterio.

Quedan: `tabla_verdad` en **E012 y E015**; `robustez` en **E001, E012 y E026**. El reparto
completo —calibración 8, necesidad 8, tabla de verdad 2, minimización 4, ajuste 9, robustez
3— se publica en `docs/validacion/busqueda-ampliada.md` y lo genera desde el CSV
`validation/tests/test-seleccion-ampliada.R`, que también congela la matriz nueva en la firma
`6a72a81d…`.

Qué cambia en este plan, más allá de las cifras:

- **`SIN_EXPECTATIVA_PUBLICADA` queda vacía.** Sus dos entradas —`E025:tabla_verdad` y
  `E008:robustez`— eran el síntoma que la auditoría convirtió en diagnóstico: un módulo
  declarado del que se sabía que no publica nada comparable no necesita una excepción, es que
  la celda estaba mal.
- **Desaparece la aserción de la robustez de E009**, que era la única fila del plan capaz de
  acusar al motor por un barrido. Está dicho en la Task 4 y no se disimula.
- **Las 100 celdas de la Table 3 de E014 se quedan sin módulo**, y a dónde van —si a alguno—
  es una decisión que esta pasada **no toma**.
- **`E012:necesidad` queda declarada como el siguiente candidato a auditar**, y no se baja.
  Es un hallazgo de esta pasada: la celda está en `si` y **no tiene objeto publicado
  documentado en ninguna parte del dossier** —ni en la fila de E012 de
  `busqueda-ampliada.md`, ni en su `motivo`, ni en la Task 7 de este plan, que dice
  literalmente que «el artículo no publica una tabla de necesidad» y sostiene la celda sobre
  afirmaciones del texto—. Es la misma clase de celda que esta pasada condena, y sobrevivió
  porque `necesidad` no mostraba el patrón del pleno que delató a `tabla_verdad`. **No se
  apaga**: nadie la ha contrastado contra el artículo, y apagarla sin mirarlo sería el mismo
  error en la otra dirección. Queda nombrada aquí y en `docs/validacion/diccionario.md`.

**Y una asimetría de esta misma auditoría, dicha para que se pueda discutir.** La
enumeración por metadatos de DataCite —144 archivos, con el depósito bloqueado y **sin poder
abrir ninguno**— se usó como evidencia para **matar** `E001:tabla_verdad`, y esa misma base
no se aplicó a `E001:robustez`, que se mantiene. La diferencia es defendible y es esta: la
robustez de E001 no depende del depósito, porque el artículo entero **es** el barrido de
frecuencia, umbrales de inclusión y anclas, con sus ocho figuras; la tabla de verdad no está
ni en el artículo ni, hasta donde la enumeración alcanza, en el depósito. Pero la evidencia
negativa que sostiene la primera mitad es **más débil** que la del resto de los seis
estudios, donde sí se abrieron los suplementos, y por eso queda escrita.

Dónde puede mudarse ahora, con el criterio de siempre:

1. **Ningún artefacto del repositorio puede leer un artículo.** La firma congela la matriz que
   alguien escribió; que esa matriz diga la verdad lo sostiene una auditoría humana con
   localizador, y nada más. Esta pasada es la prueba de que el circuito puede estar perfecto
   sobre un dato falso.
2. **La forma de un pleno es una señal, y no hay quien la vigile.** Un módulo `si` en los
   nueve estudios volvió a ser el indicio, igual que en la segunda pasada lo fue una tabla
   copiada. No es automatizable, pero sí nombrable: **desconfiar de la columna sin variación**.
3. **`E015:calibracion` puede no tener expectativas.** La Task 9 no cita ninguna tabla de
   calibración —el artículo no publica sus anclas y la Tabla 1 se usa para aceptar la
   transcripción—, y con `SIN_EXPECTATIVA_PUBLICADA` vacía un censo `0` ahí abortaría. Es
   anterior a esta pasada y sigue sin resolver: se sabrá al escribir la Task 9.
