# Búsqueda ampliada y validación en dos niveles: diseño

**Fecha:** 2026-08-11  
**Estado:** aprobado para planificación  
**Predecesor:** `2026-08-10-estado-arte-validacion-integral-design.md`

## 1. Propósito

Ampliar de manera reproducible la búsqueda de estudios publicados con datos y resultados
abiertos para determinar si es posible validar `fsqca-calibrador`. La ampliación no
rebajará los requisitos que dejaron solo un estudio elegible en el primer cribado. En su
lugar, separará dos afirmaciones de distinta fuerza:

1. **validación principal del flujo Likert**, que exige encuestas o constructos multiítem y
   cubre la promesa central de la aplicación; y
2. **validación secundaria de módulos fsQCA**, que admite otros tipos de datos y solo valida
   las etapas analíticas efectivamente reproducidas.

Los resultados de ambos niveles no se sumarán para fabricar una cifra global de estudios
"validados".

## 2. Preguntas

- ¿Existen al menos tres estudios publicados con datos Likert o constructos multiítem que
  permitan reproducir desde los datos brutos hasta una solución fsQCA?
- Si no existen tres, ¿qué etapas del motor pueden validarse con estudios reproducibles de
  otros tipos de datos?
- ¿Qué requisitos faltan con mayor frecuencia: datos, licencia, construcción de
  constructos, anclas, umbrales, código o resultados comparables?
- ¿Las discrepancias encontradas proceden de la aplicación, sus dependencias, el estudio o
  información insuficiente?

## 3. Niveles de evidencia

### Nivel A — Validación principal Likert/multiítem

Un estudio solo pertenece al Nivel A si cumple conjuntamente:

- publicación académica persistente;
- datos brutos públicos con licencia compatible con la replicación;
- encuesta Likert o constructos formados por varios ítems;
- reglas publicadas para exclusión de casos, recodificación e ítems invertidos;
- composición exacta y regla de agregación de cada constructo;
- resultado y condiciones identificables;
- anclas de calibración declaradas o producidas por un script oficial, sin ajuste
  retrospectivo contra las membresías publicadas;
- `incl.cut`, `n.cut`, `include` y tipo de solución declarados o ejecutables desde el código
  oficial;
- al menos una solución o tabla de parámetros publicada;
- archivos descargables y verificables mediante SHA-256.

Tres estudios completos reproducidos son el mínimo para afirmar validación externa en
varias replicaciones del flujo Likert. La afirmación se limitará a las etapas cubiertas por
los tres.

### Nivel B — Validación secundaria modular

El Nivel B conserva todos los requisitos anteriores salvo que permite datos continuos,
binarios, macrocomparativos o conjuntos ya calibrados, y no exige validación de medida ni
agregación multiítem. Cada estudio debe declarar qué módulos puede evaluar:

- calibración;
- necesidad;
- tabla de verdad;
- minimización y soluciones;
- parámetros de ajuste;
- robustez.

Un estudio de Nivel B nunca cuenta como validación del flujo Likert. Puede respaldar, por
ejemplo, "la minimización fue reproducida en tres estudios", pero no "la aplicación fue
validada integralmente".

## 4. Fuentes y cobertura ampliada

La búsqueda partirá de los 57 registros ya enumerados y ampliará la identificación a:

- todas las páginas de los 31 resultados de Zenodo y los 44 de Harvard Dataverse
  identificados en la primera fase;
- DataCite;
- Figshare;
- OSF mediante su API documentada;
- la red global de Dataverse, sin limitarse a Harvard;
- GESIS;
- UK Data Service;
- ICPSR;
- repositorios institucionales enlazados por publicaciones;
- suplementos de editor localizados por DOI;
- repositorios de código citados por artículos;
- rastreo hacia atrás y hacia delante de guías metodológicas y estudios elegibles.

Las consultas combinarán, como mínimo, variantes en inglés, español y portugués de
`QCA`, `fsQCA`, `fuzzy-set`, `conjuntos difusos`, `conjuntos fuzzy`, `replication`,
`replicación`, `replicação`, `supplementary data`, `datos suplementarios`, `survey`,
`encuesta`, `Likert`, `calibration`, `calibración`, `calibração` y `truth table`.

No se usarán solo primeras páginas cuando la fuente proporcione paginación o exportación
enumerable. Cuando una fuente no permita enumeración estable, se registrará la limitación
y sus resultados se tratarán como rastreo, no como universo exhaustivo.

## 5. Identificación, deduplicación y cribado

Cada registro identificado se guardará en una tabla estructurada con:

- identificador de consulta y posición o página;
- DOI, identificador de depósito y URL persistente;
- título, autores, año e idioma;
- fuente de descubrimiento;
- nivel candidato `A`, `B` o `ninguno`;
- decisión de metadatos;
- decisión de texto completo;
- motivo cerrado de exclusión;
- identificador canónico para deduplicación.

La deduplicación usará primero DOI, después identificador del depósito y finalmente título
normalizado más primer autor y año. Los componentes de un mismo paquete de replicación se
agruparán bajo una unidad canónica sin perder sus archivos individuales.

El cribado tendrá dos etapas:

1. **metadatos:** publicación vinculable y posibilidad material de datos, decisiones y
   resultados;
2. **texto completo y archivos:** verificación de todos los requisitos de Nivel A o de los
   módulos concretos de Nivel B.

Ningún estudio se excluirá por producir resultados incompatibles con la aplicación.

## 6. Regla de saturación

La búsqueda terminará solamente cuando ocurra una de estas condiciones:

1. se encuentren al menos tres estudios de Nivel A y suficiente evidencia de Nivel B para
   cubrir los módulos restantes; o
2. se completen dos rondas consecutivas de fuentes nuevas sin identificar un estudio
   elegible adicional de Nivel A ni un módulo nuevo cubierto en Nivel B.

Una ronda es un conjunto cerrado de fuentes y consultas definido antes de ejecutarlo. La
segunda ronda debe incorporar al menos rastreo de citas y repositorios institucionales, no
repetir las mismas consultas con cambios cosméticos. La saturación se calculará desde el
registro, no se declarará narrativamente de memoria.

## 7. Congelación antes de replicar

La selección y clasificación A/B se guardarán en un commit antes de ejecutar
`fsqca-calibrador` sobre cualquier estudio nuevo. Para cada estudio incluido se congelará:

- fuente, licencia y hashes;
- unidad de análisis y exclusiones;
- construcción y agregación de variables;
- anclas e `idm`;
- `incl.cut`, `n.cut`, `include` y tipos de solución;
- resultados esperados y ubicación exacta de la fuente;
- precisión publicada y tolerancia correspondiente;
- módulos evaluables.

Las tolerancias siguen la especificación anterior: `1e-9` para precisión completa,
`0.5 * 10^(-d)` para `d` decimales publicados e igualdad exacta para conteos y soluciones
normalizadas. No se modificarán después de observar resultados.

## 8. Replicación

Cada estudio tendrá cuatro ejecuciones o artefactos separados:

1. preparación transparente desde datos originales;
2. referencia mediante script oficial o paquetes citados;
3. ejecución mediante la API pública de `calibraqca`;
4. comparación estructurada de esperado y observado.

Las diferencias usarán los códigos `D-OK`, `D-FMT`, `D-APP`, `D-DEP`, `D-EST` y
`D-AMB`. Los niveles A y B compartirán comparadores, pero tendrán informes y denominadores
separados.

## 9. Criterios de resultado

### Flujo principal

- **Validado en varias replicaciones:** al menos tres estudios de Nivel A reproducidos sin
  `D-APP` en las etapas comunes declaradas.
- **Evidencia parcial:** uno o dos estudios de Nivel A reproducidos, o tres con etapas
  obligatorias no evaluables.
- **No validado:** cualquier `D-APP` que afecte datos agregados, membresías, filas de tabla
  de verdad, soluciones o ajuste.
- **Evidencia insuficiente:** ningún estudio o menos de tres sin que proceda afirmar varias
  replicaciones.

### Módulos secundarios

Cada módulo se informará como número de estudios `reproducido / evaluable`, por tipo de
datos. Un módulo con `D-APP` no puede clasificarse como reproducido aunque otros módulos del
mismo estudio coincidan.

## 10. Entregables

- ampliación de `registro-busqueda.csv` y `cribado-estudios.csv`;
- diccionario y pruebas actualizados para niveles, rondas y saturación;
- `docs/validacion/busqueda-ampliada.md`;
- selección congelada con estudios A y B;
- plan exacto de replicación escrito después de conocer los estudios;
- manifiestos, prerregistros, adaptadores, resultados y pruebas por estudio;
- `docs/validacion-integral.md` con niveles separados;
- actualización de README, CITATION y especificación conforme al resultado;
- CI que ejecute los controles de evidencia y las replicaciones permitidas.

Si la búsqueda ampliada vuelve a producir menos de tres estudios de Nivel A, el documento
debe decirlo sin completar el cupo con Nivel B. Si aparecen estudios de Nivel B, se
ejecutarán para validar módulos, no para cambiar la etiqueta del Nivel A.

## 11. Deuda documental previa

Antes de ampliar los datos se actualizará el plan anterior para que sus ejemplos de
encabezados y pruebas incluyan las columnas `alcance` y `licencia_compatible` ya aplicadas
por los artefactos actuales. Esta corrección no cambia resultados; elimina una contradicción
documental detectada en la revisión final.

## 12. Condición de cierre

El trabajo termina cuando:

- las fuentes enumerables han sido recorridas completamente;
- dos rondas satisfacen la regla de saturación o se alcanza el mínimo de Nivel A;
- toda inclusión y exclusión es reproducible desde el registro;
- la selección queda congelada antes de ejecutar la app;
- las replicaciones posibles se ejecutan sin alterar criterios;
- los resultados de Nivel A y Nivel B se reportan por separado;
- la documentación pública no excede la evidencia.
