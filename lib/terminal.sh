#!/usr/bin/env bash

install_terminal() {
  log_info "Instalando WezTerm nightly e JetBrains Mono..."
  run sudo dnf copr enable -y wezfurlong/wezterm-nightly
  run sudo dnf install -y wezterm jetbrains-mono-fonts
  install_config "$ROOT_DIR/config/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua" 0644
  install_terminal_fonts
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
