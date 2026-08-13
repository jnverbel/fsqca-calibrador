# Fuentes de la ronda 1

Fecha de ejecución: 2026-08-11. La ronda se ejecutó con las consultas fijadas
antes de observar resultados. `registro-busqueda.csv` conserva cada petición o
lote y `cribado-estudios.csv` conserva cada tarjeta, incluso cuando otro
repositorio describe el mismo estudio.

## Fuentes enumeradas

| Fuente | Petición y paginación | Respuesta verificable | Estado |
| --- | --- | ---: | --- |
| Zenodo API | Consulta predefinida con `size=100`; fallback público `size=25&page=1..2` | 31 (25 + 6) | Completa mediante fallback. La petición exacta devolvió HTTP 400 porque Zenodo limita a 25 una consulta no autenticada. |
| Harvard Dataverse API | `q=fsQCA&type=dataset&per_page=100&start=0` | 44 | Completa en B060: HTTP 200, `total_count=44`, `start=0` y 44 ítems. B039 conserva el intento anterior HTTP 504 sin atribuirle resultados. |
| OSF API nodes | `filter[title][icontains]=fsQCA&page[size]=100` | 6 | Completa: `links.meta.total=6`, `links.next=null`. |
| DataCite API | `query=fsQCA&resource-type-id=dataset&page[size]=100&page[number]=1..4` | 322 (100 + 100 + 100 + 22) | Completa: `meta.total=322`, último `links.next=null`. |
| Figshare API | `POST /v2/articles/search`, cuerpo `{"search_for":"fsQCA","limit":100,"offset":N}` para `N=0,100,...,1000` | 1.004 (diez lotes de 100 y uno de 4) | Completa: el lote corto en el offset máximo documentado cerró el conjunto. |

Las URL base y los parámetros completos constan en B036–B055. Figshare usa
POST, por lo que el cuerpo reproducible se registra en `consulta` y
`observaciones`, no se simula como query string. La documentación primaria
consultada para el límite de paginación fue
<https://docs.figshare.com/#searching-filtering-and-pagination>.

## Fuentes no enumeradas como universo

| Fuente | Impedimento observado | Registro |
| --- | --- | --- |
| Dataverse global | La Search API es por instalación. El proyecto oficial indica que las instalaciones deben buscarse individualmente y recomienda DataCite para descubrimiento transversal; el directorio global no es un endpoint federado de datasets. | B056, `enumeracion_completa=no`. |
| GESIS | La interfaz integrada acepta la consulta, pero no publicó para esta ejecución una exportación/API con total y cursor estables que permitiera cerrar el universo. | B057, rastreo, 0 resultados atribuidos. |
| UK Data Service | El catálogo interactivo no expuso una exportación/API estable del conjunto producido por esta consulta. | B058, rastreo, 0 resultados atribuidos. |
| ICPSR | La Metadata Export API existe, pero su guía exige obtener cuenta temporal de University of Michigan y solicitar credenciales. Sin esas credenciales no se atribuyó una enumeración pública. | B059, rastreo, 0 resultados atribuidos. |

Fuentes primarias de los límites: Search API de Dataverse
<https://guides.dataverse.org/en/latest/api/search.html>, directorio y guía de
búsqueda global <https://dataverse.org/installations>, FAQ de GESIS
<https://search.gesis.org/faq>, ayuda del UK Data Service
<https://ukdataservice.ac.uk/help/new-users/data-documentation/> y portal de la
API de ICPSR
<https://icpsr.github.io/metadata/icpsr_metadata_api/>.

## Cribado y deduplicación

La suma de las fuentes enumeradas es 1.407 tarjetas: 31 Zenodo, 44 Harvard, 6
OSF, 322 DataCite y 1.004 Figshare. Se conservaron 942 tarjetas como duplicados
y 455 se descartaron en metadatos. El identificador propio de cada tarjeta permanece en
`identificador_fuente`; los grupos comparten `id_estudio_canonico` por DOI de
publicación, depósito o componente de versión. Diez grupos avanzaron a texto
completo.

## Evaluaciones completas

### 10.1371/journal.pone.0326226 — Nivel B

Se inspeccionaron la publicación PLOS, S1 (algoritmo del índice), S2 (código R),
S3 (datos), las tablas de anclas y soluciones y la licencia CC BY 4.0. La
publicación fija anclas, `incl.cut=0.8`, PRI 0.6, `n.cut=1` y soluciones. Se
clasifica B porque el suplemento ejecutable cubre NCA,
no un `include` fsQCA que permita elevarlo al flujo A. **Auditoría de celdas
2026-08-13**: se retira de esta ficha «una prueba de robustez». La §4.4.4
«Robustness analysis» son dos frases sin ninguna cifra alternativa —varía la
consistencia de 0.8 a 0.85 y afirma que las configuraciones son idénticas al
subconjunto de los resultados originales—, y el artículo no publica tabla de
verdad: la Table 7 «Configurations analysis» son soluciones ya minimizadas.
`mod_tabla_verdad` y `mod_robustez` quedan en `no_evaluable`. Evidencia primaria:
<https://doi.org/10.1371/journal.pone.0326226>,
<https://doi.org/10.1371/journal.pone.0326226.s001>,
<https://doi.org/10.1371/journal.pone.0326226.s002> y
<https://doi.org/10.1371/journal.pone.0326226.s003>.

### 10.1371/journal.pone.0348315 — Nivel B modular

Se inspeccionaron publicación, escala, datos anonimizados de 38 columnas, datos
calibrados, código NCA, tablas de necesidad/soluciones y CC BY 4.0. La
publicación fija anclas percentiles 95/50/5, consistencia y PRI 0.8, frecuencia
3 y resultados. No declara la agregación exacta de los ítems ni las
expectativas `include`; por eso no es A y minimización queda `no_evaluable`.
Evidencia primaria: <https://doi.org/10.1371/journal.pone.0348315>,
<https://doi.org/10.1371/journal.pone.0348315.s002> y
<https://doi.org/10.1371/journal.pone.0348315.s004>.

### 10.1371/journal.pone.0329190 — excluido tras texto completo

La publicación y el ZIP S1 son CC BY 4.0. El ZIP fue abierto y contiene código
LDA, datos textuales y dos archivos de salida QCA; las propias salidas nombran
un CSV de entrada QCA que no está en el paquete. No se asignó Nivel B ni módulo
por esa ausencia. Evidencia primaria:
<https://doi.org/10.1371/journal.pone.0329190> y
<https://doi.org/10.1371/journal.pone.0329190.s001>.

### Reapertura sistemática de señales PLOS

Se revisaron los 32 grupos PLOS cuyas tarjetas mencionaban explícitamente S1
Data/Dataset, tabla de verdad, datos brutos, cuestionario o ítems. Siete grupos
mostraban conjuntamente datos y resultados/decisiones QCA y avanzaron a texto
completo: 10.1371/journal.pone.0259014, .0282617, .0300283, .0301031,
.0302210, .0305916 y .0308717. Los restantes presentaban una sola señal sin el
complemento material necesario en las tarjetas y quedaron en metadatos.

| DOI | Archivos y SHA-256 verificados | Decisión factual |
| --- | --- | --- |
| 10.1371/journal.pone.0259014 | S1 CSV `a2903dd5…3814a4` | Excluir: publicación/datos/calibración/`incl.cut`/intermedia sí; `n.cut` no declarado. |
| 10.1371/journal.pone.0282617 | S1 XLSX `ce4bdff6…e00f20`; S2 `60b8dd40…9152d`; S4 `caf06be5…33701`; S5 `080839eb…e662`; S6 `8fa25f41…81aa` | B: 80 países, reglas y variables exactas, anclas, `incl.cut=0.80`, `n.cut=1`, expectativas intermedias, necesidad, tablas, soluciones, ajuste y robustez 0.85/0.90. |
| 10.1371/journal.pone.0300283 | S1 `69a72303…60d8`; S2 `739ee86b…6f15`; S3 `89130e85…6d70` | Excluir: PLOS retractó la publicación el 23-10-2025 por dudas de validez/procedencia, revisión y autoría. |
| 10.1371/journal.pone.0301031 | S1 CSV `e8ee154f…9812` | B modular: diez áreas, variables/reglas, anclas directas e indirectas, `incl.cut=0.75`, `n.cut=1`, necesidad y ajuste; faltan expectativas `include` y robustez, por lo que minimización/robustez son `no_evaluable`. **Auditoría de celdas 2026-08-13**: también `tabla_verdad`, que decía «tabla» — la Table 3 lleva el rótulo «Truth table» sobre una matriz caso × condición, sin casos, consistencia, PRI ni resultado. |
| 10.1371/journal.pone.0302210 | S1 PDF `c505a456…b604` | B: matrices de 60 firmas para 2018/2021, variables exactas, 95/50/5, `incl.cut=0.85`, `n.cut=1`, solución más parsimoniosa, necesidad, tablas y ajuste; robustez no publicada. |
| 10.1371/journal.pone.0305916 | S1 `7426d9b4…f20`; S2 `a26a13cd…a08`; S3 CSV `4f8f3a8a…55ec`; S4 `bb57b4ba…f54` | Excluir: auditoría detallada abajo. |
| 10.1371/journal.pone.0308717 | S4 XLS `2d01b2a6…9e3e` | Excluir: las 6.284 filas no incluyen el monto necesario para seleccionar el 1%/64 casos ni los insumos del K-means. |

### Auditoría congelada de 10.1371/journal.pone.0305916

- Publicación persistente y licencia: sí, PLOS CC BY 4.0.
- Tipo y datos: cuestionario Likert de 21 ítems; S3 conserva 71 respuestas
  retenidas por ítem y membresías, pero no las 84 respuestas originales.
- Exclusión/recodificación/inversión: 13 respuestas se describen sólo como
  inválidas por “infidelity and missing information”; no hay regla operativa,
  código de ausentes, recodificación ni declaración verificable de ítems
  invertidos.
- Composición/agregación: S1 identifica cinco constructos y el artículo ordena
  promediar ítems. Design, Skill, Behaviour y Result coinciden en 71/71 filas;
  Reaction discrepa en 67/71 (caso 1: media R1–R4 `4.75`, columna `4.08`).
- Outcome/condiciones: outcome Effectiveness/Design; condiciones Reaction,
  Learning/Skill, Behaviour y Result, identificables en texto y S3.
- Calibración: `ETAPA(5,4.2,1.92)`, `RA(5,4.25,1.70)`,
  `LS(5,4,1.90)`, `BH(5,4,1.65)`, `RE(5,4,1.55)`.
- Suficiencia: `n.cut=1`, consistencia `>0.80`, solución intermedia y tablas
  comparables; `include`/expectativas direccionales no se publican.
- Decisión: `ninguno/excluir`. Elegir la columna Reaction en vez de la media,
  inventar las exclusiones o completar `include` serían decisiones
  retrospectivas; no se asignó ningún módulo.

No se ejecutó `fsqca-calibrador`, no se incorporaron archivos de terceros al
repositorio y no se excluyó ningún estudio por compatibilidad potencial con la
aplicación.
