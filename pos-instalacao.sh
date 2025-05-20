#!/bin/bash
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

# --- Funções de Instalação e Configuração ---

# 0. Pré-requisitos, atualização do sistema e configuração do Flathub
install_prerequisites_and_update() {
    log_info "Instalando dependências básicas (curl, git, util-linux-user, unzip, tar, flatpak)..."
    sudo dnf install -y curl git util-linux-user unzip tar flatpak

    log_info "Atualizando o sistema..."
    sudo dnf update -y

    log_info "Configurando repositório Flathub (se ainda não estiver configurado)..."
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

# 1. Remover todos os jogos (opcional, comentado na main)
remove_games() {
    log_info "Removendo jogos..."
    sudo dnf remove -y gnome-mines gnome-sudoku aisleriot quadrapassel iagno lightsoff \
                       swell-foop five-or-more four-in-a-row hitori gnome-klotski \
                       gnome-robots gnome-tetravex tali || log_warn "Alguns jogos não foram encontrados ou já removidos."
}

# 2. Remover tmux (se instalado)
remove_tmux() {
    log_info "Removendo tmux (se instalado)..."
    sudo dnf remove -y tmux || log_warn "tmux não encontrado ou já removido."
}

# 3. Instalar Zsh e Oh My Zsh
install_zsh_ohmyzsh() {
    log_info "Instalando Zsh..."
    sudo dnf install -y zsh

    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_info "Oh My Zsh já está instalado. Pulando instalação."
    else
        log_info "Instalando Oh My Zsh..."
        export ZSH_DISABLE_COMPFIX="true"
        export RUNZSH=no CHSH=no
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    log_info "Configurando Zsh como shell padrão para o usuário atual ($USER)..."
    if command -v zsh &> /dev/null; then
        if [ "$(basename "$SHELL")" != "zsh" ]; then
            sudo chsh -s "$(which zsh)" "$USER"
            log_info "Shell padrão alterado para Zsh para o usuário $USER."
            log_info "IMPORTANTE: A mudança terá efeito completo após logout/login ou reinicialização."
        else
            log_info "Zsh já é o shell padrão para o usuário $USER."
        fi
    else
        log_error "Zsh não encontrado. Não foi possível definir como shell padrão."
    fi
}

# 4. Instalar Kitty
install_kitty() {
    log_info "Instalando Kitty..."
    sudo dnf install -y kitty
}

# 5. Instalar Zellij
install_zellij() {
    local arch
    arch=$(uname -m)
    local zellij_bin_name="zellij"
    local zellij_archive_name_pattern
    local zellij_download_url
    local install_dir="/usr/local/bin"
    local tmp_dir

    log_info "Verificando arquitetura para Zellij..."
    case "$arch" in
        "x86_64")
            zellij_archive_name_pattern="zellij-x86_64-unknown-linux-musl.tar.gz"
            ;;
        "aarch64")
            zellij_archive_name_pattern="zellij-aarch64-unknown-linux-musl.tar.gz"
            ;;
        *)
            log_error "Arquitetura $arch não tem um binário Zellij pré-compilado comum listado neste script."
            log_error "Por favor, instale Zellij manualmente de https://github.com/zellij-org/zellij/releases"
            return 1
            ;;
    esac

    zellij_download_url="https://github.com/zellij-org/zellij/releases/latest/download/${zellij_archive_name_pattern}"

    log_info "Instalando/Atualizando para a versão mais recente do Zellij..."

    tmp_dir=$(mktemp -d -t zellij-install-XXXXXX)
    trap 'rm -rf -- "$tmp_dir"' RETURN # Garante limpeza do diretório temporário

    log_info "Baixando Zellij de ${zellij_download_url} para ${tmp_dir}..."
    if curl -LfsS "$zellij_download_url" -o "$tmp_dir/zellij.tar.gz"; then
        log_info "Zellij baixado. Extraindo..."
        if tar -xzf "$tmp_dir/zellij.tar.gz" -C "$tmp_dir"; then
            local downloaded_zellij_path="$tmp_dir/$zellij_bin_name"

            if [ -f "$downloaded_zellij_path" ]; then
                chmod +x "$downloaded_zellij_path"
                local downloaded_version
                downloaded_version=$("$downloaded_zellij_path" --version | awk '{print $2}')

                if command -v $zellij_bin_name &>/dev/null; then
                    local installed_version
                    installed_version=$($zellij_bin_name --version | awk '{print $2}')
                    if [[ "$installed_version" == "$downloaded_version" ]]; then
                        log_info "Zellij versão $installed_version já é a mais recente. Pulando instalação."
                        return 0
                    else
                        log_warn "Zellij $installed_version instalado. Atualizando para $downloaded_version."
                    fi
                else
                    log_info "Instalando Zellij versão $downloaded_version."
                fi

                log_info "Instalando binário do Zellij em ${install_dir}..."
                if sudo install -m 0755 "$downloaded_zellij_path" "${install_dir}/"; then
                    log_info "Zellij $downloaded_version instalado com sucesso em ${install_dir}/${zellij_bin_name}"
                    "${install_dir}/${zellij_bin_name}" --version
                else
                    log_error "Falha ao instalar o binário do Zellij usando 'sudo install'."
                    return 1
                fi
            else
                log_error "Binário '$zellij_bin_name' não encontrado no arquivo baixado após extração."
                return 1
            fi
        else
            log_error "Falha ao extrair o arquivo Zellij (zellij.tar.gz). Pode estar corrompido."
            return 1
        fi
    else
        log_error "Falha ao baixar Zellij. Verifique a URL, sua conexão ou se a versão/arquitetura é válida."
        return 1
    fi
    log_info "Instalação/Atualização do Zellij concluída."
}

# 6. Instalar Neovim e LazyVim
install_neovim_lazyvim() {
    log_info "Instalando Neovim..."
    sudo dnf install -y neovim python3-neovim

    log_info "Instalando LazyVim..."
    if [ ! -d "$HOME/.config/nvim" ]; then
        log_info "Clonando LazyVim starter..."
        git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
        log_info "LazyVim starter clonado para $HOME/.config/nvim."
    else
        log_info "Diretório $HOME/.config/nvim já existe. Pulando clone do LazyVim."
    fi
}

# 7. Garantir que o GCC e ferramentas de desenvolvimento estejam instaladas
install_dev_tools() {
    log_info "Garantindo que GCC e ferramentas de desenvolvimento estejam instaladas..."
    local dnf_version_major
    dnf_version_major=$(dnf --version 2>/dev/null | head -n1 | cut -d' ' -f1 | cut -d'.' -f1)
    local group_install_cmd

    if [[ "$dnf_version_major" == "5" ]]; then
        group_install_cmd="sudo dnf group install -y"
    elif [[ "$dnf_version_major" =~ ^[0-4]$ ]]; then
        group_install_cmd="sudo dnf groupinstall -y"
    else
        log_warn "Não foi possível determinar a versão do DNF. Tentando 'sudo dnf group install -y' (DNF5) como padrão."
        group_install_cmd="sudo dnf group install -y"
    fi

    log_info "Tentando instalar o grupo 'Development Tools' usando: ${group_install_cmd} \"Development Tools\""
    if ${group_install_cmd} "Development Tools"; then
        log_info "Comando '${group_install_cmd} \"Development Tools\"' executado com sucesso ou o grupo já estava instalado."
    else
        log_warn "Falha ao executar '${group_install_cmd} \"Development Tools\"'."
        log_info "Tentando instalar 'gcc' e 'gcc-c++' explicitamente como fallback..."
        if sudo dnf install -y gcc gcc-c++; then
            log_info "GCC e G++ (compilador C++) instalados explicitamente com sucesso."
        else
            log_error "Falha ao instalar 'gcc' e 'gcc-c++' explicitamente. Verifique os logs do DNF."; return 1
        fi
    fi

    log_info "Verificando a presença do compilador GCC..."
    if command -v gcc &>/dev/null; then
        log_info "GCC encontrado: $(gcc --version | head -n1)"
    else
        log_error "GCC não foi encontrado mesmo após as tentativas de instalação."; return 1
    fi

    log_info "Verificando a presença do 'make'..."
    if command -v make &>/dev/null; then
        log_info "'make' encontrado: $(make --version | head -n1)"
    else
        log_warn "'make' não encontrado. Se necessário, instale com: sudo dnf install make"
    fi
    log_info "Instalação/verificação de ferramentas de desenvolvimento concluída."
}

# 8. Remover aplicativos específicos do GNOME
remove_gnome_apps() {
    log_info "Removendo aplicativos específicos do GNOME..."
    # gnome-text-editor foi removido desta lista
    sudo dnf remove -y gnome-contacts gnome-weather gnome-maps gnome-boxes simple-scan \
                       totem rhythmbox gnome-tour gnome-characters gnome-connections \
                       evince loupe gnome-logs gnome-abrt \
                       gnome-system-monitor gnome-clocks gnome-calendar gnome-camera || log_warn "Alguns aplicativos GNOME não foram encontrados ou já removidos."
    log_info "Removendo LibreOffice..."
    sudo dnf remove -y libreoffice* || log_warn "LibreOffice não encontrado ou já removido."
}

# 9. Instalar SDKMAN!
install_sdkman() {
    log_info "Verificando SDKMAN!..."
    if [ -d "$HOME/.sdkman" ]; then
        log_info "SDKMAN! já está instalado em $HOME/.sdkman. Pulando instalação."
    else
        log_info "Instalando SDKMAN!..."
        curl -s "https://get.sdkman.io?rcupdate=false" | bash
        log_info "SDKMAN! instalado."
        log_info "Para usar o SDKMAN! na sessão atual, execute: source \"\$HOME/.sdkman/bin/sdkman-init.sh\""
    fi
}

# 10. Instalar Maven
install_maven() {
    log_info "Instalando Maven via dnf..."
    sudo dnf install -y maven
    log_info "Maven instalado a partir dos repositórios do Fedora."
}

# 11. Instalar Nerd Font (CodeNewRoman)
install_nerd_fonts() {
    local font_name="CodeNewRoman"
    # ATUALIZE ESTA TAG SE NECESSÁRIO PARA A ÚLTIMA VERSÃO DA FONTE
    local latest_nerd_font_release_tag="v3.4.0"
    local font_zip_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${latest_nerd_font_release_tag}/${font_name}.zip"
    local user_fonts_dir="$HOME/.local/share/fonts"
    local tmp_dir
    tmp_dir=$(mktemp -d -t nerd-font-install-XXXXXX)
    trap 'rm -rf -- "$tmp_dir"' RETURN

    log_info "Instalando Nerd Font: ${font_name}..."

    if fc-list | grep -qi "${font_name// /.*}"; then
        log_info "Fonte ${font_name} Nerd Font parece já estar instalada. Pulando."
        return 0
    fi

    mkdir -p "$user_fonts_dir"

    log_info "Baixando ${font_name}.zip de ${font_zip_url}..."
    if curl -LfsS "$font_zip_url" -o "$tmp_dir/${font_name}.zip"; then
        log_info "Descompactando fontes em $tmp_dir..."
        if unzip -qjo "$tmp_dir/${font_name}.zip" "*.ttf" "*.otf" -d "$user_fonts_dir"; then
            log_info "Fontes extraídas para $user_fonts_dir."
            log_info "Atualizando cache de fontes..."
            fc-cache -fv
            log_info "${font_name} Nerd Font instalada com sucesso."
        else
            log_error "Falha ao descompactar ${font_name}.zip. Pode estar corrompido ou não conter arquivos .ttf/.otf esperados."
        fi
    else
        log_error "Falha ao baixar ${font_name}.zip. Verifique a URL (${font_zip_url}) ou sua conexão."
    fi
    log_info "Instalação da Nerd Font concluída."
}

# 12. Instalar aplicativos Flatpak
install_flatpak_apps() {
    log_info "Instalando aplicativos Flatpak selecionados..."
    
    local flatpaks_to_install=(
        "com.bitwarden.desktop"
        "com.jetbrains.IntelliJ-IDEA-Ultimate"
    )

    for app_id in "${flatpaks_to_install[@]}"; do
        log_info "Tentando instalar/atualizar $app_id via Flatpak..."
        # flatpak install lida com apps já instalados (atualiza ou não faz nada)
        if flatpak install flathub "$app_id" -y; then # Instala por usuário
            log_info "$app_id instalado/atualizado com sucesso."
        else
            log_error "Falha ao instalar $app_id via Flatpak. Tente manualmente: flatpak install flathub $app_id"
        fi
    done
    log_info "Instalação de aplicativos Flatpak concluída."
}

# --- Execução Principal ---
main() {
    install_prerequisites_and_update
    
    # Remoções
    # remove_games
    remove_gnome_apps
    remove_tmux

    # Ambiente de Desenvolvimento e Terminal
    install_zsh_ohmyzsh
    install_kitty
    install_zellij
    install_nerd_fonts
    install_neovim_lazyvim
    install_dev_tools
    
    # Ferramentas de Desenvolvimento Adicionais
    install_sdkman
    install_maven

    # Aplicativos GUI Adicionais
    install_flatpak_apps

    echo ""
    echo "-------------------------------------------------------"
    log_info "Configuração inicial concluída!"
    echo "-------------------------------------------------------"
    local font_display_name="CodeNewRoman Nerd Font"
    echo "Próximos Passos:"
    echo "1. FAÇA LOGOUT E LOGIN NOVAMENTE (ou reinicie o sistema) para que todas as alterações tenham efeito:"
    echo "   - Zsh como shell ativo e SDKMAN! carregado."
    echo "   - Fontes reconhecidas e Zellij no PATH global."
    echo "   - Aplicativos Flatpak completamente integrados."
    echo "2. Abra o terminal Kitty e configure-o para usar a fonte '${font_display_name}'."
    echo "3. No Kitty, inicie Zellij com: zellij"
    echo "4. Abra o Neovim (nvim) pela primeira vez para que o LazyVim configure os plugins."
    echo "5. Abra os aplicativos Flatpak (Bitwarden, IntelliJ IDEA Ultimate) e fixe-os no seu painel/dock manualmente, se desejar."
    echo "6. Use SDKMAN! (ex: 'sdk list java', 'sdk install java VERSAO_DESEJADA')."
    echo "-------------------------------------------------------"
}

# Executar a função principal
main

exit 0
