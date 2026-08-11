# Informe de Task 3: ronda 1 en fuentes enumerables

## Estado y alcance

Ejecución realizada el 2026-08-11 en el worktree
`estado-arte-validacion`. Se fijaron las nueve fuentes y consultas del brief,
se recorrió toda paginación pública cerrable y se mantuvieron todos los
resultados/duplicados. No se ejecutó `fsqca-calibrador` ni se versionaron datos
de terceros.

## Fuentes y paginación

- Zenodo: la petición exacta `size=100` devolvió HTTP 400 (máximo público 25).
  El fallback semánticamente idéntico recorrió páginas 1 y 2: 25 + 6 = 31.
- Harvard Dataverse: HTTP 504 para la consulta exacta, `per_page=25` y
  variantes de orden/mayúsculas. Se registraron 0 revisados, `no`, sin inventar
  el total desde la ronda histórica.
- OSF nodes: HTTP 200, total 6, una página, `next=null`.
- DataCite: total 322, cuatro páginas 100 + 100 + 100 + 22, `next=null`.
- Figshare: POST reproducible con offsets 0–1000; diez lotes de 100 y uno de 4,
  total enumerado 1.004.
- Dataverse global: no existe Search API federada de todas las instalaciones;
  la documentación oficial indica búsqueda por instalación/DataCite.
- GESIS y UK Data Service: interfaces de rastreo sin exportación/API estable
  para cerrar el conjunto de la consulta.
- ICPSR: su Metadata Export API exige cuenta temporal U-M y credenciales
  solicitadas; sin ellas no fue enumerable de manera pública.

Las URL, parámetros, cuerpos POST, fechas, lotes y bloqueos están en B036–B059
y se explican en `docs/validacion/fuentes-ronda-1.md`.

## Decisiones y conteos

- 1.363 filas de cribado de ronda 1 = 31 Zenodo + 6 OSF + 322 DataCite +
  1.004 Figshare.
- 897 duplicados conservados, 463 descartes de metadatos y 3 evaluaciones
  completas.
- E008 (10.1371/journal.pone.0326226): incluir Nivel B.
- E009 (10.1371/journal.pone.0348315): incluir Nivel B modular.
- E010 (10.1371/journal.pone.0329190): excluir tras comprobar que el ZIP no
  contiene el archivo de entrada QCA que citan sus salidas.
- Ronda 1: 0 A, 2 B, módulos nuevos
  `calibracion|necesidad|tabla_verdad|minimizacion|ajuste|robustez`, no
  saturada.

## Archivos

Modificados: `registro-busqueda.csv`, `cribado-estudios.csv`, `estudios.csv`,
`rondas-busqueda.csv`, `evidencia-insuficiente.md`,
`exclusiones-estudios.md`, `validation/tests/test-busqueda-ampliada.R`,
`validation/tests/test-esquemas.R`, `validation/tests/test-estado-arte.R` y
`validation/tests/test-seleccion-estudios.R`. Creado
`docs/validacion/fuentes-ronda-1.md`.

Las correcciones cruzadas eliminan dos supuestos válidos sólo antes de ampliar
el corpus: que existía exactamente un duplicado y que el estado del arte
histórico debía sumar todas las rondas futuras. `test-estado-arte.R` deriva
ahora los conteos publicados exclusivamente de `ronda == 0` y prueba mediante
una fila sintética que una ronda posterior no los altera. La rama de evidencia
insuficiente se basa en estudios Nivel A: los tres Nivel B acumulados no se
presentan como tres replicaciones integrales.

## Pruebas

Ejecución final del 2026-08-11, todas con estado 0:

```text
for f in validation/tests/*.R; do Rscript --vanilla "$f" || exit 1; done
  test-busqueda-ampliada.R: estado 0
  test-esquemas.R: estado 0
  test-estado-arte.R: estado 0
  test-seleccion-estudios.R: seleccion valida: 10 examinados; 3 incluidos;
    7 excluidos; 1420 registros identificados; mutaciones rechazadas

Rscript --vanilla validation/tests/test-esquemas.R: estado 0
Rscript --vanilla validation/tests/test-busqueda-ampliada.R: estado 0
git diff --check: estado 0, sin salida
```

## Autoauditoría final

- B036–B059 son 24 filas de registro para ronda 1 y contienen las nueve fuentes
  exigidas; `sum(resultados_revisados)=1363`.
- Hay exactamente 1.363 filas de cribado con `ronda=1`: 897 duplicados, 463
  descartes y 3 evaluaciones completas; la suma coincide con búsquedas.
- E008–E010 comparten exactamente los canónicos de sus filas de evaluación
  completa. Hay 0 IDs de fila repetidos, 0 DOI/canónicos incoherentes y 0
  grupos repetidos con una cantidad de principales distinta de uno.
- `rondas-busqueda.csv` declara 1.363 registros nuevos, 0 A, 2 B y los seis
  módulos sólo después de las evaluaciones completas de E008/E009.
- El acumulado conserva la frontera histórica: ronda 0 no cambia; las pruebas
  de su publicación se calculan sólo sobre `ronda == 0`.
- Los CSV son válidos para las cuatro pruebas R; no hay archivos descargados de
  terceros ni ejecución de la aplicación en el repositorio.
