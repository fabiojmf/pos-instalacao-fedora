#!/usr/bin/env zsh
set -e

# --- Funções de Log ---
log_info() { echo "INFO: $1"; }
log_warn() { echo "WARN: $1"; }
log_error() { echo "ERROR: $1" >&2; }

# --- Configuração do Kitty ---
configure_kitty() {
    log_info "Configurando o Kitty..."
    local kitty_config_dir="$HOME/.config/kitty"
    local kitty_conf_file="$kitty_config_dir/kitty.conf"
    local kitty_theme_file="$kitty_config_dir/GruvBox_DarkHard.conf"

    mkdir -p "$kitty_config_dir"

    log_info "Criando arquivo de configuração principal: $kitty_conf_file..."
    cat << 'EOF' > "$kitty_conf_file"
# themes
include GruvBox_DarkHard.conf
#include Wryan.conf
#include VSCode_Dark.conf

# terminal opacity and blur
background_opacity 1.0
background_blur 1

# advance
term xterm-kitty

# terminal bell
enable_audio_bell no

# os specific tweaks (Gnome window decoration for wayland)
linux_display_server x11

# --- Fonte ---
font_family        MesloLGS NF
bold_font          auto
italic_font        auto
bold_italic_font   auto
font_size          11.0

# font size management
map ctrl+shift+backspace change_font_size all 0

# cursor customization
# block / beam / underline
cursor_shape block
cursor_blink_interval 0
cursor_stop_blinking_after 0
shell_integration no-cursor

# scrollback
scrollback_lines 5000
wheel_scroll_multiplier 3.0

# mouse
mouse_hide_wait -1

# window layout
remember_window_size  no
initial_window_width  1200
initial_window_height 750
window_border_width 1.5pt
enabled_layouts tall
window_padding_width 0
window_margin_width 2
hide_window_decorations no

# window management
map ctrl+shift+enter new_window
map ctrl+shift+] next_window
map ctrl+shift+[ previous_window

# layout management
map ctrl+shift+l next_layout
map ctrl+alt+r goto_layout tall
map ctrl+alt+s goto_layout stack

# tab bar customization
tab_bar_style powerline
tab_powerline_style slanted
tab_bar_edge bottom
tab_bar_align left
active_tab_font_style   bold
inactive_tab_font_style normal

# tab management
map ctrl+shift+t new_tab
map ctrl+shift+right next_tab
map ctrl+shift+left previous_tab
map ctrl+shift+q close_tab
EOF

    log_info "Criando arquivo de tema: $kitty_theme_file..."
    cat << 'EOF' > "$kitty_theme_file"
# Tema: Gruvbox Dark Hard

# Cores da Seleção
selection_foreground #ebdbb2
selection_background #d65d0e

# Cores da Borda da Janela
active_border_color #8ec07c
inactive_border_color #665c54

# Cores das Abas
active_tab_foreground #ebdbb2
active_tab_background #458588
inactive_tab_foreground #ebdbb2
inactive_tab_background #8ec07c

# Cores Básicas
background #1d2021
foreground #ebdbb2

# 16 Cores Principais
color0  #3c3836
color1  #cc241d
color2  #98971a
color3  #d79921
color4  #458588
color5  #b16286
color6  #689d6a
color7  #a89984
color8  #928374
color9  #fb4934
color10 #b8bb26
color11 #fabd2f
color12 #83a598
color13 #d3869b
color14 #8ec07c
color15 #fbf1c7

# Cores do Cursor
cursor #bdae93
cursor_text_color #665c54

# Cor da URL
url_color #458588
EOF

    log_info "Configuração do Kitty concluída."
}

# --- Aviso sobre a Remoção do GNOME Terminal ---
warn_about_gnome_terminal_removal() {
    log_info "Verificando a presença do GNOME Terminal..."
    if dnf list installed gnome-terminal &>/dev/null; then
        log_warn "------------------------------------------------------------------"
        log_warn "AVISO: O GNOME Terminal está instalado."
        log_warn "Recomenda-se mantê-lo como fallback caso o Kitty não inicie."
        log_warn "Para remover, descomente a linha abaixo neste script."
        # sudo dnf remove -y gnome-terminal
        log_warn "------------------------------------------------------------------"
    else
        log_info "GNOME Terminal não está instalado."
    fi
}

# --- Execução Principal ---
main() {
    log_info "Iniciando script de finalização..."
    log_info "Este script deve ser executado APÓS reinicialização do sistema."

    configure_kitty
    warn_about_gnome_terminal_removal

    echo ""
    log_info "-------------------------------------------------------"
    log_info "Script de finalização concluído!"
    log_info "-------------------------------------------------------"
    echo "Resumo:"
    echo "  - Configurações do Kitty salvas em ~/.config/kitty/"
    echo "  - Fonte: MesloLGS NF (11pt)"
    echo "  - Tema: Gruvbox Dark Hard"
    echo ""
    echo "Próximo Passo:"
    echo "  - Feche e reabra o Kitty para aplicar as configurações."
    log_info "-------------------------------------------------------"
}

main
exit 0
