#!/usr/bin/env bash

install_prerequisites() {
  log_info "Instalando pré-requisitos..."
  run sudo dnf install -y curl git unzip tar flatpak jq util-linux-user dnf5-plugins
}

update_system() {
  log_info "Atualizando o Fedora..."
  run sudo dnf upgrade --refresh -y
}

configure_flathub() {
  log_info "Configurando Flathub..."
  run sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

remove_unwanted_apps() {
  log_info "Removendo aplicativos GNOME não utilizados e LibreOffice..."
  local candidates=(
    gnome-contacts gnome-weather gnome-maps gnome-boxes simple-scan totem rhythmbox
    gnome-tour gnome-characters gnome-connections evince loupe gnome-logs gnome-abrt
    gnome-system-monitor gnome-clocks gnome-calendar gnome-camera
  ) installed=() package

  for package in "${candidates[@]}"; do
    rpm -q "$package" >/dev/null 2>&1 && installed+=("$package")
  done
  ((${#installed[@]})) && run sudo dnf remove -y "${installed[@]}"

  mapfile -t installed < <(rpm -qa --qf '%{NAME}\n' | grep -E '^(libreoffice|libobasis)' | sort -u || true)
  ((${#installed[@]})) && run sudo dnf remove -y "${installed[@]}"
}

remove_fedora_node() {
  log_info "Garantindo que Node/npm não sejam gerenciados por RPM..."
  local packages=()
  mapfile -t packages < <(rpm -qa --qf '%{NAME}\n' | grep -E '^(nodejs($|-)|npm$)' | sort -u || true)
  if ((${#packages[@]})); then
    run sudo dnf remove -y "${packages[@]}"
  else
    log_info "Nenhum Node/npm do Fedora instalado."
  fi
}
