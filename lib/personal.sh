#!/usr/bin/env bash

install_personal_apps() {
  local app=com.bitwarden.desktop
  if flatpak list --app --columns=application 2>/dev/null | grep -qx "$app"; then
    log_info "Bitwarden já está instalado."
  else
    run flatpak install -y flathub "$app"
  fi
}
