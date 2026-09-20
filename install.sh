#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DRY_RUN=0
PRESET=""
PROFILE_ARGS=""
PROFILES=""

usage() {
  cat <<'EOF'
Uso: ./install.sh [opções]

Opções:
  --preset NOME     Preset completo: host, work-vm ou standalone.
  --profile LISTA   Perfis separados por vírgula. Sem --preset, substitui o
                    padrão; com --preset, acrescenta perfis ao preset.
                    Disponíveis: base, cleanup, shell, terminal, desktop,
                    browser, personal, toolchains, containers, development,
                    ai, virtualization, vm-guest, nvidia, maintenance, all
  --dry-run         Mostra as principais ações sem alterar o sistema.
  -h, --help        Exibe esta ajuda.

Padrão: --preset host
EOF
}

while (($#)); do
  case "$1" in
    --preset)
      [[ $# -ge 2 && -n $2 ]] || { echo "--preset requer um nome" >&2; exit 2; }
      PRESET=$2
      shift 2
      ;;
    --profile)
      [[ $# -ge 2 && -n $2 ]] || { echo "--profile requer uma lista" >&2; exit 2; }
      PROFILE_ARGS="${PROFILE_ARGS:+$PROFILE_ARGS,}$2"
      shift 2
      ;;
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
source "$ROOT_DIR/lib/browser.sh"
source "$ROOT_DIR/lib/personal.sh"
source "$ROOT_DIR/lib/toolchains.sh"
source "$ROOT_DIR/lib/containers.sh"
source "$ROOT_DIR/lib/development.sh"
source "$ROOT_DIR/lib/ai.sh"
source "$ROOT_DIR/lib/virtualization.sh"
source "$ROOT_DIR/lib/vm-guest.sh"
source "$ROOT_DIR/lib/nvidia.sh"
source "$ROOT_DIR/lib/desktop.sh"
source "$ROOT_DIR/lib/maintenance.sh"

main() {
  resolve_profiles
  require_fedora
  validate_profiles
  [[ -n $PRESET ]] && log_info "Preset selecionado: $PRESET"
  log_info "Perfis selecionados: $PROFILES"
  (( DRY_RUN )) && log_warn "Modo dry-run: nenhuma alteração intencional será realizada."

  if profile_enabled base; then
    install_prerequisites
    update_system
    configure_flathub
  fi

  profile_enabled cleanup && remove_unwanted_apps
  profile_enabled shell && install_shell
  profile_enabled terminal && install_terminal
  profile_enabled browser && install_browser
  profile_enabled personal && install_personal_apps
  profile_enabled toolchains && install_toolchains
  profile_enabled containers && install_containers
  profile_enabled development && install_development
  profile_enabled ai && install_ai_tools
  profile_enabled virtualization && install_virtualization
  profile_enabled vm-guest && install_vm_guest
  profile_enabled nvidia && install_nvidia_if_present
  profile_enabled desktop && configure_desktop
  profile_enabled maintenance && install_maintenance_automation

  log_info "Instalação concluída."
  profile_enabled shell && log_warn "Reabra o terminal para carregar o Zsh."
  profile_enabled toolchains && log_warn "Reabra o terminal para carregar mise e SDKMAN."
  log_warn "Reinicie apenas se houve instalação/atualização do driver NVIDIA ou do kernel."
  if profile_enabled ai; then
    log_warn "Preencha manualmente ~/.config/ai-agents/endpoints.zsh e autentique os agentes."
  fi
}

main
