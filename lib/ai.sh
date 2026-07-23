#!/usr/bin/env bash

install_ai_tools() {
  log_info "Configurando diretórios persistentes dos agentes de IA..."
  local agents_home=$HOME/.local/share/ai-agents
  export AI_AGENTS_HOME=$agents_home
  export CLAUDE_CONFIG_DIR=$agents_home/claude
  export KIRO_HOME=$agents_home/kiro

  run mkdir -p "$CLAUDE_CONFIG_DIR" "$KIRO_HOME" "$agents_home/pi/agent" "$HOME/.config/ai-agents"
  ensure_symlink "$agents_home/pi" "$HOME/.pi"
  ensure_symlink "$agents_home/kiro" "$HOME/.kiro"

  install_if_missing "$ROOT_DIR/config/ai-agents/endpoints.zsh.example" \
    "$HOME/.config/ai-agents/endpoints.zsh" 0600
  install_if_missing "$ROOT_DIR/config/claude/settings.json" \
    "$CLAUDE_CONFIG_DIR/settings.json" 0644
  install_if_missing "$ROOT_DIR/config/pi/settings.json" \
    "$agents_home/pi/agent/settings.json" 0644

  install_ai_mise_tools
  install_pi_packages
  install_herdr_integrations
}

install_ai_mise_tools() {
  log_info "Instalando Claude Code, Kiro CLI, Pi e Herdr pelo mise..."
  if (( DRY_RUN )); then
    log_info "Executaria mise use --global para claude, kiro-cli, Pi e Herdr."
    return 0
  fi

  local exclusions tool
  exclusions=$(mise_cmd settings get minimum_release_age_excludes 2>/dev/null || printf '[]')
  for tool in 'github:ogulcancelik/herdr' 'npm:@earendil-works/pi-coding-agent'; do
    if ! grep -qF "\"$tool\"" <<<"$exclusions"; then
      mise_cmd settings add minimum_release_age_excludes "$tool"
      exclusions=$(mise_cmd settings get minimum_release_age_excludes 2>/dev/null || printf '[]')
    fi
  done

  mise_cmd use --global --yes \
    claude@latest \
    kiro-cli@latest \
    'github:ogulcancelik/herdr@latest' \
    'npm:@earendil-works/pi-coding-agent@latest'
}

install_pi_packages() {
  log_info "Instalando o pacote pi-web-access pelo próprio Pi..."
  if (( DRY_RUN )); then
    log_info "Executaria: pi install npm:pi-web-access"
  else
    mise_cmd exec -- pi install npm:pi-web-access
  fi
}

install_herdr_integrations() {
  log_info "Instalando integrações oficiais do Herdr para Claude e Pi..."
  if (( DRY_RUN )); then
    log_info "Executaria: herdr integration install claude/pi"
  else
    mise_cmd exec -- herdr integration install claude
    mise_cmd exec -- herdr integration install pi
  fi
}
