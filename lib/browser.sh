#!/usr/bin/env bash

install_browser() {
  if command_exists google-chrome-stable; then
    log_info "Google Chrome já está instalado."
    return 0
  fi

  log_info "Instalando Google Chrome..."
  run sudo dnf install -y fedora-workstation-repositories
  run sudo dnf config-manager setopt google-chrome.enabled=1
  run sudo dnf install -y google-chrome-stable
}
