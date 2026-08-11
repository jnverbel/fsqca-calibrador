# Fuentes de la ronda 1

Fecha de ejecución: 2026-08-11. La ronda se ejecutó con las consultas fijadas
antes de observar resultados. `registro-busqueda.csv` conserva cada petición o
lote y `cribado-estudios.csv` conserva cada tarjeta, incluso cuando otro
repositorio describe el mismo estudio.

## Fuentes enumeradas

| Fuente | Petición y paginación | Respuesta verificable | Estado |
| --- | --- | ---: | --- |
| Zenodo API | Consulta predefinida con `size=100`; fallback público `size=25&page=1..2` | 31 (25 + 6) | Completa mediante fallback. La petición exacta devolvió HTTP 400 porque Zenodo limita a 25 una consulta no autenticada. |
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
| Harvard Dataverse API | La consulta exacta con `per_page=100`, el fallback `per_page=25` y variantes de orden/mayúsculas respondieron HTTP 504. No se reutilizó el total histórico como si fuera una respuesta actual. | B039, `enumeracion_completa=no`, 0 revisados. |
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

La suma de las fuentes enumeradas es 1.363 tarjetas: 31 Zenodo, 6 OSF, 322
DataCite y 1.004 Figshare. Se conservaron 897 tarjetas como duplicados y 463 se
descartaron en metadatos. El identificador propio de cada tarjeta permanece en
`identificador_fuente`; los grupos comparten `id_estudio_canonico` por DOI de
publicación, depósito o componente de versión. Tres grupos avanzaron a texto
completo.

## Evaluaciones completas

### 10.1371/journal.pone.0326226 — Nivel B

Se inspeccionaron la publicación PLOS, S1 (algoritmo del índice), S2 (código R),
S3 (datos), las tablas de anclas y soluciones y la licencia CC BY 4.0. La
publicación fija anclas, `incl.cut=0.8`, PRI 0.6, `n.cut=1`, soluciones y una
prueba de robustez. Se clasifica B porque el suplemento ejecutable cubre NCA,
no un `include` fsQCA que permita elevarlo al flujo A. Evidencia primaria:
<https://doi.org/10.1371/journal.pone.0326226>,
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
<https://doi.org/10.1371/journal.pone.0348315.s003>.

### 10.1371/journal.pone.0329190 — excluido tras texto completo

La publicación y el ZIP S1 son CC BY 4.0. El ZIP fue abierto y contiene código
LDA, datos textuales y dos archivos de salida QCA; las propias salidas nombran
un CSV de entrada QCA que no está en el paquete. No se asignó Nivel B ni módulo
por esa ausencia. Evidencia primaria:
<https://doi.org/10.1371/journal.pone.0329190> y
<https://doi.org/10.1371/journal.pone.0329190.s001>.

No se ejecutó `fsqca-calibrador`, no se incorporaron archivos de terceros al
repositorio y no se excluyó ningún estudio por compatibilidad potencial con la
aplicación.
