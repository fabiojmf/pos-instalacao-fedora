# Ferramentas instaladas pelo perfil toolchains.
export npm_config_cache="${XDG_CACHE_HOME:-$HOME/.cache}/npm"

command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

# O script instala somente o SDKMAN; a seleção das versões Java é manual.
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
