# Cómo ejecutar el Calibrador fsQCA

*[🇬🇧 English](development.md) · 🇪🇸 Español*

Tres cosas distintas: correr la aplicación en tu Mac, generar el informe, y desplegarla
para que el investigador la use desde su navegador.

---

## 0. Regla que se rompe una y otra vez

**Todo se ejecuta desde la raíz del repositorio**, nunca desde una subcarpeta.

```bash
cd ~/Desktop/fsqca-calibrador
```

El `.Rprofile` que activa `renv` vive en la raíz. Desde `app/` o `informe/`, R no encuentra
ni `shiny` ni `QCA` y falla con *"there is no package called…"*. La app lo comprueba al
arrancar y aborta con un mensaje claro en vez de dar un error críptico.

---

## 1. La aplicación en local

```bash
Rscript app/app.R
```

Abre <http://127.0.0.1:7788>. Avisará en la consola de que arranca **abierta**, sin clave —
que es lo correcto en tu máquina.

### Variables de entorno

| Variable | Para qué | Por defecto |
|---|---|---|
| `PUERTO` | puerto de escucha | `7788` |
| `CLAVE_APP` | clave de acceso; sin ella la app queda abierta | sin definir |
| `HOST_APP` | interfaz de escucha; `0.0.0.0` en contenedor | `127.0.0.1` |
| `DEV_PASO` | arranca en ese paso con `limpia.csv` ya cargado | `0` |

Para ver el paso 4 sin recorrer el flujo a mano:

```bash
DEV_PASO=4 Rscript app/app.R
```

Con clave, como en producción:

```bash
CLAVE_APP="la-que-elijas" Rscript app/app.R
```

### Capturar una pantalla sin levantar el servidor

```bash
Rscript app/capturar.R 4 /tmp/paso4.html
```

Rinde el HTML del paso llamando a las mismas funciones que usa la app. Existe porque Shiny
rellena los paneles por websocket y Chrome en modo headless no llega a capturarlos.

---

## 2. El informe

```bash
export PATH="$HOME/.local/bin:$PATH"        # ahí quedó Quarto
Rscript informe/generar-ejemplo.R           # proyecto de ejemplo, solo la 1ª vez
quarto render informe/informe.qmd           # HTML y Word
```

Salen `informe/informe.html` e `informe/informe.docx`. Con los datos del investigador:

```bash
quarto render informe/informe.qmd \
  -P proyecto:ruta/al/proyecto.json \
  -P datos:ruta/a/la/encuesta.csv
```

### Sobre Quarto

Está en `~/.local/opt/quarto`, con un enlace en `~/.local/bin/quarto`. **No se instaló con
`brew install --cask quarto`**: ese cask ejecuta un `.pkg` con `sudo` y exige contraseña en
una terminal real. Se descargó el paquete y se expandió a mano:

```bash
brew fetch --cask quarto
pkgutil --expand-full "<ruta-del-pkg>" ~/.local/opt/quarto-extract
mv ~/.local/opt/quarto-extract/quarto-core.pkg/Payload ~/.local/opt/quarto
ln -sf ~/.local/opt/quarto/bin/quarto ~/.local/bin/quarto
```

Para que `quarto` esté siempre disponible, añade a tu `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Si algún día prefieres la instalación oficial en el sistema, abre **Terminal.app** (no el
prompt del asistente, que tampoco tiene terminal real para `sudo`) y ejecuta
`brew install --cask quarto`. Conviven sin problema.

---

## 3. Desplegar en Fly.io

Ya están escritos el `Dockerfile`, el `fly.toml` y el `.dockerignore`. **Y no hace falta
instalar Docker**: `--remote-only` construye la imagen en los servidores de Fly.

### Lo que tienes que ejecutar tú

Estos pasos necesitan tus credenciales, así que van en tu terminal.

```bash
cd ~/Desktop/fsqca-calibrador

# 1. Iniciar sesión (abre el navegador)
flyctl auth login

# 2. Crear la aplicación sin desplegar todavía.
#    Responde NO a "¿desplegar ahora?": primero hay que poner la clave.
flyctl launch --no-deploy --copy-config --name calibrador-fsqca --region bog

# 3. La clave de acceso, como secreto. Nunca va en el repositorio ni en la imagen.
flyctl secrets set CLAVE_APP="una-clave-larga-y-que-no-uses-en-otro-sitio"

# 4. Desplegar. --remote-only construye en Fly, no en tu Mac.
flyctl deploy --remote-only
```

La primera construcción tarda: instala unos 130 paquetes de R. Las siguientes son rápidas
porque el `Dockerfile` copia `renv.lock` antes que el código, así que Docker reutiliza la
capa de paquetes mientras el lockfile no cambie.

### Comprobar que quedó bien

```bash
flyctl status
flyctl logs
flyctl open          # abre la URL en el navegador
```

Debe pedir la clave antes de mostrar nada.

### Mandarle la dirección al investigador

Queda en `https://calibrador-fsqca.fly.dev`. Envíale la URL y la clave **por canales
separados** — la dirección por correo y la clave por otro medio.

### Qué hace la configuración

| Ajuste | Qué significa |
|---|---|
| `force_https = true` | el tráfico va cifrado; Fly emite el certificado |
| `auto_stop_machines = "stop"` | sin uso, la máquina se apaga y deja de facturar |
| `auto_start_machines = true` | vuelve sola con la primera visita, con unos segundos de espera |
| `min_machines_running = 0` | nada encendido de noche |
| `memory = "2gb"` | R con `QCA`, `lavaan` y `NCA` cargados no cabe cómodo en 512 MB |
| `primary_region = "bog"` | Bogotá |

### Actualizar después de un cambio

```bash
flyctl deploy --remote-only
```

---

## 4. Las pruebas

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca")'
```

660 pruebas del motor y 18 de interfaz, sin `skip`. Un filtro para ir más rápido:

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "calibracion")'
```

---

## 5. Si algo se rompe

**«there is no package called…»** — o estás fuera de la raíz del repositorio, o macOS purgó
la caché de `renv`. Comprueba lo segundo así:

```bash
du -sh ~/Library/Caches/org.R-project.R/R/renv/cache   # 4,0K significa vacía
```

Y reconstruye desde el lockfile:

```bash
Rscript -e 'renv::restore(prompt = FALSE)'
```

Tarda varios minutos: este R es el de Homebrew y compila desde fuente.

**Instalaste un paquete y desaparece al restaurar** — falta el snapshot. Después de cada
`renv::install()`:

```bash
Rscript -e 'renv::snapshot(type = "all", prompt = FALSE)'
```

**La app arranca pero no pide clave** — `CLAVE_APP` no está definida. En Fly:
`flyctl secrets list` para confirmar que existe.
