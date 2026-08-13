# Calibrador fsQCA para datos Likert

*[🇬🇧 English](README.md) · 🇪🇸 Español*

Herramienta de apoyo metodológico que lleva un archivo de respuestas Likert de 5 puntos
hasta un anexo listo para una tesis doctoral: validación de medida, agregación,
calibración difusa directa, necesidad y suficiencia, minimización booleana y barrido de
robustez.

**No reimplementa ningún cálculo estadístico.** Envuelve `QCA`, `SetMethods`, `psych`,
`lavaan` y `NCA` — paquetes revisados por pares y citables. Lo que aporta es lo que este
universo comparado no documenta: validar la fiabilidad antes de promediar, diagnosticar el
efecto techo, exigir que cada ancla se justifique y dejar rastro escrito de esa
justificación en el informe.

«No documenta» no es «no existe», y la diferencia la fija esta misma rama: en
[`docs/estado-del-arte.md`](docs/estado-del-arte.md) las 14 herramientas comparadas quedan
en `no_verificado` para `validacion_medida`, y ese código **no equivale a `no`**.

## Qué evidencia externa hay, y cuál no

El motor está **contrastado contra ocho estudios publicados**, por las funciones públicas del
paquete y sobre los datos que esos estudios depositaron: los seis módulos —calibración,
necesidad, tabla de verdad, minimización, ajuste y robustez— reproducen sus resultados
publicados. [`docs/validacion-integral.md`](docs/validacion-integral.md) da cada cifra con la
tabla de la que sale y la desviación medida.

Esa cobertura es **modular**. El corpus congelado tiene **cero estudios de Nivel A** —ningún
estudio publicado permite recorrer el flujo Likert/multiítem completo— y **nueve de Nivel B**,
que cubren módulos sueltos. **No existe validación externa integral del flujo completo**, y la
cobertura modular no se suma para simularla. La búsqueda que lo determina está cerrada y
congelada en [`docs/validacion/busqueda-ampliada.md`](docs/validacion/busqueda-ampliada.md).

El mismo informe lleva, en el mismo cuerpo del texto, lo que **no** reprodujo, y los
**veintidós defectos que el ejercicio encontró en esta herramienta** —todos cerrados, cada uno
con la mutación que pone roja una prueba—.

## Estado

[![pruebas](https://github.com/jnverbel/fsqca-calibrador/actions/workflows/pruebas.yml/badge.svg)](https://github.com/jnverbel/fsqca-calibrador/actions/workflows/pruebas.yml)

**Completo y funcionando.** Las suites suman
**1.063 pruebas de motor** y **81 pruebas de interfaz**,
ninguna con `skip`, detrás de una interfaz Shiny de ocho pasos y un informe Quarto en HTML y
Word. Esas dos cifras no se teclean a mano: el trabajo de CI que corre cada suite exige que
el README publique el recuento que acaba de medir, exactamente una vez.

La calibración está **contrastada contra un resultado publicado**: reproduce la calibración
difusa que Ragin publicó para los datos de Lipset (1959) dentro de la precisión con que ese
dato se publica, y los puntos de cruce recuperados coinciden con los umbrales del estudio.

Las dos suites corren en Linux en cada empujón, sobre el entorno que reconstruye
`renv.lock`. El flujo falla si aparece una prueba omitida: una prueba omitida es una prueba
que no existe.

```sh
Rscript -e 'testthat::test_local("pkg/calibraqca")'  # el motor
Rscript tests/interfaz.R                             # la interfaz, en un navegador
```

Cada constante numérica del motor está tabulada en
[`docs/especificacion.md`](docs/especificacion.md) con la mutación que debe romper una prueba
concreta. Una constante que sobrevive a su mutación es una constante sin prueba.

**Se ejecuta en el equipo del investigador**, con doble clic. Instrucciones para él, sin
jerga, en [`INSTALAR.md`](INSTALAR.md). El único requisito previo es instalar R una vez.

## Sobre el idioma

La interfaz, el informe generado y los identificadores del código están en **español**, a
propósito: esta herramienta existe para el investigador social hispanohablante, que hoy no
tiene con qué validar la fiabilidad antes de promediar. La documentación que necesita un
lector de fuera — el README, la guía de instalación y la de desarrollo — está en **inglés**.

Los nombres de las funciones exportadas (`calibrar()`, `nueva_bitacora()`, `semaforo`) son
en español y se quedan en español. La [especificación](docs/especificacion.md) también, con
un resumen inicial en inglés que explica cómo leer sus tablas.

## Ejecutar

Siempre desde la raíz del repositorio — ahí vive el `.Rprofile` que activa `renv`.

```bash
Rscript app/app.R                                   # la aplicación
Rscript -e 'testthat::test_local("pkg/calibraqca")' # las pruebas
quarto render informe/informe.qmd                   # el informe
```

Instrucciones completas, incluido el despliegue: [`docs/como-ejecutar.md`](docs/como-ejecutar.md).

## Documentación

| Documento | Contenido | Idioma |
|---|---|---|
| [`INSTALAR.md`](INSTALAR.md) | Para el investigador: instalar R y abrir la herramienta | Español |
| [`INSTALL.md`](INSTALL.md) | Lo mismo, en inglés | Inglés |
| [`docs/como-ejecutar.md`](docs/como-ejecutar.md) | Para desarrollo: ejecutar, generar el informe y desplegar | Español |
| [`docs/development.md`](docs/development.md) | La misma guía, condensada, en inglés | Inglés |
| [`docs/especificacion.md`](docs/especificacion.md) | Arquitectura, los 8 pasos, las 36 alertas, esquema del archivo de proyecto, informe y plan de pruebas | Español, resumen en inglés |
| [`docs/validacion-integral.md`](docs/validacion-integral.md) | Validación externa: qué se contrastó contra estudios publicados, con qué cifras y qué queda fuera | Español, resumen en inglés |
| [`docs/referencias/`](docs/referencias/) | `fuzzy_likert_5.R` y los reprex de los reportes de bugs aguas arriba | Código R |

> `fuzzy_likert_5.R` es **otra ruta metodológica** (Delphi difuso con números
> triangulares), no el punto de partida del motor. Ver la sección 0.4 de la especificación.

## Bugs reportados aguas arriba

Trabajar en esta herramienta destapó defectos en los paquetes que envuelve. Cada uno está
documentado con un ejemplo reproducible en [`docs/referencias/`](docs/referencias/):

- `SetMethods` 4.1 — `rob.cases` roto; el bucle de `helper_rob` está en tres funciones y
  corrompe `rob.fit()`
  ([reprex](docs/referencias/robfit-solucion-media-ignorada.R))
- `QCA` — `minimize()` reconstruye en silencio una tabla de verdad modificada cuando se le
  pasa `n.cut` ([reprex](docs/referencias/qca-minimize-ncut-reprex.R),
  [issue #4](https://github.com/dusadrian/QCA/issues/4))

El calibrador no está afectado por ninguno de los dos.

## Reparto de responsabilidades

El desarrollo, el despliegue y el mantenimiento son apoyo técnico. **Las decisiones
metodológicas — de dónde salen las anclas y cómo se justifican — son del investigador,
porque son las que se defienden ante el jurado.** La herramienta está diseñada
precisamente para dejar constancia documentada de cada una.

## Licencia

MIT. Ver [`LICENSE`](LICENSE). Para citarla, ver [`CITATION.cff`](CITATION.cff).
