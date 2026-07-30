# Calibrador fsQCA para datos Likert

Herramienta de apoyo metodológico que lleva un archivo de respuestas Likert de 5 puntos
hasta un anexo listo para una tesis doctoral: validación de medida, agregación,
calibración difusa directa, necesidad y suficiencia, minimización booleana y barrido de
robustez.

**No reimplementa ningún cálculo estadístico.** Envuelve `QCA`, `SetMethods`, `psych`,
`lavaan` y `NCA` — paquetes revisados por pares y citables. Lo que aporta es lo que hoy no
existe: validar la fiabilidad antes de promediar, diagnosticar el efecto techo, exigir que
cada ancla se justifique y dejar rastro escrito de esa justificación en el informe.

## Estado

**Motor completo y probado** (los ocho pasos, 373 pruebas sin `skip`), interfaz Shiny de
ocho pasos e informe Quarto en HTML y Word. Falta desplegarlo en Fly.io: la configuración
está escrita y solo requiere las credenciales del titular de la cuenta.

## Ejecutar

Siempre desde la raíz del repositorio — ahí vive el `.Rprofile` que activa `renv`.

```bash
Rscript app/app.R                                   # la aplicación
Rscript -e 'testthat::test_local("pkg/calibraqca")' # las pruebas
quarto render informe/informe.qmd                   # el informe
```

Instrucciones completas, incluido el despliegue: [`docs/como-ejecutar.md`](docs/como-ejecutar.md).

## Documentación

| Documento | Contenido |
|---|---|
| [`docs/especificacion.md`](docs/especificacion.md) | Arquitectura, los 8 pasos, las 32 alertas, esquema del archivo de proyecto, informe y plan de pruebas |
| [`docs/como-ejecutar.md`](docs/como-ejecutar.md) | Ejecutar en local, generar el informe y desplegar |
| [`docs/preguntas-al-investigador.md`](docs/preguntas-al-investigador.md) | Las 8 preguntas para dimensionar el trabajo |
| [`docs/referencias/`](docs/referencias/) | PDF de la propuesta técnica y `fuzzy_likert_5.R` |

> `fuzzy_likert_5.R` es **otra ruta metodológica** (Delphi difuso con números
> triangulares), no el punto de partida del motor. Ver la sección 0.4 de la especificación.

## Reparto de responsabilidades

El desarrollo, el despliegue y el mantenimiento son apoyo técnico. **Las decisiones
metodológicas — de dónde salen las anclas y cómo se justifican — son del investigador,
porque son las que se defienden ante el jurado.** La herramienta está diseñada
precisamente para dejar constancia documentada de cada una.
