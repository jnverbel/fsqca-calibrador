# Estado del arte y validación integral: diseño

**Fecha:** 2026-08-10  
**Estado:** aprobado para planificación  
**Objeto:** `fsqca-calibrador`

## 1. Propósito

Determinar con evidencia externa si `fsqca-calibrador` aporta una capacidad que no esté
ya cubierta por herramientas existentes y si reproduce correctamente flujos fsQCA
publicados. El trabajo no parte de que la aplicación sea novedosa ni correcta. Puede
concluir que su contribución es solo instrumental, que duplica herramientas existentes o
que presenta discrepancias metodológicas.

El resultado tendrá dos componentes inseparables:

1. una revisión reproducible del estado del arte de herramientas y flujos para fsQCA con
   datos de encuesta o constructos agregados; y
2. una validación integral contra entre tres y cinco estudios publicados que permitan
   recalcular los resultados a partir de datos brutos públicos.

## 2. Preguntas de investigación

### Estado del arte

- ¿Qué aplicaciones, paquetes o flujos reproducibles integran preparación de datos,
  validación de medida, agregación, calibración, QCA, robustez y reporte?
- ¿Qué parte concreta del flujo de `fsqca-calibrador` no está cubierta por esas
  alternativas?
- ¿La obligación de justificar anclas y conservar la decisión en el informe es una
  capacidad original, una integración original de capacidades conocidas o una práctica ya
  implementada?
- ¿Qué evidencia existe sobre la utilidad, adopción, mantenimiento y validación de cada
  alternativa?

### Validación

- ¿Reproduce la aplicación los conjuntos calibrados publicados o recalculables?
- ¿Reproduce los análisis de necesidad, tablas de verdad, soluciones y parámetros de
  ajuste?
- ¿Las diferencias se deben al motor, a versiones de dependencias, a decisiones no
  documentadas por el estudio o a errores del trabajo original?
- ¿Qué partes del flujo no pueden validarse con evidencia publicada?

## 3. Alcance y unidad de comparación

La revisión cubrirá software de escritorio, aplicaciones web, paquetes de R y flujos
documentados que ejecuten QCA o preparen datos de encuesta para QCA. La fecha de corte de
la búsqueda será 2026-08-10. Se consultarán, como mínimo, Crossref, OpenAlex, Google
Scholar mediante resultados indexados accesibles, CRAN, repositorios oficiales de
software y sitios de los autores. Cada afirmación factual inestable se respaldará con una
fuente primaria cuando exista.

No se evaluará como novedad científica una mera diferencia de idioma, interfaz o
empaquetado. Esas diferencias se clasificarán como accesibilidad o integración
instrumental. Una contribución metodológica exigiría una regla, estimador, protocolo o
resultado teórico nuevo y validado; el proyecto actualmente no reclama ninguno.

## 4. Protocolo de búsqueda del estado del arte

Antes de seleccionar resultados se registrarán:

- bases y buscadores consultados;
- fecha y cadena exacta de cada búsqueda;
- número de resultados revisados;
- criterios de inclusión y exclusión;
- motivo de exclusión en texto completo;
- versión y fecha de consulta de cada herramienta.

Las cadenas combinarán variantes de `fsQCA`, `fuzzy-set qualitative comparative
analysis`, `calibration`, `Likert`, `survey`, `reliability`, `validity`, `robustness`,
`workflow`, `software`, `Shiny`, `R package` y `reproducible report`. Se hará rastreo hacia
atrás y hacia delante de las revisiones y guías metodológicas centrales.

### Inclusión

Se incluirá una herramienta o flujo si satisface al menos uno de estos criterios:

- ejecuta calibración o QCA;
- prepara constructos de encuesta para QCA;
- implementa pruebas de robustez para QCA;
- genera un registro o informe reproducible de decisiones de calibración.

### Exclusión

Se excluirá:

- contenido puramente divulgativo sin herramienta o procedimiento ejecutable;
- software que usa "calibración" con un significado ajeno a conjuntos difusos;
- copias o interfaces sin diferencias funcionales respecto de su proyecto de origen;
- afirmaciones comerciales sin documentación comprobable.

### Matriz comparativa

Cada alternativa se codificará, como mínimo, por:

- licencia, disponibilidad y mantenimiento;
- interfaz, idioma y requisitos técnicos;
- validación de medida y agregación;
- calibración y registro de justificación de anclas;
- necesidad, suficiencia, minimización y NCA;
- robustez de anclas y umbrales;
- manejo de casos y advertencias;
- exportación reproducible y trazabilidad;
- validación publicada, adopción y limitaciones.

La conclusión distinguirá expresamente entre novedad metodológica, integración de
software, accesibilidad y ausencia de evidencia.

## 5. Selección de estudios para validación

Se seleccionarán entre tres y cinco estudios, sin condicionar la selección a que la
aplicación reproduzca sus resultados.

### Requisitos obligatorios

Cada estudio debe tener:

- publicación académica identificable mediante DOI u otro registro persistente;
- datos brutos públicos con licencia o condiciones que permitan su uso para replicación;
- resultado y condiciones identificables;
- anclas de calibración declaradas o derivables sin decisión retrospectiva;
- umbrales de consistencia y frecuencia declarados o contenidos en un script público;
- al menos una solución o tabla de parámetros publicada contra la cual comparar.

### Diversidad buscada

El conjunto final debe contener, cuando la evidencia disponible lo permita:

- al menos dos equipos de autores;
- al menos dos dominios sustantivos;
- al menos un estudio con constructos multiítem de encuesta;
- al menos un estudio de referencia metodológica o con script oficial de replicación;
- variación en el número de condiciones y el tamaño muestral.

Si menos de tres estudios satisfacen todos los requisitos, la validación no se completará
con casos débiles. Se informará que la evidencia disponible es insuficiente y se conservará
el registro de exclusiones.

## 6. Prerregistro interno de resultados y tolerancias

Para cada estudio se creará una ficha inmutable antes de ejecutar la aplicación. La ficha
contendrá:

- referencia y versión de los datos;
- hash SHA-256 del archivo original;
- unidad de análisis y reglas de exclusión;
- construcción exacta de cada constructo;
- anclas, `idm`, umbrales, `include` y tipo de solución;
- valores esperados transcritos de la publicación o producidos por su script oficial;
- tolerancia por resultado;
- campos que el artículo no permite reconstruir.

Las tolerancias se fijarán según la precisión publicada:

- membresías o parámetros disponibles con precisión completa: tolerancia absoluta
  `1e-9`;
- valores publicados con `d` decimales: tolerancia absoluta máxima de
  `0.5 * 10^(-d)`;
- conteos, configuraciones y presencia de términos: igualdad exacta tras normalizar solo
  notación y orden;
- resultados extraídos de una figura: no se usarán como prueba numérica de aprobación.

No se modificará una tolerancia después de observar el resultado. Cualquier corrección a
una ficha quedará registrada con fecha, causa y diferencia textual.

## 7. Flujo de replicación por estudio

Cada replicación tendrá un directorio independiente y cuatro capas:

1. **Fuente:** enlace, metadatos, licencia, hash y archivo original sin modificar.
2. **Adaptación:** script explícito que transforma nombres y formatos sin ejecutar
   decisiones analíticas ocultas.
3. **Referencia:** script oficial del estudio o reproducción directa mediante las
   funciones de los paquetes citados.
4. **Aplicación:** ejecución de las funciones públicas de `calibraqca` con las mismas
   decisiones.

Se compararán, cuando el estudio los permita:

- casos incluidos y datos agregados;
- membresías calibradas;
- consistencia y cobertura de necesidad;
- filas, frecuencias, consistencia y PRI de la tabla de verdad;
- soluciones compleja, parsimoniosa e intermedia;
- consistencia, cobertura bruta, cobertura única y cobertura de la solución;
- rangos o escenarios de robustez.

Los datos originales no se redistribuirán cuando su licencia no lo permita. En ese caso se
versionará un manifiesto de descarga y verificación, no el archivo.

## 8. Clasificación de discrepancias

Toda diferencia se asignará a una de estas categorías con evidencia:

- **D-APP:** defecto o decisión no documentada de `fsqca-calibrador`;
- **D-DEP:** diferencia causada por versión o comportamiento de una dependencia;
- **D-EST:** inconsistencia entre datos, texto, tablas o script del estudio;
- **D-AMB:** información insuficiente para decidir;
- **D-FMT:** diferencia exclusiva de presentación sin efecto numérico;
- **D-OK:** equivalencia dentro de la tolerancia prerregistrada.

Una discrepancia `D-AMB` no contará como aprobación. Una discrepancia `D-EST` tampoco se
usará para afirmar que la aplicación es correcta: solo indicará que el estudio no sirve
para resolver esa comparación.

## 9. Criterios de evaluación

No habrá una puntuación global que oculte fallos. Se informará el resultado por etapa y
estudio.

- **Reproducido:** todos los resultados evaluables cumplen su tolerancia y no hay
  discrepancias `D-APP`.
- **Reproducción parcial:** existe al menos un resultado no evaluable o `D-AMB`, pero
  ningún resultado evaluable presenta `D-APP`.
- **No reproducido:** existe al menos una discrepancia `D-APP` que afecta membresías,
  selección de filas, solución o parámetros de ajuste.

La aplicación solo podrá describirse como validada externamente en varias replicaciones si
al menos tres estudios completos quedan en la categoría **Reproducido**. Incluso entonces,
la afirmación se limitará a las etapas y tipos de datos efectivamente cubiertos.

## 10. Hallazgos sobre SetMethods

El informe distinguirá tres estados:

- **detectado:** existe un ejemplo reproducible y una explicación técnica;
- **reportado:** el reporte fue enviado a la mantenedora y se conserva evidencia local de
  fecha, canal y contenido;
- **confirmado/corregido:** existe respuesta verificable de la mantenedora, issue público,
  cambio de código o nueva versión.

El usuario informa que el defecto ya fue reportado. Se usará por ahora el estado
**reportado**. No se identificará a una persona ni se publicará correspondencia privada
sin autorización; bastará una constancia factual no sensible.

## 11. Entregables

- `docs/estado-del-arte.md`: método, diagrama de selección, matriz de herramientas,
  resultados y conclusión crítica.
- `docs/validacion-integral.md`: protocolo, estudios incluidos, resultados por etapa,
  discrepancias y límites.
- `docs/validacion/registro-busqueda.csv`: búsquedas y resultados examinados.
- `docs/validacion/estudios.csv`: inclusiones, exclusiones y motivos.
- `docs/validacion/herramientas.csv`: matriz comparativa auditable.
- `validation/`: manifiestos, fichas prerregistradas, adaptadores y resultados derivados
  permitidos.
- pruebas automatizadas de regresión para cada estudio reproducible;
- actualización de `README.md`, `README.es.md` y `CITATION.cff` para que las afirmaciones
  coincidan exactamente con la evidencia obtenida.

Los documentos separarán hechos, inferencias y ausencia de evidencia. Toda conclusión
negativa quedará incluida; no se retirará un estudio por producir un fallo de la
aplicación.

## 12. Verificación y reproducibilidad

- Todos los scripts correrán desde una sesión limpia con las dependencias fijadas por
  `renv.lock`.
- Cada archivo externo tendrá URL de origen, fecha de acceso, licencia y SHA-256.
- Las tablas de los documentos se generarán desde archivos estructurados, no mediante
  transcripción manual duplicada.
- Las pruebas fallarán ante diferencias fuera de tolerancia; no convertirán fallos en
  advertencias.
- Se ejecutará la suite del motor y las replicaciones en una sesión limpia antes de emitir
  cualquier afirmación de éxito.
- Si una dependencia o fuente deja de estar disponible, el informe conservará el hash y
  marcará la replicación como no ejecutable, no como aprobada.

## 13. Fuera de alcance

- demostrar causalidad sustantiva de los estudios replicados;
- corregir silenciosamente errores de publicaciones externas;
- introducir un nuevo método de calibración o robustez;
- medir adopción comunitaria mediante estrellas o descargas como sustituto de utilidad;
- afirmar exhaustividad mundial de la revisión;
- publicar correspondencia privada con la mantenedora de `SetMethods`.

## 14. Condición de cierre

El trabajo termina cuando la búsqueda y sus exclusiones son auditables, entre tres y cinco
estudios fuertes han sido seleccionados o se ha demostrado que no existen tres que cumplan
los requisitos, todas las comparaciones posibles han sido ejecutadas, las discrepancias
han sido clasificadas y la documentación pública del proyecto refleja sin exageración el
resultado obtenido.
