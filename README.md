# Demo: un agente nocturno que resuelve tickets de Kubernetes

Repositorio de demo para la charla "Agentes que trabajan mientras duermes".
Una tarea programada de Claude Code toma por la noche un issue con la etiqueta `agent-ok`,
corrige los manifiestos de `k8s/`, valida y abre un PR en borrador. Una persona revisa y aprueba a la mañana.

No hay cluster ni credenciales de cloud: toda la validación es estática y corre en la CI.

## Qué hay en el repo

| Ruta | Para qué |
|---|---|
| `k8s/` | Manifiestos de podinfo (Namespace, Deployment, Service) con deuda técnica a propósito |
| `.kube-linter.yaml` | Checks activos; cada exclusión corresponde a un issue |
| `.github/workflows/ci.yaml` | Job `validate` (kubeconform + kube-linter) y job `guard` (barreras para ramas `claude/`) |
| `scripts/guard.sh` | El agente no puede tocar la CI ni CODEOWNERS, ni agregar exclusiones de lint |
| `CODEOWNERS` | Los archivos de barreras requieren revisión de una persona |
| `CLAUDE.md` | Reglas del agente en este repo |
| `issues/` | Los issues que se crean con el script de setup |
| `routine/prompt.md` | Prompt de la tarea programada |
| `routine/setup-script.sh` | Instala kubeconform y kube-linter en el entorno cloud |
| `scripts/setup-github.sh` | Crea etiquetas, issues y la protección de `main` |

## Issues de la demo

| # | Issue | Etiqueta inicial | Cuándo se resuelve |
|---|---|---|---|
| 1 | Requests y limits | `agent-ok` | Hoy, con **Run now** (prueba de punta a punta) |
| 2 | Readiness y liveness probes | `agent-ok` | Noche 1, a las 03:00 |
| 3 | Security context no-root | `agent-ok` | Día 2, ensayo con **Run now** |
| 4 | Labels app.kubernetes.io | `demo-en-vivo` | **En vivo**: se le pone `agent-ok` durante la charla |
| 5 | Migrar a Helm | `needs-design` | Nunca: el agente lo ignora (sirve para mostrarlo) |

El agente toma siempre el issue `agent-ok` de número más bajo. **Haz merge (o cierra) cada PR antes de la siguiente ejecución**: todos tocan `deployment.yaml` y `.kube-linter.yaml`, y si se acumulan sin merge van a tener conflictos.

## Plan de 2 días

### Día 1 (hoy)

1. Crea el repo en GitHub, por ejemplo `[cuenta]/[repo-demo]`, y sube este contenido.
2. En `CODEOWNERS`, reemplaza `[usuario-github]` por **otra persona** del equipo (ver "Ojo" abajo).
3. Corre `scripts/setup-github.sh [cuenta]/[repo-demo]`.
4. Verifica que la CI de `main` está en verde (pestaña Actions).
5. En [claude.ai/code/routines](https://claude.ai/code/routines) → **New routine**:
   - Nombre: `Agente nocturno k8s`.
   - Prompt: el contenido de `routine/prompt.md`.
   - Repositorio: `[cuenta]/[repo-demo]`.
   - Entorno: crea uno nuevo con `routine/setup-script.sh` como setup script. Revisa que el acceso de red permita `github.com`; si no, el agente valida igual en la CI.
   - Connectors: quita todos; no hacen falta.
   - Trigger: diario a las 03:00 (hora local).
6. **Run now** → debería tomar el issue #1. Abre la sesión y revisa que el PR esté acotado y la CI en verde.
7. Tu compañero aprueba, pasas el PR a "Ready for review" y haces merge. Anota cuánto tardó la ejecución.

### Noche 1

La tarea corre sola a las 03:00 y abre el PR del issue #2.

### Día 2

1. Revisa el PR nocturno, aprueba con tu compañero y haz merge. Ese PR es el que muestras en la charla como "lo que hizo mientras dormía".
2. Ensayo general: **Run now** para el issue #3, cronometrado, siguiendo el guion de la demo.
3. Prueba de barreras, desde tu terminal con tu usuario (el mismo que usa el agente):
   - `git push origin HEAD:main` con un commit cualquiera → GitHub tiene que rechazarlo.
   - Intentar el merge de un PR sin aprobación → tiene que rechazarlo.
   - PR trampa: una rama `claude/trampa-anotacion` que agrega `ignore-check.kube-linter.io/no-liveness-probe` al Deployment → `validate` en verde y `guard` en rojo. Déjalo abierto sin merge: sirve para mostrarlo en la charla.
4. Deja abiertas las pestañas: historial de la tarea, el repo, el PR de la noche 1 y la sesión del ensayo (plan B).

### En la charla

1. Muestra el historial y el PR de la noche.
2. Ponle `agent-ok` al issue #4 en vivo.
3. **Run now** y narra la sesión mientras corre.
4. Cuando abra el PR: CI en verde (`validate` y `guard`), revisión y aprobación.
5. Si en 6 minutos no abrió el PR, pasa al plan B: la sesión del ensayo.

## Ojo con esto

- **No puedes aprobar tu propio PR.** Los commits y PRs del agente salen con tu usuario de GitHub, y GitHub no permite que el autor apruebe. Para el merge hace falta otra persona, presente en la charla o conectada. Es un buen punto para contar: el agente usa tu identidad, así que la aprobación tiene que venir de alguien más.
- **Los PRs se abren en borrador.** Antes del merge hay que pasarlos a "Ready for review".
- **Verde no significa éxito.** El estado verde de una ejecución sólo indica que no hubo error de infraestructura; hay que abrir la sesión para ver qué hizo.
- **Las tareas programadas están en research preview.** El comportamiento y los límites pueden cambiar; revisa la documentación antes de la charla.
- **El tag de la imagen (`podinfo:6.5.4`) no se valida en la CI**, porque no se descarga la imagen. Verifícalo antes de desplegar estos manifiestos en un cluster real.
- **La protección de `main` también aplica a los admins (`enforce_admins: true`).** Por defecto GitHub no aplica las reglas a quien es admin del repo, y el agente actúa con tu usuario. Sin esto, el agente podría hacer push directo a `main` o merge sin aprobación.
- **Conecta GitHub con la GitHub App de Claude, no con `/web-setup`.** `/web-setup` entrega tu token completo de `gh`. Revisa que la instalación de la app no tenga permiso de *Administration* sobre el repo: con ese permiso podría quitar la protección por API.
- **`guard` ejecuta el `guard.sh` de `main`, pero el workflow sale del PR.** Si el agente modificara `guard.sh`, no podría validarse a sí mismo. Si reescribiera `.github/workflows/ci.yaml`, sí podría obtener un `guard` en verde. El respaldo real es CODEOWNERS sobre `.github/` con `require_code_owner_reviews`: **rechaza cualquier PR del agente que toque `.github/`**.
- **Qué detecta `guard`.** Compara el YAML de `.kube-linter.yaml` ya parseado, no el texto. Rechaza: exclusiones nuevas, checks quitados de `include`, `doNotAutoAddDefaults`, checks personalizados borrados o modificados, y anotaciones `ignore-check.kube-linter.io` en `k8s/`. Las anotaciones son la trampa más probable, porque `k8s/` no tiene CODEOWNERS.

## Referencias

- Tareas programadas (routines): https://code.claude.com/docs/en/routines
- Entornos cloud: https://code.claude.com/docs/en/cloud-environments
- kubeconform: https://github.com/yannh/kubeconform
- kube-linter: https://github.com/stackrox/kube-linter
- El autor no puede aprobar su propio PR: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/approving-a-pull-request-with-required-reviews
- Las reglas de protección no aplican a admins por defecto: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches

