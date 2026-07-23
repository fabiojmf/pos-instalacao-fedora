#!/usr/bin/env bash

install_shell() {
  log_info "Instalando Zsh, Oh My Zsh, plugins e Powerlevel10k..."
  run sudo dnf install -y zsh

  if [[ ! -d $HOME/.oh-my-zsh ]]; then
    if (( DRY_RUN )); then
      log_info "Instalaria Oh My Zsh."
    else
      RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" -- --unattended
    fi
  fi

  local custom=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
  clone_or_update https://github.com/romkatv/powerlevel10k.git "$custom/themes/powerlevel10k"
  clone_or_update https://github.com/zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"
  clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting "$custom/plugins/zsh-syntax-highlighting"

  install_config "$ROOT_DIR/config/zsh/zshrc" "$HOME/.zshrc" 0600
  install_config "$ROOT_DIR/config/zsh/p10k.zsh" "$HOME/.p10k.zsh" 0644

  local zsh_path
  zsh_path=$(command -v zsh || echo /usr/bin/zsh)
  if [[ $(getent passwd "$USER" | cut -d: -f7) != "$zsh_path" ]]; then
    run sudo chsh -s "$zsh_path" "$USER"
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
