#!/usr/bin/env bash

install_containers() {
  log_info "Instalando Podman e Podman Compose..."
  run sudo dnf install -y podman podman-compose
}
