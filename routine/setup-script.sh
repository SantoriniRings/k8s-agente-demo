#!/usr/bin/env bash
# Script de setup para el entorno cloud de la tarea programada.
# Pegar en el campo "Setup script" del entorno (se cachea entre ejecuciones).
# Corre como root antes de que arranque Claude Code: instala en /usr/local/bin para que
# las herramientas estén en el PATH de la sesión sin depender de .bashrc.
# No usa set -e a propósito: si el script falla, la sesión no arranca. Si una descarga
# falla, el agente no tiene la herramienta, lo informa en el PR y la CI valida igual.
curl -sSL https://github.com/yannh/kubeconform/releases/download/v0.8.0/kubeconform-linux-amd64.tar.gz \
  | tar xz -C /usr/local/bin kubeconform || echo "No se pudo instalar kubeconform"
curl -sSL https://github.com/stackrox/kube-linter/releases/download/v0.8.3/kube-linter-linux.tar.gz \
  | tar xz -C /usr/local/bin kube-linter || echo "No se pudo instalar kube-linter"
exit 0
