# fsQCA Calibrator for Likert data

*🇬🇧 English · [🇪🇸 Español](README.es.md)*

A methodological support tool that takes a file of 5-point Likert responses all the way to
an appendix ready for a doctoral dissertation: measurement validation, aggregation, direct
fuzzy calibration, necessity and sufficiency, Boolean minimisation and a robustness sweep.

**It reimplements no statistical computation.** It wraps `QCA`, `SetMethods`, `psych`,
`lavaan` and `NCA` — peer-reviewed, citable packages. What it contributes is what the
compared universe of tools does not document: validating reliability *before* averaging,
diagnosing the ceiling effect, requiring that every anchor be justified, and leaving a
written trace of that justification in the report.

"Not documented" is not "does not exist", and this repository draws that line itself: in
[`docs/estado-del-arte.md`](docs/estado-del-arte.md) all 14 compared tools are recorded as
`no_verificado` for `validacion_medida`, and that code **is not equivalent to `no`**.

## What external evidence exists, and what does not

The search for published studies to validate this tool against is closed and frozen in
[`docs/validacion/busqueda-ampliada.md`](docs/validacion/busqueda-ampliada.md): **zero Level
A studies** (a reproducible end-to-end chain), **nine Level B** (isolated module coverage),
and **no replication executed yet**. There is no integral external validation of the
Likert/multi-item workflow, and modular coverage is not added up to simulate one.

## Status

[![tests](https://github.com/jnverbel/fsqca-calibrador/actions/workflows/pruebas.yml/badge.svg)](https://github.com/jnverbel/fsqca-calibrador/actions/workflows/pruebas.yml)

**Complete and working.** An engine with 1,059 tests and 81 interface tests, none of them
skipped, an eight-step Shiny interface, and a Quarto report in HTML and Word.

The calibration is **checked against a published result**: it reproduces the fuzzy
calibration Ragin published for the Lipset (1959) data, to the precision at which that
figure is published, and the recovered crossover points match the study's thresholds.

Both suites run on Linux on every push, on the environment rebuilt from `renv.lock`. The
workflow fails if a skipped test appears: a skipped test is a test that does not exist.

```sh
Rscript -e 'testthat::test_local("pkg/calibraqca")'  # the engine
Rscript tests/interfaz.R                             # the interface, in a browser
```

Every numeric constant in the engine is tabulated in
[`docs/especificacion.md`](docs/especificacion.md) together with the mutation that must turn
a specific test red. A constant that survives its mutation is a constant without a test.

**It runs on the researcher's own machine**, by double-clicking. Jargon-free instructions
for them in [`INSTALL.md`](INSTALL.md). The only prerequisite is installing R once.

## A note on language

The interface, the generated report and the source identifiers are in **Spanish**, on
purpose: this tool exists for the Spanish-speaking social-science researcher who today has
nothing to validate reliability with before averaging. The documentation an outside reader
needs — this README, the installation guide and the development guide — is in **English**.

Exported function names (`calibrar()`, `nueva_bitacora()`, `semaforo`) are Spanish and will
stay Spanish. The [specification](docs/especificacion.md) is in Spanish too; it opens with
an English summary of how to read its tables.

## Running it

Always from the repository root — that is where the `.Rprofile` that activates `renv` lives.

```bash
Rscript app/app.R                                   # the application
Rscript -e 'testthat::test_local("pkg/calibraqca")' # the tests
quarto render informe/informe.qmd                   # the report
```

Full instructions, deployment included: [`docs/development.md`](docs/development.md).

## Documentation

| Document | Contents | Language |
|---|---|---|
| [`INSTALL.md`](INSTALL.md) | For the researcher: install R and open the tool | English |
| [`INSTALAR.md`](INSTALAR.md) | The same, for the Spanish-speaking researcher | Spanish |
| [`docs/development.md`](docs/development.md) | For development: run it, build the report, deploy | English |
| [`docs/como-ejecutar.md`](docs/como-ejecutar.md) | Development log with the local-environment detail | Spanish |
| [`docs/especificacion.md`](docs/especificacion.md) | Architecture, the 8 steps, the 36 alerts, project-file schema, report and test plan | Spanish, English summary |
| [`docs/referencias/`](docs/referencias/) | `fuzzy_likert_5.R` and the reprexes for the upstream bug reports | R source |

> `fuzzy_likert_5.R` is **a different methodological route** (fuzzy Delphi with triangular
> numbers), not the engine's starting point. See section 0.4 of the specification.

## Upstream bug reports

Work on this tool surfaced defects in the packages it wraps. Each one is documented with a
reproducible example under [`docs/referencias/`](docs/referencias/):

- `SetMethods` 4.1 — `rob.cases` broken; the `helper_rob` loop appears in three functions
  and corrupts `rob.fit()`
  ([reprex](docs/referencias/robfit-solucion-media-ignorada.R))
- `QCA` — `minimize()` silently rebuilds a modified truth table when passed `n.cut`
  ([reprex](docs/referencias/qca-minimize-ncut-reprex.R),
  [issue #4](https://github.com/dusadrian/QCA/issues/4))

The calibrator itself is not affected by either.

## Division of responsibility

Development, deployment and maintenance are technical support. **The methodological
decisions — where the anchors come from and how they are justified — belong to the
researcher, because those are the ones defended before the committee.** The tool is designed
precisely to leave a documented record of each one.

## Licence

MIT. See [`LICENSE`](LICENSE). To cite it, see [`CITATION.cff`](CITATION.cff).
