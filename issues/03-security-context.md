---
title: Correr podinfo como no-root con filesystem de solo lectura
labels: agent-ok
---
## Contexto
El contenedor corre con los valores por defecto de la imagen. Queremos garantizarlo desde el manifiesto.

## Qué hay que hacer
- En el contenedor `podinfo`, agregar `securityContext` con `runAsNonRoot: true`, `readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false` y `capabilities.drop: ["ALL"]`.
- Quitar de `.kube-linter.yaml` las exclusiones `run-as-non-root` y `no-read-only-root-fs`.

## Criterios de aceptación
- `kube-linter lint k8s/ --config .kube-linter.yaml` pasa sin esas dos exclusiones.
- `kubeconform -strict` pasa.

## Fuera de alcance
- PodSecurity admission del namespace y NetworkPolicies.
