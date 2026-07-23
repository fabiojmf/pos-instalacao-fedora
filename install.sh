#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DRY_RUN=0
PROFILES="base,terminal,development,ai,nvidia,desktop"

usage() {
  cat <<'EOF'
Uso: ./install.sh [opções]

Opções:
  --profile LISTA   Perfis separados por vírgula.
                    Disponíveis: base, terminal, development, ai, nvidia, desktop, all
  --dry-run         Mostra as principais ações sem alterar o sistema.
  -h, --help        Exibe esta ajuda.

Padrão: base,terminal,development,ai,nvidia,desktop
EOF
}

while (($#)); do
  case "$1" in
    --profile) [[ $# -ge 2 ]] || { echo "--profile requer uma lista" >&2; exit 2; }; PROFILES=$2; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opção desconhecida: $1" >&2; usage; exit 2 ;;
  esac
done

# shellcheck source=lib/common.sh
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/system.sh"
source "$ROOT_DIR/lib/shell.sh"
source "$ROOT_DIR/lib/terminal.sh"
source "$ROOT_DIR/lib/development.sh"
source "$ROOT_DIR/lib/ai.sh"
source "$ROOT_DIR/lib/nvidia.sh"
source "$ROOT_DIR/lib/desktop.sh"

main() {
  require_fedora
  log_info "Perfis selecionados: $PROFILES"
  (( DRY_RUN )) && log_warn "Modo dry-run: nenhuma alteração intencional será realizada."

  if profile_enabled base; then
    install_prerequisites
    update_system
    configure_flathub
    remove_unwanted_apps
    remove_fedora_node
    install_shell
    install_sdkman
    install_mise
    install_node_with_mise
  fi

  profile_enabled terminal && install_terminal
  profile_enabled development && install_development
  profile_enabled ai && install_ai_tools
  profile_enabled nvidia && install_nvidia_if_present
  profile_enabled desktop && configure_desktop

  log_info "Instalação concluída."
  log_warn "Reabra o terminal para carregar Zsh, mise e SDKMAN."
  log_warn "Reinicie apenas se houve instalação/atualização do driver NVIDIA ou do kernel."
  log_warn "Preencha manualmente ~/.config/ai-agents/endpoints.zsh e autentique os agentes."
}

main
