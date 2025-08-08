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

# --- Configuração do Kitty ---
configure_kitty() {
    log_info "Configurando o Kitty..."
    local kitty_config_dir="$HOME/.config/kitty"
    local kitty_conf_file="$kitty_config_dir/kitty.conf"
    local kitty_theme_file="$kitty_config_dir/GruvBox_DarkHard.conf"

    log_info "Criando diretório de configuração do Kitty em ${kitty_config_dir}..."
    mkdir -p "$kitty_config_dir"

    log_info "Criando arquivo de configuração principal: $kitty_conf_file..."
    # 'set -e' já garante que o script sairá em caso de falha no 'cat'.
    cat << 'EOF' > "$kitty_conf_file"
# --- Tema e Aparência ---
# Tema importado de um arquivo separado.
include GruvBox_DarkHard.conf

# Opacidade do fundo (1.0 = totalmente opaco).
background_opacity 1.0

# --- Fonte ---
# ## REVISADO ##
# A fonte 'CodeNewRoman Nerd Font' foi instalada pelo script anterior.
font_family        CodeNewRoman Nerd Font
bold_font          auto
italic_font        auto
bold_italic_font   auto
font_size          12.0

# Atalho para resetar o tamanho da fonte.
map ctrl+shift+backspace change_font_size all 0

# --- Cursor ---
cursor_shape     block
# Desativa o piscar do cursor para economizar recursos.
cursor_blink_interval 0

# --- Comportamento do Terminal ---
# Número de linhas para guardar no histórico de scroll.
scrollback_lines 5000

# Desativa o sino de áudio do terminal.
enable_audio_bell no

# Integração com o shell para funcionalidades avançadas.
shell_integration no-cursor

# Configuração de servidor gráfico (Wayland/X11).
# Comentado para permitir que o Kitty autodetecte. É a opção mais segura no Fedora.
# Descomente e defina como 'x11' ou 'wayland' apenas se encontrar problemas.
# linux_display_server x11

# --- Layout e Janelas ---
# Layouts de janela habilitados. 'tall' é um bom padrão.
enabled_layouts tall

# Gerenciamento de janelas (splits).
map ctrl+shift+enter new_window_with_cwd
map ctrl+shift+]     next_window
map ctrl+shift+[     previous_window

# Gerenciamento de abas.
tab_bar_style      powerline
tab_powerline_style slanted
map ctrl+shift+t     new_tab_with_cwd
map ctrl+shift+right next_tab
map ctrl+shift+left  previous_tab
map ctrl+shift+q     close_tab
EOF

    log_info "Criando arquivo de tema do Kitty: $kitty_theme_file..."
    # 'set -e' também se aplica aqui.
    cat << 'EOF' > "$kitty_theme_file"
# Tema: Gruvbox Dark Hard
# Cores da Seleção
selection_foreground     #ebdbb2
selection_background     #d65d0e

# Cores da Borda da Janela
active_border_color      #8ec07c
inactive_border_color    #665c54

# Cores das Abas
active_tab_foreground    #ebdbb2
active_tab_background    #458588
inactive_tab_foreground  #ebdbb2
inactive_tab_background  #8ec07c

# Cores Básicas
background               #1d2021
foreground               #ebdbb2

# 16 Cores Principais
color0                   #3c3836
color1                   #cc241d
color2                   #98971a
color3                   #d79921
color4                   #458588
color5                   #b16286
color6                   #689d6a
color7                   #a89984
color8                   #928374
color9                   #fb4934
color10                  #b8bb26
color11                  #fabd2f
color12                  #83a598
color13                  #d3869b
color14                  #8ec07c
color15                  #fbf1c7

# Cores do Cursor
cursor                   #bdae93
cursor_text_color        #665c54

# Cor da URL
url_color                #458588
EOF

    log_info "Configuração do Kitty concluída."
    log_info "As alterações serão aplicadas na próxima vez que o Kitty for iniciado."
}

# --- Aviso sobre a Remoção do GNOME Terminal (Ação Manual Recomendada) ---
warn_about_gnome_terminal_removal() {
    log_info "Verificando a presença do GNOME Terminal..."
    if dnf list installed gnome-terminal &>/dev/null; then
        log_warn "------------------------------------------------------------------"
        log_warn "AVISO DE SEGURANÇA: O GNOME Terminal está instalado."
        log_warn "Não é recomendado remover o terminal padrão do sistema (gnome-terminal)."
        log_warn "Ele serve como um 'fallback' seguro caso o Kitty não inicie por algum motivo."
        log_warn "Se você tem certeza de que deseja removê-lo, edite este script e descomente a linha abaixo."
        # Se tiver certeza, descomente a linha a seguir para remover o GNOME Terminal:
        # sudo dnf remove -y gnome-terminal
        log_warn "------------------------------------------------------------------"
    else
        log_info "GNOME Terminal não está instalado. Nenhuma ação necessária."
    fi
}

# --- Execução Principal ---
main() {
    log_info "Iniciando script de finalização e configuração..."
    log_info "Este script deve ser executado APÓS uma reinicialização do sistema."

    configure_kitty
    warn_about_gnome_terminal_removal

    echo ""
    log_info "-------------------------------------------------------"
    log_info "Script de finalização concluído!"
    log_info "-------------------------------------------------------"
    echo "Resumo das Ações:"
    echo "  - As configurações do Kitty foram salvas em ~/.config/kitty/."
    echo "  - Você foi AVISADO sobre os riscos de remover o GNOME Terminal."
    echo ""
    echo "Próximo Passo:"
    echo "  - FECHE e REABRA o terminal Kitty para que as novas configurações e tema sejam aplicados."
    echo "Seu ambiente de terminal personalizado deve estar pronto."
    log_info "-------------------------------------------------------"
}

# Executar a função principal
main

exit 0
