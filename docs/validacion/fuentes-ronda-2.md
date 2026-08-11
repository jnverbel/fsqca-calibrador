# Fuentes de la ronda 2

Fecha de ejecución: 2026-08-11. Las familias B061–B068 se registraron antes
de cada petición o seguimiento textual. No se ejecutó `fsqca-calibrador` ni se
versionaron archivos de terceros; publicaciones y suplementos se inspeccionaron
en almacenamiento temporal.

## Consultas y fuentes primarias

| Registro | Fuente | Revisados / universo | Alcance verificable |
| --- | --- | ---: | --- |
| B061 | OpenAlex API | 96 / 238 | Se resolvieron los DOI E001–E017 y se conservaron hasta diez citas hacia delante por semilla, ordenadas por citas. |
| B062 | OpenAlex API | 70 / 502 | Diez referencias hacia atrás de E001, E008, E009, E012, E014, E015 y la guía de Schneider y Wagemann. |
| B063 | Crossref, publicaciones y suplementos | 17 / 17 | Reinspección exacta de publicación, enlaces, licencia y disponibilidad de E001–E017. |
| B064 | DataCite API | 1 / 1 | Diecisiete búsquedas DOI exactas; sólo respondió el depósito Harvard 10.7910/DVN/23637, ya vinculado a E005. |
| B065 | OpenAlex, consulta española | 0 / 0 | Respuesta HTTP 200 cerrada. |
| B066 | OpenAlex, consulta portuguesa | 0 / 0 | Respuesta HTTP 200 cerrada. |
| B067 | OpenAlex, consulta inglesa | 25 / 321 | Primer lote de 25 congelado antes de ejecutar. |
| B068 | Publicaciones OA oficiales | 8 / 8 | Seguimiento a texto completo de las señales materiales surgidas en B061/B067. |

OpenAlex devolvió 96 tarjetas de citas y 70 de referencias; se conservaron las
repeticiones entre semillas y contra rondas anteriores. DataCite confirmó
`10.7910/DVN/23637` como suplemento de `10.1177/0049124114532446`. Crossref
expuso enlaces y licencias de los 17 DOI semilla, pero ningún artefacto nuevo
alteró sus decisiones congeladas.

## Texto completo y artefactos

`10.1371/journal.pone.0271960` ya tenía grupo principal en R1. La publicación
declara que los microdatos empresariales no pueden compartirse públicamente y
requieren aprobación de las empresas y acuerdo de acceso; la reapertura B068
queda visible como duplicado, sin crear otro estudio canónico.

Siete canónicos nuevos se evaluaron en E018–E024:

- E018, `10.1371/journal.pone.0311543`: S1 DOCX y S2 XLSX se abrieron; SHA-256
  `153a58fd…13d8` y `e88d5797…6b67d`. La publicación usa GMM, no fsQCA.
- E019, `10.1371/journal.pone.0316388`: S1 XLSX, SHA-256
  `9cb963ce…73ef`, contiene 1.566 filas; el artículo usa FE/RE/GMM, no fsQCA.
- E020, `10.1371/journal.pone.0323668`: publicación y S1/S2 documentan
  DID/PSM-DID; no hay resultado configuracional.
- E021, `10.3390/joitmc6030076`: no se hallaron microdatos o paquete de
  replicación y Crossref registra la versión actual como CC BY-NC-ND 4.0. El
  PDF oficial respondió HTTP 403; no se infirió contenido ausente.
- E022, `10.3390/buildings12091349`: 244 cuestionarios Likert, ítems, anclas
  95/50/5, `n.cut=5` y soluciones publicados; los datos sólo se ofrecen por
  solicitud al autor.
- E023, `10.3389/fpsyg.2021.733319`: agrega 1.231 cuestionarios a 30
  provincias y publica anclas, `n.cut=1`, necesidad, soluciones y robustez,
  pero no la matriz de casos pre-calibración ni un archivo descargable.
- E024, `10.1057/s41599-025-05551-y`: anclas, `n.cut=1`, resultados y
  robustez están publicados; la declaración primaria limita los datos a
  solicitud al autor.

La ausencia de datos públicos en E022–E024 no se sustituyó con tablas ni con
supuestos. E018–E020 no se excluyeron por compatibilidad con la aplicación,
sino porque sus textos no contienen un análisis fsQCA comparable.

## Conteo, decisión y saturación

La ronda conserva 217 filas: 176 descartes de metadatos, 34 duplicados y siete
evaluaciones completas. E018–E024 quedaron excluidos; no hay A ni B nuevos.
Como los seis módulos ya estaban cubiertos al cerrar R1, `modulos_nuevos` es
`ninguno`. La regla calculada da `0 A & ningún módulo nuevo`, por lo que R2 es
saturada. Al seguir habiendo 0 A acumulados, se abrió una ronda 3 genuinamente
nueva para exigir dos rondas saturadas consecutivas.
