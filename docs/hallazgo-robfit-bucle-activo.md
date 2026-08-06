# El bucle de `helper_rob.R` está en tres sitios y uno de ellos corrompe `rob.fit()` hoy

**Fecha:** 2026-08-06. **Estado:** verificado, **no comunicado a Oana todavía** (decisión de
esperar a septiembre, ver el final).
**Reprex:** `referencias/robfit-solucion-media-ignorada.R` — corre entero, salidas pegadas.
**Antecedente:** el seguimiento enviado el 2026-08-02 reportó este bucle en **un** sitio y con
la salvedad de que estaba *enmascarado* por el Bug 1. **Las dos cosas resultaron ser
inexactas**, y esta es la rectificación.

## 1. Está en tres sitios, no en uno

Fuente inspeccionado: `github.com/nenaoana/SetMethods`, `R/helper_rob.R` (repo de desarrollo de
la propia mantenedora; último push 2025-07-05, posterior a la publicación de la 4.1 en CRAN).

| Línea | Función | Escrito |
|---|---|---|
| 5 | `rob.union` | `for (i in 1:length(test_sol))` ← **correcta** |
| 26 | `rob.evaluation` | `for (i in length(test_sol))` |
| 147 | `robust.intersections` | `for (i in length(test_sol))` |
| 208 | `robust.rank` | `for (i in length(test_sol))` |

El correo del 08-02 solo mencionó la de `robust.intersections`, que es la que se ve al
desensamblar `rob.cases()`. Las otras dos aparecen únicamente leyendo el archivo entero.

## 2. No está enmascarado: `rob.fit()` lo ejecuta y no aborta

`rob.fit()` llama a `rob.evaluation()`, y `rob.fit()` **funciona**. El correo del 08-02 dijo
*"as things stand this is masked by Bug 1: `rob.cases()` aborts before the loop is reached"*.
Eso vale para `robust.intersections`, no para `rob.evaluation`. Por esa vía el defecto se
manifiesta hoy, en una función publicada del protocolo, **devolviendo cifras plausibles**.

La rama de lista de `rob.evaluation()` siembra `P2` con `test_sol[[1]]` y luego hace `pmin`
solo con `test_sol[[length(test_sol)]]`. Lo que esté en medio no entra.

## 3. Prueba de mutación

Datos `PAYF` del propio paquete, tres soluciones de prueba. Primera y última fijas; se cambia
únicamente la del medio, por dos soluciones que no se parecen en nada (`HE` frente a `GG*AH`).

```
                      RF_cov RF_cons RF_SC_minTS RF_SC_maxTS
medio = HE             0.987   0.973       0.960       0.724
medio = GG*AH          0.887   0.963       0.960       0.724   <- misma cifra
GG*AH movida al final  0.887   0.963       0.885       0.730   <- la misma, ahora sí cuenta
```

`RF_SC_minTS` y `RF_SC_maxTS` no se mueven al cambiar la solución del medio, y sí se mueven
cuando esa misma solución pasa a la última posición. `RF_cov` y `RF_cons` sí reaccionan porque
pasan por `rob.union()`, que recorre la lista entera.

**Consecuencia:** quien pase tres o más especificaciones alternativas a `rob.fit()` —que es lo
que pide el protocolo de Oana y Schneider (2024)— obtiene dos de las cuatro cifras de ajuste
calculadas sobre la primera y la última nada más, sin aviso ni error.

Es más grave que los dos bugs ya reportados: aquellos abortan, y un aborto se ve. Este no.

## 4. El calibrador no está afectado

`pkg/calibraqca/R/robustez.R:312` llama a `SetMethods::rob.fit(test_sol = intento, ...)` con
**un único objeto de solución**, no una lista. La rama de lista de `rob.evaluation()` no se
ejecuta, y el bucle defectuoso tampoco. Comprobado por lectura del único punto de llamada:
no hay ningún otro uso de `rob.fit` ni de `rob.cases` en el código de producción.

## 5. Contexto para decidir cuándo escribir

- SetMethods 4.1 está en CRAN desde **2025-03-21**. De la 4.0 (2023-03) a la 4.1 pasaron **dos
  años**. La cadencia de mantenimiento no es semanal.
- El correo a Oana salió el 07-31 y el seguimiento el 08-02: **cuatro días hábiles**, en
  agosto, con el EUI en cierre estival. El silencio no es señal de nada.
- Adrian Dușa contestó en **dos días** — pero por un issue de GitHub con notificaciones, no
  por correo.
- **Canal alternativo disponible:** `github.com/nenaoana/SetMethods` tiene los issues
  habilitados y **cero issues abiertos en toda su historia**. Deja rastro público y fechado,
  que es lo que conviene si esto va a JOSS.

## Decisión tomada el 2026-08-06

**Esperar a septiembre.** No enviar un tercer correo en agosto. Cuando se escriba, va **un
solo** mensaje que junte, en este orden: (1) la rectificación del `toupper`, (2) esta
rectificación del alcance del bucle, (3) el hallazgo de `esa()`, (4) el `rob.fit`, que es el
argumento más fuerte porque es el único que corrompe resultados en vez de abortar.
El borrador vive en `respuesta-oana-en-espera.md`.

## Lección

La misma de la revalidación del 08-02, y por segunda vez: **lo que se dice sobre el alcance de
un defecto es tan conjetural como lo que se dice sobre su causa.** «Está en `robust.intersections`»
y «está enmascarado por el Bug 1» se escribieron sin abrir el archivo entero ni buscar quién más
llamaba a la función. Un `grep` del patrón en todo el fuente y otro de los llamadores habría dado
las dos correcciones antes de que el correo saliera.
