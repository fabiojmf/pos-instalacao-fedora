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
