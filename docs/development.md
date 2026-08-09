# Development guide

*🇬🇧 English · [🇪🇸 Español](como-ejecutar.md)*

Four separate things: running the application locally, building the report, running the
tests, and deploying it so the researcher can use it from a browser.

The Spanish version, [`como-ejecutar.md`](como-ejecutar.md), carries additional detail about
the maintainer's local environment (how Quarto was installed without `sudo`, `renv` cache
recovery on macOS). If you only need to run and review this repository, this page is enough.

---

## 0. The rule that gets broken over and over

**Everything runs from the repository root**, never from a subfolder.

```bash
cd fsqca-calibrador
```

The `.Rprofile` that activates `renv` lives at the root. From `app/` or `informe/`, R finds
neither `shiny` nor `QCA` and fails with *"there is no package called…"*. The app checks
this at startup and aborts with a clear message instead of a cryptic error.

First time on a fresh checkout, rebuild the environment from the lockfile:

```bash
Rscript -e 'renv::restore(prompt = FALSE)'
```

This takes several minutes — it installs around 130 R packages.

---

## 1. The application, locally

```bash
Rscript app/app.R
```

Opens <http://127.0.0.1:7788>. The console will warn that it starts **open**, with no
password — which is the right thing on your own machine.

### Environment variables

| Variable | Purpose | Default |
|---|---|---|
| `PUERTO` | listening port | `7788` |
| `CLAVE_APP` | access password; without it the app is left open | unset |
| `HOST_APP` | listening interface; `0.0.0.0` in a container | `127.0.0.1` |
| `DEV_PASO` | start at that step with `limpia.csv` already loaded | `0` |

To see step 4 without walking the flow by hand:

```bash
DEV_PASO=4 Rscript app/app.R
```

With a password, as in production:

```bash
CLAVE_APP="pick-one" Rscript app/app.R
```

### Rendering one screen without starting the server

```bash
Rscript app/capturar.R 4 /tmp/paso4.html
```

Renders that step's HTML by calling the same functions the app uses. It exists because
Shiny fills the panels over a websocket and headless Chrome does not get to capture them.

---

## 2. The report

```bash
Rscript informe/generar-ejemplo.R           # example project, first time only
quarto render informe/informe.qmd           # HTML and Word
```

This produces `informe/informe.html` and `informe/informe.docx`. With the researcher's own
data:

```bash
quarto render informe/informe.qmd \
  -P proyecto:path/to/proyecto.json \
  -P datos:path/to/survey.csv
```

Quarto is a separate prerequisite; install it from <https://quarto.org/docs/get-started/>.

---

## 3. The tests

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca")'  # the engine
Rscript tests/interfaz.R                             # the interface, in a browser
```

660 engine tests and 18 interface tests, no `skip`. The CI workflow fails if a skipped test
appears. A filter, to go faster:

```bash
Rscript -e 'testthat::test_local("pkg/calibraqca", filter = "calibracion")'
```

Test names and messages are in Spanish, like the rest of the source.

---

## 4. Deploying to Fly.io

The `Dockerfile`, the `fly.toml` and the `.dockerignore` are already written. **Docker is
not required locally**: `--remote-only` builds the image on Fly's servers.

These steps need your credentials, so they go in your own terminal.

```bash
cd fsqca-calibrador

# 1. Log in (opens the browser)
flyctl auth login

# 2. Create the app without deploying yet.
#    Answer NO to "deploy now?": the password has to be set first. This is
#    not just advice -- on Fly the app refuses to start without CLAVE_APP.
flyctl launch --no-deploy --copy-config --name calibrador-fsqca --region bog

# 3. The access password, as a secret. Never in the repository, never in the image.
flyctl secrets set CLAVE_APP="a-long-password-you-use-nowhere-else"

# 4. Deploy. --remote-only builds on Fly, not on your machine.
flyctl deploy --remote-only
```

The first build is slow: it installs around 130 R packages. Later ones are fast, because
the `Dockerfile` copies `renv.lock` before the code, so Docker reuses the package layer for
as long as the lockfile is unchanged.

### Checking it came out right

```bash
flyctl status
flyctl logs
flyctl open          # opens the URL in the browser
```

It must ask for the password before showing anything.

### What the configuration does

| Setting | What it means |
|---|---|
| `force_https = true` | traffic is encrypted; Fly issues the certificate |
| `auto_stop_machines = "stop"` | idle, the machine stops and stops billing |
| `auto_start_machines = true` | it comes back on the first visit, after a few seconds |
| `min_machines_running = 0` | nothing running overnight |
| `memory = "2gb"` | R with `QCA`, `lavaan` and `NCA` loaded does not fit comfortably in 512 MB |
| `primary_region = "bog"` | Bogotá |

Send the researcher the URL and the password **through separate channels**.

---

## 5. If something breaks

**«there is no package called…»** — either you are outside the repository root, or the
`renv` cache is gone. Check the second:

```bash
du -sh ~/Library/Caches/org.R-project.R/R/renv/cache   # 4.0K means empty
```

Then rebuild from the lockfile:

```bash
Rscript -e 'renv::restore(prompt = FALSE)'
```

**You installed a package and it disappears on restore** — the snapshot is missing. After
every `renv::install()`:

```bash
Rscript -e 'renv::snapshot(type = "all", prompt = FALSE)'
```

**On Fly the machine does not come up, and the log says `CLAVE_APP no esta definida`** — that
is the intended behaviour, not a fault: the repository is public and the app name is in
`fly.toml`, so the URL can be worked out. Starting without a password would leave the whole
tool open. Set it and redeploy:

```bash
flyctl secrets set CLAVE_APP="a-long-password-you-use-nowhere-else"
flyctl deploy --remote-only
```

**It starts locally without asking for a password** — that is correct. Off Fly there is
nobody to protect against, and the console says so out loud when it listens beyond
`127.0.0.1`. Run `flyctl secrets list` to confirm the secret exists in production.
