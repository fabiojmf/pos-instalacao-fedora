#!/usr/bin/env bash

configure_desktop() {
  install_chrome
  install_flatpak_apps
  install_terminal_fonts
  configure_gnome
}

install_chrome() {
  if command_exists google-chrome-stable; then
    log_info "Google Chrome já está instalado."
    return 0
  fi
  log_info "Instalando Google Chrome..."
  run sudo dnf install -y fedora-workstation-repositories
  run sudo dnf config-manager setopt google-chrome.enabled=1
  run sudo dnf install -y google-chrome-stable
}

install_flatpak_apps() {
  local app=com.bitwarden.desktop
  if flatpak list --app --columns=application 2>/dev/null | grep -qx "$app"; then
    log_info "Bitwarden já está instalado."
  else
    run flatpak install -y flathub "$app"
  fi
}

install_terminal_fonts() {
  if fc-list | grep -i 'MesloLGS NF' >/dev/null; then
    log_info "MesloLGS NF já está instalada."
    return 0
  fi
  log_info "Instalando MesloLGS NF para Powerlevel10k..."
  local destination=$HOME/.local/share/fonts base=https://github.com/romkatv/powerlevel10k-media/raw/master
  local files=(
    'MesloLGS NF Regular.ttf'
    'MesloLGS NF Bold.ttf'
    'MesloLGS NF Italic.ttf'
    'MesloLGS NF Bold Italic.ttf'
  ) file encoded
  if (( DRY_RUN )); then
    log_info "Baixaria as fontes MesloLGS NF em $destination."
    return 0
  fi
  mkdir -p "$destination"
  for file in "${files[@]}"; do
    encoded=${file// /%20}
    curl -fL "$base/$encoded" -o "$destination/$file"
  done
  fc-cache -f
}

configure_gnome() {
  if ! command_exists gsettings || [[ -z ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then
    log_warn "Sessão GNOME indisponível; preferências gráficas não foram aplicadas."
    return 0
  fi

  log_info "Aplicando preferências GNOME..."
  run gsettings set org.gnome.desktop.interface color-scheme prefer-dark
  run gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:close

  local path=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/
  run gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$path']"
  run gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" name 'Open WezTerm'
  run gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" command wezterm
  run gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" binding '<Control><Alt>Up'

  local favorites="['org.mozilla.firefox.desktop', 'google-chrome.desktop', 'com.bitwarden.desktop.desktop', 'org.gnome.Nautilus.desktop', 'jetbrains-idea.desktop', 'dbeaver-ce.desktop', 'org.wezfurlong.wezterm.desktop']"
  run gsettings set org.gnome.shell favorite-apps "$favorites"
}
