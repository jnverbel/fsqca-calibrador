# Plan 04 — Interfaz, informe y despliegue

**Objetivo:** poner el motor en manos del investigador. Asistente Shiny de ocho pasos,
informe Quarto en HTML y Word, contenedor Docker en Fly.io con contraseña.

**Depende de los planes 01-03**: el motor está completo y probado (373 pruebas).

## Cómo se verifica esto

**No con `testthat`.** La interfaz se mira a ojo, con capturas en los tres puntos donde el
investigador decide: el mapeo, los deslizadores y el semáforo. Las capturas las revisa
Javier. Y **nada sustituye a que el investigador la use** sobre sus datos reales.

Lo que sí se prueba automáticamente es que la app **arranca sin error** y que el motor
sigue verde: la frontera Shiny (`test-frontera-shiny.R`) es la que garantiza que meter
interfaz no contamine el cálculo.

---

## Plan de diseño

### El sujeto manda

Una herramienta de trabajo metodológico para **una persona que trabaja sola**, en sesiones
largas, tomando decisiones que va a defender ante un jurado. No es un panel de control ni
una landing: es un instrumento. La pantalla debe hacer fácil **leer números y escribir
prosa**, que son las dos cosas que ocurren aquí.

**El anclaje no es arbitrario:** el investigador ya recibió el documento de propuesta en
PDF, y el informe final saldrá en Quarto. La aplicación extiende esa misma identidad, para
que propuesta → herramienta → informe se lean como un solo trabajo.

### Color

La paleta de estados **se validó con `scripts/validate_palette.js`**, no a ojo. La primera
tentativa —rojo `#A32F2F` con cobre `#9A5B2D`— **falló**: ΔE 9,6 en visión normal y 4,9 en
deuteranopía, es decir, dos colores que el investigador no podría distinguir. La que se usa
pasa las cinco comprobaciones:

| Rol | Hex | Uso |
|---|---|---|
| Bloqueante | `#C4342B` | alerta que impide avanzar |
| Advertencia | `#C98A0A` | alerta que exige reconocimiento |
| Informativa | `#2E6FD0` | se registra y se imprime |
| Resuelta | `#1E8A63` | dejó de dispararse |
| Tinta | `#16202E` | texto |
| Azul estructura | `#1F3A5F` | títulos, reglas, encabezados |
| Papel | `#FCFCFB` / `#F2F3F5` | fondo y paneles |

Los estados **nunca van solo por color**: llevan etiqueta y símbolo, según la regla de
status colors.

**La escala de membresía es divergente, y eso no es una elección estética.** En teoría de
conjuntos difusos, 0,50 no es "el medio de una escala": es **máxima ambigüedad respecto de
la pertenencia**. Una rampa secuencial mentiría sobre el método. Va cobre (fuera del
conjunto) ← gris neutro en 0,50 → azul (dentro), con la línea del 0,50 marcada siempre.

### Tipografía — la regla es que el tipo declara la naturaleza del contenido

| Rol | Familia | Por qué |
|---|---|---|
| Títulos de paso y **justificaciones** | serif (`Charter`, `Iowan Old Style`, Palatino, Georgia) | lo que el investigador escribe **es el producto**: acaba impreso en la tesis, así que se le da tratamiento de prosa, no de formulario |
| Controles, etiquetas, navegación | sans del sistema | son herramienta, no contenido |
| **Todo número** | monoespaciada (`SF Mono`, Menlo, monospace) | consistencia, PRI, membresías y anclas se comparan en columna; con proporcional no se alinean |

El campo donde se justifica un ancla se compone en serif, a medida de lectura (66ch), sobre
blanco: parece un manuscrito, no un input. Es el riesgo que asumo, y se justifica solo —
ese texto sale íntegro en el informe y es lo primero que lee un evaluador.

### Layout

```
┌──────────────────────────────────────────────────────────────┐
│  Calibrador fsQCA            proyecto.json  ⭳ guardar        │
├──────────────────────────────────────────────────────────────┤
│  ①Ingesta ─②Medida ─③Agregar ─④Calibrar ─⑤Semáforo ─⑥…      │  ← regla de pasos
├────────────────────────────────────────┬─────────────────────┤
│                                        │  BITÁCORA           │
│   Paso 4 · Calibración                 │                     │
│   ────────────────────                 │  ▲ A-18 Efecto      │
│                                        │    techo   CAP_ABS  │
│   CAP_ABS                              │    ┌──────────────┐ │
│   plena  ▁▁▁▁▁●▁▁▁  4,0                │    │ reconocer…   │ │
│   cruce  ▁▁▁●▁▁▁▁▁  3,0                │    └──────────────┘ │
│   nula   ▁●▁▁▁▁▁▁▁  2,0                │                     │
│   ┌──────────────────────────────────┐ │  ● A-17 casos en    │
│   │ tira de membresía · 120 casos    │ │    0,50    CAP_ABS  │
│   │ ▏▏ ▏▎  ▍▌ ▌│▐ ▊▉█▉▊ ▋▌▍         │ │                     │
│   └──────────────────────┊───────────┘ │                     │
│      0                 0,50          1 │                     │
│                                        │                     │
│   Fuente del ancla  [teoría        ▾]  │                     │
│   ┌──────────────────────────────────┐ │                     │
│   │ El umbral de 4 corresponde a…    │ │  ← serif, 66ch      │
│   └──────────────────────────────────┘ │                     │
├────────────────────────────────────────┴─────────────────────┤
│                        [ Continuar al paso 5 → ]             │
└──────────────────────────────────────────────────────────────┘
```

La bitácora **vive fija a la derecha en todos los pasos**. No es un panel que se abre: es la
razón de ser de la herramienta, y esconderla contradiría la regla de la compuerta.

Los pasos se numeran porque **son una secuencia real** y el orden lleva información: no se
puede calibrar antes de agregar. Numerar aquí encoda algo verdadero.

### La firma: la tira de membresía

Una tira horizontal por condición donde **cada caso es una marca vertical** en su posición
de membresía, sobre la escala divergente, con el 0,50 marcado. Reaparece en el paso 4 (bajo
los deslizadores), en el paso 5 (semáforo) y en el informe.

Es lo que hace visible **el problema central del método**: ver 110 de 120 marcas apiladas
contra el borde derecho comunica el efecto techo de un vistazo, mejor que un histograma y
mucho mejor que un número. Es denso, honesto y específico de este dominio.

**Toda la audacia se gasta ahí.** El resto —controles, tablas, navegación— se mantiene
quieto y gris.

### Fuera de alcance, declarado

- **Modo oscuro.** El producto de esta herramienta es papel; el investigador trabaja de día
  contra un informe que se imprime. Añadirlo sería trabajo sin destinatario.
- **Móvil.** Se usa en un escritorio, con deslizadores finos y tablas anchas. Se garantiza
  que no desborda por debajo de 1024px, nada más.

---

## Tareas

### Tarea 1 — Armazón y tema
`app/app.R`, `app/R/tema.R`, `app/www/estilos.css`. Regla de pasos, bitácora fija,
paleta validada, tipografía. Un modo `DEV_PASO` que precarga estado para poder capturar
cualquier paso sin repetir el flujo a mano.

- [ ] La app arranca y sirve en `127.0.0.1:7788`.
- [ ] Captura de la pantalla vacía; revisarla a ojo.

### Tarea 2 — Pasos 1 a 3
Carga de archivo, mapeo ítem→constructo editable, tabla de fiabilidad, ICC. Cada paso
llama al motor y vuelca las alertas en la bitácora.

### Tarea 3 — Paso 4, el corazón
Tres deslizadores por condición con la tira de membresía en vivo, contador de `% > 0,50` y
de casos en 0,50, selector de fuente y campo de justificación en serif. **La compuerta:**
el botón de continuar se desactiva con alertas abiertas y explica cuál.

### Tarea 4 — Pasos 5 a 8
Semáforo con la tira por condición, tabla de verdad con PRI en rojo cuando falla,
las tres soluciones, y descargas: proyecto JSON, base calibrada, informe, guion.

### Tarea 5 — Informe Quarto
`informe/informe.qmd` en HTML y Word. Necesita `! brew install --cask quarto` (pide
contraseña).

### Tarea 6 — Docker y Fly.io
`Dockerfile` sobre `rocker/r-ver` con `renv.lock`, contraseña, HTTPS. Necesita Docker y
`flyctl auth login`, que exige credenciales del usuario.
