# Validación externa del calibrador fsQCA

*Informe público. Fecha de cierre: 2026-08-13.*

> **English summary.** This report documents what has, and what has not, been validated
> against published fsQCA studies. **There is no integral external validation of the
> Likert/multi-item workflow**: the frozen corpus contains **zero Level A studies** — none
> published allows the full chain to be reproduced end to end — and **nine Level B**, which
> cover isolated modules. What was executed is a **modular** contrast of eight published
> studies through the package's public functions. Every figure below carries the table it
> comes from and the deviation measured; the limits are in the same body text as the
> results, and so are the twenty-two defects the exercise found in this tool.

---

## 1. Lo primero, porque condiciona todo lo demás

**No existe validación externa integral del flujo Likert/multiítem de esta herramienta**, y
la cobertura modular que sí existe **no se suma para simularla**. La búsqueda que lo
determina está cerrada y congelada en
[`validacion/busqueda-ampliada.md`](validacion/busqueda-ampliada.md): de 1.689 tarjetas
cribadas y 28 estudios evaluados a texto completo, **cero son de Nivel A** —una cadena
integral reproducible— y **nueve son de Nivel B**, que cubren módulos sueltos. Ninguna
frase de este informe autoriza a decir «validada externamente» sin más.

Lo que sí se puede afirmar, y es lo que este documento sostiene con cifras: **los seis
módulos del motor —calibración, necesidad, tabla de verdad, minimización, ajuste y
robustez— se contrastaron contra ocho estudios publicados, por las funciones públicas del
paquete y sobre los datos que esos estudios depositaron, y reproducen sus resultados
publicados dentro de las desviaciones que se detallan más abajo.**

## 2. Qué es esta validación, y qué no es

- **No valida la estadística.** El motor no reimplementa ningún cálculo: envuelve `QCA`,
  `SetMethods`, `psych`, `lavaan` y `NCA`. Lo que se pone a prueba es que la herramienta
  orqueste esos paquetes de modo que un análisis publicado vuelva a salir.
- **Se ejecutó por el camino público.** Todo lo que se midió pasa por las funciones
  exportadas que usa la aplicación —`leer_datos()`, `definir_mapeo()`,
  `promediar_constructos()`, `definir_anclas()`, `calibrar()`,
  `diagnosticar_calibracion()`, `analizar_necesidad()`, `construir_tabla_verdad()`,
  `minimizar()`, `diagnosticar_suficiencia()`, `ajuste_de_expresion()`,
  `rango_consistencia()`, `rango_frecuencia()`, `barrido_robustez()`—, no por rutas
  internas. Un resultado que sólo se alcanza sorteando la API no cuenta.
- **Se ejecutó dos veces, y sólo la segunda cuenta.** La primera pasada sorteó defectos del
  propio motor para llegar al resultado; la segunda se rehízo entera por las funciones
  públicas después de corregirlos. Conviene decir por qué importa la distinción: en la
  primera pasada E012 daba «13 de 14» valores, y ese valor discrepante **no era ruido, era
  un defecto de la herramienta** (`minimizar()` etiquetaba como intermedia la solución
  parsimoniosa). Un informe basado en la primera pasada habría publicado una tasa de acierto
  alta y habría enterrado el hallazgo.
- **El dossier de búsqueda es anterior y describe otra cosa.**
  `validacion/busqueda-ampliada.md` congela el 2026-08-11 la **selección** de estudios, que
  se hizo sin ejecutar la herramienta; la replicación que describe este informe vino después.

## 3. El corpus, y por qué la cobertura es desigual

Cifras contadas sobre `validacion/cribado-estudios.csv` y `validacion/estudios.csv`:

| Etapa | Conteo |
| --- | ---: |
| Tarjetas identificadas | 1.689 |
| Duplicados | 985 |
| Descartes en metadatos | 680 |
| Tarjetas abiertas a texto completo | 24 |
| Canónicos evaluados a texto completo | 28 |
| Nivel A / Nivel B / exclusiones | 0 / 9 / 19 |

Los nueve incluidos son E001, E008, E009, E012, E014, E015, E025, E026 y E027. La cobertura
por módulo, contada sobre `estudios.csv` tras la auditoría de celdas del 2026-08-13 que
contrastó cada celda contra el artículo original:

| Módulo | Estudios que lo sostienen |
| --- | --- |
| calibración | 8 — E001, E008, E012, E014, E015, E025, E026, E027 |
| necesidad | 8 — E008, E009, E012, E014, E015, E025, E026, E027 |
| tabla de verdad | 2 — E012, E015 |
| minimización | 4 — E001, E008, E012, E015 |
| ajuste | 9 — los nueve |
| robustez | 3 — E001, E012, E026 |

Son 34 celdas `si` sobre 54 pares estudio-módulo. **`tabla_verdad` sólo es comparable en 2
de los 9 estudios y `robustez` en 3**: en siete de ellos la celda estaba marcada sin que
ninguna tabla publicada la sostuviera, porque el artículo *describe* la tabla de verdad al
explicar el método y publica sólo la tabla de **soluciones**, que es minimización y ajuste.

## 4. Cómo se comparó

- **Los artefactos son los que depositaron los autores**, descargados de su repositorio,
  verificados por SHA-256 y **no versionados en este repositorio** (§10 los identifica para
  que cualquiera los recupere).
- **Se comparan valores publicados en tablas**, nunca leídos de una figura.
- **No hay un umbral que dictamine «pasa».** De cada comparación se informa cuántos valores
  se compararon y la **desviación máxima**; el lector decide. Los estudios publican con dos
  o tres decimales, así que una desviación del orden de la milésima es el suelo de
  resolución del dato publicado, no una diferencia de cálculo.

## 5. Lo reproducido, módulo por módulo

### 5.1 Calibración

| Estudio | Qué se comparó | Valores | Desviación máxima |
| --- | --- | ---: | ---: |
| E026 | las membresías que el motor calibra desde el crudo con las anclas publicadas, contra las **calibradas por los autores** (459 casos × 6 condiciones) | 2.754 | 0,0094 |
| E009 | ídem contra la base calibrada de los autores (203 × 7) | 1.421 | 0,0090 |
| E009 | las **21 anclas** de su Tabla 5, recuperadas como percentiles 95/50/5 de la muestra | 21 | 0,0003 |
| E012 | las **15 anclas** de su Tabla 2 | 15 | 0,0050 |

Los autores de E026 y E009 publican sus membresías con dos y tres decimales; contra E026,
la calibración del motor cae dentro de 0,005 en 2.168 de las 2.754 comparaciones, y coincide
al redondear a dos decimales en 332 a 433 de los 459 casos según la condición.

**La banda del 0,50.** `corregir_050()` detecta **93 de 93** casos en el punto de cruce de
E009, casilla a casilla y sin ninguno de más: las siete condiciones coinciden una a una con
las 93 celdas que los autores dejaron marcadas en `0,501` en su propia base. El control
importa: **con la comparación por igualdad exacta que el motor usaba antes, y con las anclas
tal como el artículo las publica —redondeadas a tres decimales—, sólo se habrían hallado
52.** En E026 la misma función encuentra **193 pertenencias en 0,50 exacto, repartidas en 170
de sus 459 casos**.

### 5.2 Necesidad

| Estudio | Tabla | Valores | Desviación máxima |
| --- | --- | ---: | ---: |
| E009 | Tablas 7 y 8, sobre las membresías de sus autores | 48 | 0,0005 |
| E026 | Tabla 4 | 48 | 0,0009 |
| E027 | Tabla 9 | 24 | 0,0139 (23 dentro de 0,01) |
| E012 | S3 Table, consistencias | 20 | 0,0045 |
| E025 | Tabla 9 | 24 | ver §8 |
| E014 | Tabla 4 | — | **no reproduce**, ver §8 |

### 5.3 Tabla de verdad

- **E012** publica sus dos tablas de verdad completas (S4 y S5). El motor produce **23 y 23
  filas**, **las mismas 23 configuraciones** en cada una, y **el mismo conjunto de filas por
  encima del umbral de consistencia 0,80**. Sobre las 46 consistencias brutas y PRI de cada
  tabla, la desviación máxima es 0,0162, con 34 y 32 valores dentro de 0,005.
- **E015** publica la suya para la submuestra de 2021 (Tabla 4). El motor produce
  **19 filas frente a 19**, **las mismas 19 configuraciones** y **las 19 frecuencias
  idénticas**, una a una. Las consistencias brutas caen dentro de 0,0116 y los PRI dentro de
  0,0517. Esa reproducción es sobre la membresía **sin corregir el 0,50**, que es la única
  base que reproduce el reparto de casos del artículo; ver §8.

### 5.4 Minimización

| Estudio | Qué salió |
| --- | --- |
| E012 | las **8 configuraciones** de sus Tablas 3 y 4 —4 del resultado alto y 4 del bajo— salen **literalmente**, por la solución intermedia con las expectativas direccionales que el artículo publica |
| E009 | los **7 términos** de su Tabla 9 —6 del resultado alto y 1 del bajo— salen literalmente |
| E008 | los **5 términos** de su Tabla 7 —3 y 2— salen literalmente |
| E026 | las **4 configuraciones** de su Tabla 5 y las **3 + 3** de los dos paneles de su Tabla 6 salen literalmente |
| E025 | las **6 configuraciones** de su Tabla 10 salen literalmente, por la intermedia y bajo la declaración de expectativas que se describe en §6 |
| E015 | los **3 caminos** de su Tabla 5 para 2021 salen literalmente, y son exactamente 3 |
| E027 | **5 de las 6** configuraciones de su Tabla 10; ver §8 |
| E014 | los 4 términos que reproducen el ajuste de su Tabla 5 |

### 5.5 Ajuste

| Estudio | Tabla | Valores | Desviación máxima |
| --- | --- | ---: | ---: |
| E026 | Tabla 5 (14) y los dos paneles de la Tabla 6 (11 + 11) | 36 | 0,0005 |
| E009 | Tabla 9, alto (20) y bajo (5) | 25 | 0,0005 |
| E008 | Tabla 7 | 19 | 0,0055 |
| E027 | Tabla 10, las seis configuraciones | 18 | 0,0058 |
| E025 | Tabla 10 | 20 | 0,0056 |
| E012 | Tablas 3 y 4 | 28 | 0,0095 |
| E014 | Tabla 5, comparada como conjunto ordenado | 14 | 0,0069 |

### 5.6 Robustez

**E026 es el único estudio del corpus que publica una prueba de robustez con cifras
alternativas completas**, y el motor reproduce **los dos paneles de su Tabla 6**: subir la
frecuencia de 4 a 5 y subir la consistencia de 0,80 a 0,82 dan exactamente sus tres
configuraciones en cada caso, con sus coberturas de solución **0,286** y **0,218** y sus
consistencias 0,794 y 0,815 (22 valores, desviación máxima 0,0005).

Sobre esa misma base, las ventanas que calcula el paso 7 son
`rango_consistencia() = [0,80; 0,80]` y `rango_frecuencia() = [4; 4]`: la solución cambia en
cuanto cualquiera de los dos umbrales se mueve, que es exactamente lo que el propio artículo
demuestra al moverlos. La ventana no es un elogio de la solución, es una medida — y aquí
mide lo mismo que midieron sus autores.

## 6. Qué solución publica cada estudio

Varios artículos declaran una solución y publican otra. El motor permite decidirlo, porque
produce las tres y dice cuál presenta:

| Estudio | Lo que publica |
| --- | --- |
| E012 | **intermedia**, como declara, y con las expectativas direccionales que él mismo publica en texto |
| E025 | **intermedia**, pero sólo bajo una declaración de expectativas que el artículo **no** publica: con `FUN` y `AES` esperadas presentes y `EXP` esperada ausente salen sus seis configuraciones; con las seis condiciones esperadas presentes, no. Ni la conservadora ni la parsimoniosa las dan |
| E015 | **parsimoniosa**, como declara |
| E026 | **conservadora**, y sobre las membresías **sin corregir el 0,50**: con `corregir_050()` aplicado, su Tabla 5 deja de salir |
| E009 | **conservadora**, pese a declarar intermedia |
| E014 | **conservadora**: sus cifras de ajuste son las de la conservadora, pese a que el artículo declara explícitamente que selecciona la intermedia |
| E008 | **indistinguible**: sus 16 configuraciones están todas observadas, no queda ningún remanente y las tres soluciones coinciden |
| E027 | **ninguna de las tres** reproduce su Tabla 10 completa |

## 7. Los límites

Van aquí, con la misma letra que los aciertos.

1. **Cero estudios de Nivel A.** No existe validación integral del flujo Likert/multiítem
   completo, y no porque no se haya intentado: **no hay ningún estudio publicado en el
   corpus que lo permita**. La cobertura es y seguirá siendo modular mientras eso no cambie.
2. **Los escenarios de desplazamiento de anclas del paso 7 no tienen contraparte publicada.**
   Ningún estudio del corpus hace ese ejercicio, así que esa parte del paso 7 descansa en
   medición interna —pruebas propias sobre los datos reales de E012 y E026— y no en un
   resultado externo.
3. **E012 no reproduce sus Tablas 6 y 7**, que son su prueba de robustez: **0 de 4 términos**
   a un corte de 0,85 y **0 de 4** a un corte de 0,90. La evidencia disponible apunta al
   artículo —`ajuste_de_expresion()` da a tres de las cuatro configuraciones que la Tabla 6
   declara intactas a 0,90 consistencias de **0,7495, 0,7575 y 0,7947** sobre las membresías
   reconstruidas de sus propios datos—, pero **es un no-reproduce y se dice como tal**.
4. **E001 no se ejecutó.** Su paquete de réplica está en Harvard Dataverse y el 2026-08-11
   seis rutas distintas de su API devolvieron `HTTP 202` con cuerpo vacío y
   `x-amzn-waf-action: challenge`. Es un bloqueo del servidor, no de un archivo. Ocho de los
   nueve incluidos sí quedaron con artefacto verificado; E001 no.
5. **`tabla_verdad` sólo es comparable en 2 de los 9 estudios y `robustez` en 3** (§3). Lo
   que se contrastó de esos dos módulos es lo que había, y es poco.
6. **Reproducir un resultado publicado obliga a veces a reproducir también lo que la
   herramienta desaconseja.** Las tablas de verdad de E015 y las soluciones de E026 sólo
   salen sobre membresías **sin corregir el 0,50**, que es lo que hicieron sus autores y
   justamente lo que el paso 4 de esta herramienta impide hacer en silencio. Es decir: la
   comparación demuestra que el motor **puede** reproducir lo publicado, no que lo publicado
   sea lo que el motor recomendaría.
7. **La comparación no es un contrato de aceptación.** No hay umbral que declare «validado»:
   hay cuentas y desviaciones. Un lector que exija tres decimales exactos verá que sólo
   algunas comparaciones lo alcanzan; uno que acepte la resolución con que se publican los
   datos verá otra cosa. Las dos lecturas salen de la misma tabla.

## 8. Observaciones sobre los trabajos replicados

Lo que sigue son **observaciones derivadas de una replicación independiente**, no
conclusiones. Cada una dice qué se midió, contra qué y dónde. Pueden tener explicaciones que
los datos publicados no permiten distinguir —una versión distinta del archivo, un paso
intermedio no descrito, una convención de etiquetado—, y **lo procedente es comunicárselas a
los autores antes de sacar cualquier conclusión**. No se atribuye intención a nadie.

- **E025, Tabla 9 (necesidad).** Tal como está impresa, 16 de sus 24 valores caen dentro de
  0,01 de lo que medimos, con una desviación máxima de 0,1095. Si se intercambian las filas
  de `fs_EXP` y `fs_AES` —y sus negaciones—, los **24 de 24** caen dentro de 0,01 y la
  desviación máxima baja a **0,0072**. Con las filas tal como se publican, `fs_EXP` figura en
  0,904 y `fs_AES` en 0,825; lo que medimos es 0,828 para EXP y 0,905 para AES. El artículo
  usa 0,90 como umbral de necesidad, de modo que la lectura de qué condición lo supera se
  invierte.
- **E027, Tabla 10 (soluciones).** Las seis configuraciones y sus 18 valores individuales
  reproducen dentro de 0,0058. Los dos valores de solución, no: el artículo publica
  consistencia **0,920** y cobertura **0,890**, y sobre sus datos medimos consistencia
  **0,8968** y cobertura **0,9205**. La consistencia publicada coincide con la cobertura
  medida hasta la tercera cifra.
- **E014.** Su tabla de necesidad no se reproduce por ninguna de **cinco vías** probadas
  —datos depositados con resultado difuso, su Tabla 2 impresa, su Tabla 3 dicotómica con
  resultado difuso, la misma con el resultado dicotomizado, y los datos depositados contra la
  negación del resultado—: el error absoluto medio va de 0,095 a 0,238 en consistencia y de
  0,176 a 0,383 en cobertura, y **ninguno** de los 10 valores coincide a dos decimales por
  ninguna vía. Aparte: su Tabla 3, rotulada «Truth table», es una matriz caso × condición
  dicotómica, y **discrepa en 56 de sus 100 celdas** de lo que se obtiene dicotomizando su
  propia Tabla 2 en 0,50 (58 de 100 frente al CSV depositado). Y el CSV depositado discrepa
  de su Tabla 2 impresa en **11 de 100** celdas.
- **E015.** En la submuestra de 2021, la calibración con los percentiles que el artículo
  declara deja **36 pertenencias en 0,50 exacto**; `QCA` deja fuera de la tabla de verdad
  todo caso con una pertenencia de 0,50, y aquí eso son **23 de sus 60 empresas**. Las
  frecuencias de su Tabla 4 suman **37**, no 60, lo que es coherente con esa pérdida. Por
  otro lado, en sus dos submuestras la consistencia de solución publicada es **mayor que la
  de cada uno de sus caminos** (2018: 0,813 frente a 0,805 / 0,767 / 0,762; 2021: 0,853
  frente a 0,841 / 0,829 / 0,794); en la réplica de 2021 —que reproduce sus tres caminos
  literalmente— la consistencia de solución nos sale **0,7598**, por debajo de la de los tres
  (0,794 / 0,836 / 0,851).

Hay una observación más que **se deja fuera a propósito** porque no se puede formular sin
conjeturar: la configuración `S-6` de E027 abarca una fila de la tabla de verdad con dos
casos, por debajo del umbral de frecuencia 3 que el propio artículo declara. Tratada como
remanente —que es lo que hacen las soluciones intermedia y parsimoniosa— esa configuración es
alcanzable, así que no hay nada que señalar.

## 9. Los defectos que esta validación encontró en la herramienta

Veintidós, todos corregidos y todos con prueba. Cada arreglo se validó por **mutación**: se
revirtió en el código fuente, se ejecutó la suite y se comprobó que se ponía roja; un arreglo
cuya reversión deja la suite en verde es un arreglo sin prueba. Que una validación externa
encuentre veintidós defectos y los cierre es su mejor argumento, no algo que esconder.

Ninguno era de estadística: la minimización, la necesidad y el ajuste ya reproducían lo
publicado desde la primera pasada. Eran de plomería, de medida y de contrato — y varios
hacían que el resultado correcto **no llegara** al investigador. Dos de los veintidós, el 17
y el 18, son huecos de la API antes que errores de cálculo: sin ellos la replicación no se
puede ejecutar por el camino que recorre el investigador.

| # | Defecto | Dónde |
| --: | --- | --- |
| 1 | `minimizar()$intermedia` devolvía la solución **parsimoniosa** con la etiqueta correcta | `analisis.R` |
| 2 | `diagnosticar_suficiencia()` abortaba cuando `QCA` devolvía varios modelos equivalentes | `analisis.R` |
| 3 | los términos de los modelos equivalentes se aplanaban con repeticiones | `analisis.R` |
| 4 | `SetMethods` se invocaba con `::` sin estar declarado en `Imports` | `DESCRIPTION` |
| 5 | el paso 7 no recibía `pri` y dictaminaba sobre una solución distinta de la del paso 6 | `robustez.R` |
| 6 | `corregir_050()` comparaba con igualdad exacta y perdía **41 de 93** casos de E009 | `calibracion.R` |
| 7 | `definir_anclas()` rechazaba las condiciones binarias, y con ellas el ejemplo canónico del método | `calibracion.R` |
| 8 | A-13 exigía `rho = 1` y se disparaba con los empates legítimos de la calibración directa | `alertas.R` |
| 9 | la cobertura única de una solución de un solo término salía `NA` donde el valor es conocido | `analisis.R` |
| 10 | los desplazamientos de ancla del paso 7 iban en **unidades absolutas**: medían la escala de los datos, no la robustez | `robustez.R` |
| 11 | el paso 7 dictaminaba sobre la conservadora aunque el paso 6 presentara la intermedia | `robustez.R` |
| 12 | `barrido_robustez()` aplanaba los modelos equivalentes | `robustez.R` |
| 13 | un umbral sin límite hallado salía `NA` sin motivo, y `NA` significaba lo contrario | `robustez.R` |
| 14 | las alertas de la tabla de verdad usaban umbrales de fábrica en vez de los declarados | `analisis.R` |
| 15 | `alertas_tabla_verdad()` no aceptaba el objeto que devuelve `construir_tabla_verdad()` | `analisis.R` |
| 16 | `calibrar()` dejaba llegar pertenencias de 0,50 a la tabla de verdad, y `QCA` descarta esos casos avisando sólo en inglés | `analisis.R` |
| 17 | no había forma de evaluar **la** expresión de un artículo sobre **tus** membresías | `ajuste_de_expresion()`, nueva |
| 18 | `analizar_necesidad()` no analizaba las negaciones, que son práctica estándar | `analisis.R` |
| 19 | `minimizar(expectativas = )` se colgaba sin aviso con tablas de muchos remanentes | `analisis.R` |
| 20 | los casos salían numerados y no nombrados en la columna de casos | `calibracion.R` |
| 21 | `definir_anclas(1, 0.5, 0)` calibraba como difusa una columna que ya era dicotómica | `calibracion.R` |
| 22 | `ajuste_de_expresion()` devolvía el ajuste **sin negar el resultado** por una evaluación no estándar de `QCA::pof` | `analisis.R` |

Los de más peso son el 1, el 2, el 5, el 6, el 10 y el 22: los seis producían un número
equivocado o ningún número, sin error y sin aviso.

## 10. Cómo rehacer esto

Los artefactos son de terceros y **no se versionan aquí**. Se identifican por su DOI y su
SHA-256, medido el 2026-08-11:

| Estudio | Artefacto | SHA-256 |
| --- | --- | --- |
| E008 | `10.1371/journal.pone.0326226.s003` | `583c935f3015d7b664c6a49cbb0bd541dcca19b9b85e794d0ce4573ce9d28d32` |
| E009 | `10.1371/journal.pone.0348315.s002` | `4e74fbe6859cf3aae69f288a1e0db211c0d2df5c136226e738cff33d1382ebb3` |
| E012 | `10.1371/journal.pone.0282617.s001` | `ce4bdff6e659f14dce5dd0669ebf92b319db2ef176c97c8f0c7a825495e00f20` |
| E014 | `10.1371/journal.pone.0301031.s001` | `e8ee154fec02a51a5e864f04a1cd5150dc119972e6b77b0568a1cdc39d5f9812` |
| E015 | `10.1371/journal.pone.0302210.s001` | `c505a456869c547444fb858c850032fc8203458588eea0657357c6f08a66b604` |
| E025 | `10.1371/journal.pone.0291870.s001` | `01712015f25e947bddff4381ab11f40055ca66c8efc359003eb1c39ef870030b` |
| E026 | `10.1371/journal.pone.0315249.s001` (ZIP) | `e076c63a2f8221f8ab33c74e9e6747d25e81afe4ebcf48f57ff41c744a28ac28` |
| E026 | `dataset.csv`, dentro de ese ZIP | `4d8655ba5f66f95f544c073ecc8d4c229266ddf1352c3a8bd4c4af95c04a26ce` |
| E027 | `10.1371/journal.pone.0320723.s003` | `5428111021daf9ec132dc425ab137966f36f724f628e1bbdff99cc7a413ed4f0` |

Los ocho son CC BY 4.0; el paquete de E001 es CC0-1.0. Los DOI, la licencia, el localizador
primario y el límite que impide que cada estudio cuente como Nivel A están en
[`validacion/busqueda-ampliada.md`](validacion/busqueda-ampliada.md); los expedientes de las
19 exclusiones, en [`validacion/exclusiones-estudios.md`](validacion/exclusiones-estudios.md).

Dos de las replicaciones viajan **dentro** de la suite del motor, con sus datos, para que no
dependan de la red: `test-replicacion-e012.R` con los 80 países de E012 en
`datos/e012-covid-80-paises.csv`, y `test-robustez-escala.R` con las 459 empresas de E026 en
`datos/e026-capital-humano.csv`. Las demás se rehacen descargando el artefacto de su DOI y
recorriendo los pasos que documenta [`especificacion.md`](especificacion.md).

## 11. Qué haría falta para levantar el límite 1

Un estudio de Nivel A: datos brutos de ítems Likert o multiítem depositados, la regla de
agregación declarada, las anclas y los umbrales publicados, y una solución comparable, todo
con licencia compatible. Tres rondas de búsqueda sobre Zenodo, Harvard Dataverse, OSF,
DataCite, Figshare, OpenAlex, Crossref, QDR y PLOS no encontraron ninguno, y las dos últimas
rondas cerraron saturadas. Hasta que aparezca, la afirmación honesta es la del §1.
