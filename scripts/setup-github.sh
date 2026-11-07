#!/usr/bin/env bash
# Prepara el repo de demo en GitHub: etiquetas, issues y protección de main.
# Requiere gh autenticado con permisos de admin sobre el repo.
# Uso: scripts/setup-github.sh <owner>/<repo>
set -euo pipefail

repo="${1:?Uso: scripts/setup-github.sh <owner>/<repo>}"
cd "$(dirname "$0")/.."

echo "== Etiquetas"
gh label create agent-ok      --repo "$repo" --color 2EB9D6 --description "Apto para el agente nocturno" --force
gh label create agent-blocked --repo "$repo" --color FF6250 --description "El agente necesita información" --force
gh label create needs-design  --repo "$repo" --color 0F2B45 --description "Requiere decisión humana" --force
gh label create demo-en-vivo  --repo "$repo" --color FFD166 --description "Se etiqueta agent-ok en vivo durante la charla" --force

echo "== Issues"
for f in issues/*.md; do
  title=$(sed -n 's/^title: //p' "$f" | head -1)
  labels=$(sed -n 's/^labels: //p' "$f" | head -1)
  body=$(awk 'BEGIN{n=0} /^---$/{n++; next} n>=2' "$f")
  echo "-> $title [$labels]"
  gh issue create --repo "$repo" --title "$title" --label "$labels" --body "$body"
done

echo "== Protección de main"
# Requiere: PR con 1 aprobación (de code owners) y los checks 'validate' y 'guard' en verde.
# enforce_admins=true es obligatorio: el agente actúa con tu usuario, que es admin del repo, y por defecto
# la protección no aplica a los admins. La salida de emergencia es desactivarla a mano en Settings > Branches.
gh api -X PUT "repos/$repo/branches/main/protection" --input - <<'JSON'
{
  "required_status_checks": { "strict": true, "contexts": ["validate", "guard"] },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "require_code_owner_reviews": true,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON

echo "Listo. Revisa los issues en https://github.com/$repo/issues"
