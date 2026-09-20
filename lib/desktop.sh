#!/usr/bin/env bash

configure_desktop() {
  configure_gnome
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

  local -a favorite_ids=(org.mozilla.firefox.desktop)
  profile_enabled browser && favorite_ids+=(google-chrome.desktop)
  profile_enabled personal && favorite_ids+=(com.bitwarden.desktop.desktop)
  favorite_ids+=(org.gnome.Nautilus.desktop)
  profile_enabled development && favorite_ids+=(jetbrains-idea.desktop dbeaver-ce.desktop)
  profile_enabled terminal && favorite_ids+=(org.wezfurlong.wezterm.desktop)

  local favorite favorite_list='[' separator=''
  for favorite in "${favorite_ids[@]}"; do
    favorite_list+="${separator}'${favorite}'"
    separator=', '
  done
  favorite_list+=']'
  run gsettings set org.gnome.shell favorite-apps "$favorite_list"
}
