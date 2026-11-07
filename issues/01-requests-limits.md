---
title: Definir requests y limits de CPU y memoria en podinfo
labels: agent-ok
---
## Contexto
El Deployment `podinfo` no declara recursos. Sin requests el scheduler no puede ubicar bien los pods, y sin limits un pod puede consumir todo el nodo.

## Qué hay que hacer
- Agregar `resources.requests` y `resources.limits` de CPU y memoria al contenedor `podinfo`.
- Valores sugeridos: requests `cpu: 50m`, `memory: 64Mi`; limits `cpu: 250m`, `memory: 128Mi`.
- Quitar de `.kube-linter.yaml` las exclusiones `unset-cpu-requirements` y `unset-memory-requirements`.

## Criterios de aceptación
- `kube-linter lint k8s/ --config .kube-linter.yaml` pasa sin esas dos exclusiones.
- `kubeconform -strict` pasa.
- No hay otros cambios en los manifiestos.

## Fuera de alcance
- Autoscaling (HPA) y cambios de réplicas.
