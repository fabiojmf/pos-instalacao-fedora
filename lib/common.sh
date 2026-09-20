#!/usr/bin/env bash

log_info() { printf '\033[1;34mINFO:\033[0m %s\n' "$*"; }
log_warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*"; }
log_error() { printf '\033[1;31mERRO:\033[0m %s\n' "$*" >&2; }
die() { log_error "$*"; exit 1; }

run() {
  if (( DRY_RUN )); then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

resolve_profiles() {
  local preset_profiles=''
  case "$PRESET" in
    '')
      if [[ -z $PROFILE_ARGS ]]; then
        PRESET=host
        preset_profiles='base,cleanup,shell,terminal,desktop,browser,personal,containers,virtualization,nvidia,maintenance'
      fi
      ;;
    host)
      preset_profiles='base,cleanup,shell,terminal,desktop,browser,personal,containers,virtualization,nvidia,maintenance'
      ;;
    work-vm)
      preset_profiles='base,cleanup,shell,terminal,desktop,browser,toolchains,containers,development,ai,vm-guest,maintenance'
      ;;
    standalone)
      preset_profiles='base,cleanup,shell,terminal,desktop,browser,personal,toolchains,containers,development,ai,nvidia,maintenance'
      ;;
    *) die "Preset desconhecido: $PRESET" ;;
  esac

  PROFILES="${preset_profiles}${preset_profiles:+${PROFILE_ARGS:+,}}${PROFILE_ARGS}"
}

validate_profiles() {
  local profile
  local -a requested
  IFS=',' read -ra requested <<<"$PROFILES"
  ((${#requested[@]})) || die "Informe ao menos um perfil ou preset."

  for profile in "${requested[@]}"; do
    case "$profile" in
      base|cleanup|shell|terminal|desktop|browser|personal|toolchains|containers|development|ai|virtualization|vm-guest|nvidia|maintenance|all) ;;
      '') die "A lista de perfis contém um item vazio." ;;
      *) die "Perfil desconhecido: $profile" ;;
    esac
  done
}

require_fedora() {
  [[ -r /etc/os-release ]] || die "Não foi possível identificar o sistema operacional."
  # shellcheck disable=SC1091
  source /etc/os-release
  [[ ${ID:-} == fedora ]] || die "Este instalador suporta somente Fedora Workstation."
  log_info "Fedora ${VERSION_ID:-desconhecido} detectado."
}

profile_enabled() {
  local wanted=$1 profile
  IFS=',' read -ra _profiles <<<"$PROFILES"
  for profile in "${_profiles[@]}"; do
    [[ $profile == "$wanted" || $profile == all ]] && return 0
  done
  return 1
}

backup_file() {
  local path=$1
  [[ -e $path || -L $path ]] || return 0
  local backup
  backup="${path}.backup.$(date +%Y%m%d-%H%M%S)"
  run cp -a -- "$path" "$backup"
  log_warn "Backup criado: $backup"
}

install_config() {
  local source=$1 destination=$2 mode=${3:-0644}
  if [[ -f $destination ]] && cmp -s "$source" "$destination"; then
    log_info "Configuração já atualizada: $destination"
    return 0
  fi
  if (( DRY_RUN )); then
    log_info "Instalaria $source em $destination"
    return 0
  fi
  mkdir -p "$(dirname "$destination")"
  backup_file "$destination"
  install -m "$mode" "$source" "$destination"
  log_info "Configuração instalada: $destination"
}

install_if_missing() {
  local source=$1 destination=$2 mode=${3:-0644}
  if [[ -e $destination || -L $destination ]]; then
    log_info "Preservando arquivo existente: $destination"
    return 0
  fi
  if (( DRY_RUN )); then
    log_info "Criaria $destination"
    return 0
  fi
  mkdir -p "$(dirname "$destination")"
  install -m "$mode" "$source" "$destination"
  log_info "Arquivo inicial criado: $destination"
}

ensure_symlink() {
  local target=$1 link=$2
  if [[ -L $link && $(readlink "$link") == "$target" ]]; then
    log_info "Link já correto: $link"
    return 0
  fi
  if [[ -e $link && ! -L $link ]]; then
    log_warn "$link existe e não é um link; preservando-o. Ajuste manualmente."
    return 0
  fi
  run mkdir -p "$(dirname "$target")"
  run ln -sfn "$target" "$link"
  log_info "Link configurado: $link -> $target"
}

clone_or_update() {
  local repository=$1 destination=$2
  if [[ -d $destination/.git ]]; then
    run git -C "$destination" pull --ff-only
  elif [[ -e $destination ]]; then
    log_warn "$destination já existe e não é um clone Git; preservando."
  else
    run git clone --depth=1 "$repository" "$destination"
  fi
}
