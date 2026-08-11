# Relevo: búsqueda ampliada y validación A/B

**Fecha de checkpoint:** 2026-08-11  
**Worktree:** `worktree local`  
**Rama:** `codex/estado-arte-validacion`  
**Plan rector:** `docs/superpowers/plans/2026-08-11-busqueda-ampliada-validacion.md`

## Estado científico congelado

- Búsqueda ampliada cerrada por dos rondas consecutivas saturadas (R2 y R3).
- 1.689 registros cribados, 28 evaluaciones de texto completo.
- Nivel A: **0**. No hay validación externa integral del flujo Likert/multiítem.
- Nivel B: **9**. Cubren módulos secundarios, sin sumar esos estudios a Nivel A.
- Exclusiones: **19**.
- No se ha ejecutado `fsqca-calibrador` sobre estudios externos ni se han versionado datos de terceros.

Los resultados se sustentan en `docs/validacion/registro-busqueda.csv`,
`cribado-estudios.csv`, `estudios.csv`, `rondas-busqueda.csv`,
`busqueda-ampliada.md` y `evidencia-insuficiente.md`.

## Commits relevantes

- `f6f122c` — identidad congelada de R1.
- `bc613c4` y `6160376` — rastreo, saturación e identidad de R2/R3.
- `f47da31` — primera congelación A/B.
- El commit de checkpoint posterior a este documento contiene el refuerzo pendiente
  de la auditoría de Task 5.

## Punto exacto de reanudación

Task 5 fue revisada y recibió tres hallazgos importantes. El checkpoint ya incluye
su corrección parcial o completa en:

- `validation/tests/test-seleccion-ampliada.R`
- `docs/validacion/busqueda-ampliada.md`
- `docs/validacion/exclusiones-estudios.md`

Antes de marcar Task 5 terminada, ejecutar y revisar:

```bash
Rscript --vanilla validation/tests/test-seleccion-ampliada.R
Rscript --vanilla validation/tests/test-esquemas.R
Rscript --vanilla validation/tests/test-busqueda-ampliada.R
Rscript --vanilla validation/tests/test-estado-arte.R
git diff --check
```

La revisión debe confirmar, mediante lectura del diff y pruebas negativas, que:

1. La selección fija exactamente 28 evaluaciones, 0 A, 9 B y 19 exclusiones;
   después de congelar no admite `decision=pendiente`.
2. Mutar únicamente `nivel` de **cada** B a A hace fallar el validador.
3. Todo hecho usado para incluir o excluir tiene localizador primario exacto
   (archivo + sección/tabla/página/hoja), o declara literalmente la ausencia y
   dónde se inspeccionó.

## Siguientes tareas

1. Terminar/revisar Task 5 y actualizar el libro SDD:
   `.superpowers/sdd/2026-08-11-busqueda-ampliada-validacion/progress.md`.
2. Ejecutar Task 6: escribir
   `docs/superpowers/plans/2026-08-11-replicaciones-seleccionadas.md` desde los
   nueve estudios B y sus artefactos reales. Debe contener una tarea por estudio,
   hashes, variables, parámetros, resultados, tolerancias y comparadores; no usar
   marcadores pendientes. Como no hay A, declarar que solo se planifican módulos B.
3. Solicitar revisión independiente de Task 6.
4. Hacer revisión integral de toda la rama desde el merge-base con `main`, corregir
   una sola ola de hallazgos si procede, y usar el flujo de finalización de rama.

## Disciplina de continuidad

- Usar el flujo SDD ya creado; no volver a despachar Tasks 1–4, que ya constan
  completas en `progress.md`.
- Los informes internos en `.superpowers/sdd/` son ignorados: conservarlos en disco
  pero **no** hacer `git add -f` ni versionarlos.
- No rebajar criterios A para completar una cuota ni atribuir exhaustividad a
  Dataverse global, GESIS, UKDS o ICPSR, que quedaron documentados como no
  enumerables/limitados.
- No ejecutar la aplicación hasta que el siguiente plan de replicación haya sido
  escrito a partir de los artefactos reales y la selección permanezca congelada.
