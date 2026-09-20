#!/usr/bin/env bash

install_toolchains() {
  remove_fedora_node
  install_sdkman
  install_mise
  install_node_with_mise
  install_config "$ROOT_DIR/config/zsh/post.d/20-toolchains.zsh" \
    "$HOME/.config/zsh/post.d/20-toolchains.zsh" 0644
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

install_sdkman() {
  if [[ -d $HOME/.sdkman ]]; then
    log_info "SDKMAN já está instalado. Nenhuma versão Java será alterada."
    return 0
  fi
  log_info "Instalando somente o SDKMAN; versões Java ficam a cargo do usuário."
  if (( DRY_RUN )); then
    log_info "Executaria o instalador oficial do SDKMAN."
  else
    curl -fsSL https://get.sdkman.io | bash
  fi
}

install_mise() {
  if command_exists mise || [[ -x $HOME/.local/bin/mise ]]; then
    log_info "mise já está instalado."
    return 0
  fi
  log_info "Instalando mise..."
  if (( DRY_RUN )); then
    log_info "Executaria o instalador oficial do mise."
  else
    curl -fsSL https://mise.run | sh
  fi
}

mise_cmd() {
  if command_exists mise; then
    mise "$@"
  else
    "$HOME/.local/bin/mise" "$@"
  fi
}

install_node_with_mise() {
  log_info "Instalando Node LTS exclusivamente pelo mise..."
  if (( DRY_RUN )); then
    log_info "Executaria: mise use --global --yes node@lts"
  else
    mise_cmd use --global --yes node@lts
  fi
}
