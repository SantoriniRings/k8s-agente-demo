#!/usr/bin/env bash
# Barreras que impone la plataforma sobre las ramas del agente (claude/*).
# Uso: scripts/guard.sh <rama-head> <rama-base>
# La CI ejecuta la versión de este script que está en la rama base, no la del PR.
# Requiere python3 con PyYAML.
set -euo pipefail

head_ref="${1:?rama head}"
base_ref="${2:?rama base}"

if [[ "$head_ref" != claude/* ]]; then
  echo "Rama humana ($head_ref): no aplica."
  exit 0
fi

fail=0
changed=$(git diff --name-only "origin/${base_ref}...HEAD")
echo "Archivos modificados por el agente:"
echo "$changed"

# 1. El agente no toca la CI, CODEOWNERS ni este script.
if echo "$changed" | grep -qE '^(\.github/|CODEOWNERS$|scripts/guard\.sh$)'; then
  echo "::error::Una rama claude/ no puede modificar .github/, CODEOWNERS ni scripts/guard.sh."
  fail=1
fi

# 2. El agente no puede silenciar checks con anotaciones en los manifiestos.
if git diff "origin/${base_ref}...HEAD" -- k8s/ | grep -E '^\+' | grep -q 'ignore-check.kube-linter.io'; then
  echo "::error::Una rama claude/ no puede agregar anotaciones ignore-check.kube-linter.io."
  fail=1
fi

# 3. La configuración de kube-linter sólo puede endurecerse: quitar exclusiones,
#    agregar checks o checks personalizados. Se compara el YAML parseado, no el texto.
git show "origin/${base_ref}:.kube-linter.yaml" > "${TMPDIR:-/tmp}/kl-base.yaml" 2>/dev/null || echo "{}" > "${TMPDIR:-/tmp}/kl-base.yaml"
git show "HEAD:.kube-linter.yaml" > "${TMPDIR:-/tmp}/kl-head.yaml" 2>/dev/null || echo "{}" > "${TMPDIR:-/tmp}/kl-head.yaml"
if ! python3 - "${TMPDIR:-/tmp}/kl-base.yaml" "${TMPDIR:-/tmp}/kl-head.yaml" <<'PY'
import sys, yaml

base = yaml.safe_load(open(sys.argv[1])) or {}
head = yaml.safe_load(open(sys.argv[2])) or {}
errores = []

bc, hc = base.get("checks") or {}, head.get("checks") or {}
nuevas = set(hc.get("exclude") or []) - set(bc.get("exclude") or [])
if nuevas:
    errores.append(f"agrega exclusiones: {sorted(nuevas)}")
quitados = set(bc.get("include") or []) - set(hc.get("include") or [])
if quitados:
    errores.append(f"quita checks de include: {sorted(quitados)}")
if hc.get("doNotAutoAddDefaults") and not bc.get("doNotAutoAddDefaults"):
    errores.append("desactiva los checks por defecto (doNotAutoAddDefaults)")
if bc.get("addAllBuiltIn") and not hc.get("addAllBuiltIn"):
    errores.append("desactiva addAllBuiltIn")
for clave in set(bc) | set(hc):
    if clave not in ("exclude", "include", "doNotAutoAddDefaults", "addAllBuiltIn") and bc.get(clave) != hc.get(clave):
        errores.append(f"cambia checks.{clave}")

bcc = {c.get("name"): c for c in base.get("customChecks") or []}
hcc = {c.get("name"): c for c in head.get("customChecks") or []}
for nombre, check in bcc.items():
    if hcc.get(nombre) != check:
        errores.append(f"quita o modifica el check personalizado {nombre}")

for clave in set(base) | set(head):
    if clave not in ("checks", "customChecks") and base.get(clave) != head.get(clave):
        errores.append(f"cambia la clave {clave}")

for e in errores:
    print(f"::error::Una rama claude/ no puede relajar kube-linter: {e}")
sys.exit(1 if errores else 0)
PY
then
  fail=1
fi

if [[ $fail -eq 0 ]]; then
  echo "OK: el cambio respeta las barreras."
fi
exit $fail
