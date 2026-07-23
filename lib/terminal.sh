#!/usr/bin/env bash

install_terminal() {
  log_info "Instalando WezTerm nightly e JetBrains Mono..."
  run sudo dnf copr enable -y wezfurlong/wezterm-nightly
  run sudo dnf install -y wezterm jetbrains-mono-fonts
  install_config "$ROOT_DIR/config/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua" 0644
}
