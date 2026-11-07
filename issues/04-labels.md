---
title: Usar las labels recomendadas app.kubernetes.io en los manifiestos
labels: demo-en-vivo
---
## Contexto
Los recursos sólo tienen la label `app: podinfo`. Queremos las labels recomendadas de Kubernetes para que herramientas y dashboards los agrupen bien.

## Qué hay que hacer
- Agregar `app.kubernetes.io/name: podinfo` y `app.kubernetes.io/part-of: demo` en `metadata.labels` del Deployment y del Service, y en las labels del template del pod.
- **No** cambiar `spec.selector` del Deployment ni del Service (cambiar el selector de un Deployment existente rompe el rollout).
- Agregar en `.kube-linter.yaml` un check personalizado con el template `required-label` que exija `app.kubernetes.io/name` en los objetos tipo Deployment.

## Criterios de aceptación
- `kube-linter lint k8s/ --config .kube-linter.yaml` pasa con el check nuevo.
- `kubeconform -strict` pasa.
- Los selectores quedan iguales.

## Fuera de alcance
- Labels de versión y de equipo.
