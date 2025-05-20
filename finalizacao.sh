#!/usr/bin/env zsh
set -e # Sair imediatamente se um comando falhar

# --- Funções de Log ---
log_info() {
    echo "INFO: $1"
}

log_warn() {
    echo "WARN: $1"
}

log_error() {
    echo "ERROR: $1" >&2
}

# --- Funções Auxiliares ---

# Garante que uma linha de configuração exista e esteja correta em kitty.conf
# Descomenta e edita se existir comentada, edita se existir, ou adiciona se não existir.
configure_kitty_option() {
    local config_file="$1"
    local key="$2"
    local value="$3"
    local section_comment="$4" # Comentário de cabeçalho para a seção, se a linha for adicionada pela primeira vez

    mkdir -p "$(dirname "$config_file")" # Garante que o diretório ~/.config/kitty exista
    touch "$config_file"                 # Garante que o arquivo kitty.conf exista

    # Padrão para encontrar a chave, comentada ou não, com espaços flexíveis
    local grep_pattern="^\s*(#\s*)?${key}\s+.*"
    # Padrão sed para descomentar (se necessário) e definir o valor, preservando a chave e seus espaços
    local sed_pattern_uncomment_and_set="s@^\s*(#\s*)?(${key}\s+).*@\2${value}@g"

    if grep -q -E "$grep_pattern" "$config_file"; then
        # A chave existe (comentada ou não). Descomentar e/ou definir o valor.
        sed -i -E "$sed_pattern_uncomment_and_set" "$config_file"
        log_info "Kitty config: '${key}' atualizada/garantida para '${value}'"
    else
        # Chave não existe. Adiciona a configuração.
        if [[ -n "$section_comment" ]]; then
            # Adiciona nova linha se o arquivo não terminar com uma e não estiver vazio
            if [ -s "$config_file" ] && [ "$(tail -c1 "$config_file" | wc -l)" -eq 0 ]; then
                 echo "" >> "$config_file"
            fi
            echo "" >> "$config_file" # Linha em branco antes do comentário da seção
            echo "# --- ${section_comment} ---" >> "$config_file"
        fi
        echo "${key} ${value}" >> "$config_file"
        log_info "Kitty config: '${key}' adicionada com valor '${value}'"
    fi
}

# --- Configuração do Kitty ---
configure_kitty() {
    log_info "Configurando o Kitty..."
    local kitty_conf_file="$HOME/.config/kitty/kitty.conf"
    local font_name="CodeNewRoman Nerd Font" # Verifique este nome com 'fc-list'

    # As aspas duplas em torno de "${font_name}" são importantes se o nome da fonte tiver espaços.
    # A função configure_kitty_option as manipula corretamente para o arquivo.
    configure_kitty_option "$kitty_conf_file" "font_family" "\"${font_name}\"" "Fonte"
    configure_kitty_option "$kitty_conf_file" "font_size" "12.0" "Fonte"

    configure_kitty_option "$kitty_conf_file" "initial_window_width" "800" "Tamanho da Janela"
    configure_kitty_option "$kitty_conf_file" "initial_window_height" "600" "Tamanho da Janela"
    configure_kitty_option "$kitty_conf_file" "remember_window_size" "yes" "Tamanho da Janela"

    configure_kitty_option "$kitty_conf_file" "window_margin_width" "10" "Margens e Bordas"
    configure_kitty_option "$kitty_conf_file" "single_window_margin_width" "0" "Margens e Bordas"
    configure_kitty_option "$kitty_conf_file" "window_border_width" "1pt" "Margens e Bordas"
    
    configure_kitty_option "$kitty_conf_file" "enabled_layouts" "Tall,*" "Layouts"

    configure_kitty_option "$kitty_conf_file" "tab_bar_style" "powerline" "Barra de Abas"
    configure_kitty_option "$kitty_conf_file" "tab_powerline_style" "slanted" "Barra de Abas"

    log_info "Configuração do Kitty concluída."
    log_info "Recarregue a configuração do Kitty (Ctrl+Shift+F5) ou reinicie-o para aplicar."
}

# --- Remoção do GNOME Terminal ---
remove_gnome_terminal() {
    log_info "Verificando se o GNOME Terminal está instalado..."
    if dnf list installed gnome-terminal &>/dev/null; then
        log_info "Removendo GNOME Terminal..."
        sudo dnf remove -y gnome-terminal
        log_info "GNOME Terminal removido."
    else
        log_info "GNOME Terminal não está instalado. Pulando remoção."
    fi
}

# --- Execução Principal ---
main() {
    log_info "Iniciando script de finalização (finalizacao.sh)..."
    log_info "Este script deve ser executado APÓS o script principal e um logout/login, DENTRO do Kitty."

    configure_kitty
    remove_gnome_terminal

    echo ""
    log_info "-------------------------------------------------------"
    log_info "Script de finalização concluído!"
    log_info "-------------------------------------------------------"
    echo "Lembre-se:"
    echo "  - As configurações do Kitty podem exigir recarregar (Ctrl+Shift+F5) ou reiniciar o Kitty."
    echo "Seu ambiente deve estar pronto."
    log_info "-------------------------------------------------------"
}

# Executar a função principal
main

exit 0
