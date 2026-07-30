# Instalar y abrir el Calibrador fsQCA

Esta herramienta se ejecuta **en su propio equipo**. Sus datos no salen de él en ningún
momento: no se suben a internet, no se guardan en ningún servidor.

Hay que hacer una instalación, una sola vez. Después se abre con doble clic.

---

## Paso 1 · Instalar R

R es el programa que hace los cálculos. Se instala una vez y no hay que abrirlo nunca:
la herramienta lo usa por dentro.

### En Windows

1. Abra <https://cran.r-project.org/bin/windows/base/>
2. Pulse **Download R for Windows**.
3. Ejecute el archivo descargado y acepte todas las opciones por defecto.

### En Mac

1. Abra <https://cran.r-project.org/bin/macosx/>
2. Descargue el instalador que corresponda a su Mac:
   - **Apple Silicon** si su Mac es M1, M2, M3 o posterior.
   - **Intel** si es anterior a 2020.
   - Si no está seguro: menú Apple → *Acerca de este Mac*. Si dice "Chip Apple",
     es Apple Silicon.
3. Ejecute el instalador y acepte las opciones por defecto.

---

## Paso 2 · Abrir la herramienta

Dentro de la carpeta que recibió hay dos archivos. Use el de su sistema:

- **Windows:** doble clic en `Ejecutar-en-Windows.bat`
- **Mac:** doble clic en `Ejecutar-en-Mac.command`

Se abrirá una ventana negra con texto. **No la cierre**: es la herramienta funcionando.
Al cabo de unos segundos se abrirá sola una pestaña en su navegador.

**La primera vez tarda varios minutos.** Está descargando los paquetes de cálculo. Puede
dejarlo trabajando e ir por un café. Las veces siguientes arranca en segundos.

Para cerrar la herramienta, cierre la ventana negra.

---

## Si algo no funciona

### Windows dice que el archivo no es seguro

Windows desconfía de los archivos descargados de internet. Pulse **Más información** y
después **Ejecutar de todas formas**.

### Mac dice que no puede abrirlo porque es de un desarrollador no identificado

Haga **clic derecho** sobre `Ejecutar-en-Mac.command` y elija **Abrir**. Aparecerá el
mismo aviso, pero ahora con un botón **Abrir**. Solo hay que hacerlo la primera vez.

### La ventana negra dice que no encuentra R

R no quedó instalado, o se instaló después de abrir la ventana. Cierre la ventana, vuelva
al Paso 1 y después abra de nuevo el archivo.

### En Mac, dice que no pudo instalar los paquetes

A los Mac les faltan a veces las herramientas de compilación. Abra la aplicación
**Terminal** (búsquela con ⌘+Espacio) y escriba exactamente esta línea:

```
xcode-select --install
```

Pulse Intro, acepte la instalación y espere a que termine. Después vuelva a abrir
`Ejecutar-en-Mac.command`.

### El navegador no se abre solo

Abra su navegador y escriba en la barra de direcciones:

```
http://127.0.0.1:7788
```

### Cualquier otra cosa

Haga una captura de la ventana negra completa y envíela a quien le entregó la
herramienta. El texto de esa ventana dice qué pasó.

---

## Lo que conviene saber

**Sus datos no viajan.** El archivo de respuestas se lee en su equipo y desaparece de la
memoria al cerrar la herramienta. Lo único que se guarda es lo que usted descargue.

**Guarde el archivo de proyecto.** Al terminar una sesión, descargue el archivo
`proyecto.json`. Contiene sus anclas, sus justificaciones y el cierre de cada alerta —
todo su trabajo metodológico, no los datos. Con él puede retomar donde lo dejó y volver a
generar el informe.

**El informe lo ve dentro de la herramienta.** En el último paso aparece completo, y puede
descargarlo en HTML para abrirlo en el navegador o imprimirlo.

**Para la versión en Word**, envíe el archivo `proyecto.json` a quien le entregó la
herramienta y se lo devolverá en `.docx`, listo para copiar tablas y texto a su tesis. Ese
archivo lleva sus anclas, sus justificaciones y el cierre de cada alerta — **no lleva sus
datos**.
