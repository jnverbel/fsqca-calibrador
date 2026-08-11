# Fuentes de la ronda 3

Fecha de ejecución: 2026-08-11. La ronda se congeló después de R2, que ya
era saturada, como una búsqueda distinta de la ronda de citas: un repositorio
institucional y suplementos de editor. No se ejecutó `fsqca-calibrador` ni se
versionaron materiales de terceros; los suplementos se descargaron sólo a
almacenamiento temporal para inspección.

## Consultas y fuentes primarias

| Registro | Fuente | Revisados / universo | Alcance verificable |
| --- | --- | ---: | --- |
| B069 | Qualitative Data Repository (Syracuse University), API Dataverse | 0 / 0 | `q=fsQCA&type=dataset&per_page=100` devolvió `total_count=0`. |
| B070 | PLOS Search API | 4 / 4 | Cuatro señales de suplementos de datos que quedaron como metadatos en R1: `10.1371/journal.pone.0291870`, `10.1371/journal.pone.0315249`, `10.1371/journal.pone.0320723` y `10.1371/journal.pone.0325933`. |
| B071 | PLOS One, artículo y suplemento oficiales | 4 / 4 | Texto completo, declaración de disponibilidad y S1 de los cuatro DOI de B070. |

La tercera ronda no reutiliza el rastreo bibliométrico de R2: consulta el
catálogo institucional de QDR y después abre directamente las publicaciones y
suplementos editoriales. Las tarjetas de B070 permanecen visibles como
duplicados del mismo canónico reabierto materialmente en B071.

## Evaluación material

- E025 (`10.1371/journal.pone.0291870`): el CSV S1 tiene 225 respuestas de
  ítems. El artículo publica agregación, anclas 5/3.5/1, frecuencia 3,
  consistencia 0.80, PRI 0.75, necesidad, soluciones, cobertura y validación
  predictiva. Es B modular: falta código y expectativas `include`.
- E026 (`10.1371/journal.pone.0315249`): el ZIP S1 contiene 459 casos con
  variables crudas y calibradas. Publica anclas 85/50/15, frecuencia 4,
  consistencia 0.80, PRI 0.60, necesidad, soluciones, cobertura y robustez.
  Es B modular por falta de código y expectativas `include`.
- E027 (`10.1371/journal.pone.0320723`): el CSV S1 contiene 318 respuestas de
  ítems. El artículo declara promedios, anclas 4/3/2, frecuencia 3,
  consistencia 0.80, necesidad, soluciones y cobertura. Es B modular; no hay
  código, expectativas `include` ni robustez fsQCA reproducible.
- E028 (`10.1371/journal.pone.0325933`): S1 es un cuestionario DOCX, no las
  389 respuestas. Se excluye por no poder reconstruir constructos ni
  calibración; no se infirió el contenido de una matriz ausente.

## Saturación

R3 tiene 8 tarjetas (4 duplicados y 4 evaluaciones completas), 0 Nivel A y 3
Nivel B. Sus módulos verificables ya estaban en la cobertura acumulada de R1,
por lo que `modulos_nuevos=ninguno` y R3 es saturada. R2 y R3 son dos rondas
consecutivas saturadas; como el total de A sigue siendo menor que tres, esta
pareja satisface la regla de cierre alternativa.
