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

    log_info "Criando diretório de configuração do Kitty em ${kitty_config_dir} (se não existir)..."
    mkdir -p "$kitty_config_dir"

    log_info "Criando/Substituindo arquivo de configuração principal: $kitty_conf_file..."
    # Usamos 'EOF' com aspas para evitar expansão de variáveis dentro do here-document
    cat << 'EOF' > "$kitty_conf_file"
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

# font
font_family        Code New Roman Nerd Font
bold_font          auto
italic_font        auto
bold_italic_font   auto
font_size 12.0

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

    if [ $? -eq 0 ]; then
        log_info "$kitty_conf_file criado/substituído com sucesso."
    else
        log_error "Falha ao criar/substituir $kitty_conf_file."
        return 1
    fi

    log_info "Criando/Substituindo arquivo de tema Kitty: $kitty_theme_file..."
    cat << 'EOF' > "$kitty_theme_file"
# Selection Colors
selection_foreground     #ebdbb2
selection_background     #d65d0e

# Window border Colors
active_border_color      #8ec07c
inactive_border_color    #665c54

# Kitty tabs colors
active_tab_foreground    #ebdbb2
active_tab_background    #458588
inactive_tab_foreground  #ebdbb2
inactive_tab_background  #8ec07c

# Basic color
background               #1d2021
foreground               #ebdbb2

# 16 main colors
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

# Cursor colors
cursor                   #bdae93
cursor_text_color        #665c54

# Url color
url_color                #458588
EOF

    if [ $? -eq 0 ]; then
        log_info "$kitty_theme_file criado/substituído com sucesso."
    else
        log_error "Falha ao criar/substituir $kitty_theme_file."
        return 1
    fi

    log_info "Configuração do Kitty concluída."
    log_info "Recarregue a configuração do Kitty (Ctrl+Shift+F5) ou reinicie-o para aplicar."
}

# --- Remoção do GNOME Terminal ---
remove_gnome_terminal() {
    log_info "Verificando se o GNOME Terminal está instalado..."
    if dnf list installed gnome-terminal &>/dev/null; then
        log_info "Removendo GNOME Terminal..."
        # Adicionar verificação se o usuário é root ou tem sudo, ou se o script é executado com sudo
        if [[ $EUID -ne 0 ]]; then
            sudo dnf remove -y gnome-terminal
        else
            dnf remove -y gnome-terminal
        fi
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
    echo "  - As configurações do Kitty devem ter sido aplicadas. Se não, recarregue (Ctrl+Shift+F5) ou reinicie o Kitty."
    echo "Seu ambiente deve estar pronto."
    log_info "-------------------------------------------------------"
}

# Executar a função principal
main

exit 0
