---
title: Agregar readiness y liveness probes a podinfo
labels: agent-ok
---
## Contexto
Sin probes, Kubernetes manda tráfico a pods que todavía no están listos y no reinicia los que quedan colgados. podinfo expone `/readyz` y `/healthz` en el puerto `http` (9898).

## Qué hay que hacer
- Agregar `readinessProbe` (HTTP GET `/readyz`) y `livenessProbe` (HTTP GET `/healthz`) al contenedor `podinfo`, usando el puerto con nombre `http`.
- Activar en `.kube-linter.yaml` los checks `no-readiness-probe` y `no-liveness-probe` (sección `checks.include`).

## Criterios de aceptación
- `kube-linter lint k8s/ --config .kube-linter.yaml` pasa con los dos checks activos.
- `kubeconform -strict` pasa.
- Las probes apuntan al puerto `http`, no a un número fijo.

## Fuera de alcance
- Startup probes y ajuste fino de tiempos.
