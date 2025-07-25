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
    log_info "Verificando e configurando SDKMAN!..."
    local sdkman_install_dir="$HOME/.sdkman"

    if [ ! -d "$sdkman_install_dir" ]; then
        log_info "SDKMAN! não encontrado. Instalando..."
        if curl -s "https://get.sdkman.io" | bash; then
            log_info "Script de instalação do SDKMAN! executado."
            if [ ! -d "$sdkman_install_dir" ]; then
                 log_error "Falha na instalação do SDKMAN!: diretório $sdkman_install_dir não foi criado."
                 return 1
            fi
            log_info "SDKMAN! instalado com sucesso em $sdkman_install_dir."
        else
            log_error "Falha ao baixar ou executar o script de instalação do SDKMAN!."
            return 1
        fi
    else
        log_info "SDKMAN! já está instalado em $sdkman_install_dir."
    fi

    local sdkman_rc_config_lines=(
        ""
        "#SDKMAN!"
        "export SDKMAN_DIR=\"$sdkman_install_dir\""
        "[[ -s \"${sdkman_install_dir}/bin/sdkman-init.sh\" ]] && source \"${sdkman_install_dir}/bin/sdkman-init.sh\""
    )

    local rc_files_to_check=()
    if [ -f "$HOME/.zshrc" ] || command -v zsh >/dev/null 2>&1; then
        if [ ! -f "$HOME/.zshrc" ]; then
            log_info "Criando $HOME/.zshrc pois Zsh está instalado mas o arquivo não existe."
            touch "$HOME/.zshrc"
        fi
        rc_files_to_check+=("$HOME/.zshrc")
    fi
    if [ -f "$HOME/.bashrc" ] || [ -n "$BASH_VERSION" ]; then
         if [ ! -f "$HOME/.bashrc" ]; then
            log_info "Criando $HOME/.bashrc pois o arquivo não existe."
            touch "$HOME/.bashrc"
        fi
        rc_files_to_check+=("$HOME/.bashrc")
    fi
    
    local modified_rc_count=0
    for rc_file in "${rc_files_to_check[@]}"; do
        if ! grep -qF -- "sdkman-init.sh" "$rc_file"; then
            log_info "Adicionando configuração do SDKMAN! ao arquivo $rc_file..."
            printf "%s\n" "${sdkman_rc_config_lines[@]}" >> "$rc_file"
            log_info "Configuração do SDKMAN! adicionada a $rc_file."
            modified_rc_count=$((modified_rc_count + 1))
        else
            log_info "SDKMAN! já parece estar configurado em $rc_file."
        fi
    done

    if [ "$modified_rc_count" -gt 0 ]; then
        log_info "Configuração do SDKMAN! nos arquivos RC concluída."
        log_info "IMPORTANTE: SDKMAN! estará disponível em novas sessões de terminal (após logout/login ou reinicialização)."
    fi
    log_info "Verificação/Configuração do SDKMAN! finalizada."
}

# 10. Instalar Maven
install_maven() {
    log_info "Instalando Maven via dnf..."
    sudo dnf install -y maven
    log_info "Maven instalado a partir dos repositórios do Fedora."
}

# 11. Instalar podman-compose
install_podman_compose() {
    log_info "Instalando podman-compose via dnf..."

    if sudo dnf install -y podman-compose; then
        log_info "podman-compose instalado com sucesso via dnf."
        if command -v podman-compose &>/dev/null; then
            log_info "podman-compose encontrado no PATH."
            podman-compose --version
        else
            # Isso seria inesperado se o dnf install for bem-sucedido
            log_warn "podman-compose foi instalado via dnf, mas 'command -v podman-compose' falhou."
        fi
    else
        log_error "Falha ao instalar podman-compose via dnf."
        return 1
    fi
    log_info "Instalação do podman-compose concluída."
}

# 12. Instalar Fonte (CamingoCode) - ATUALIZADO
install_camingocode_font() {
    local font_name="CamingoCode"
    local font_zip_url="https://janfromm.de/typefaces/camingocode/camingocode.zip"
    local user_fonts_dir="$HOME/.local/share/fonts"
    local tmp_dir
    tmp_dir=$(mktemp -d -t font-install-XXXXXX)
    trap 'rm -rf -- "$tmp_dir"' RETURN

    log_info "Instalando Fonte: ${font_name}..."
    
    # Verifica se algum arquivo de fonte com "Camingo" no nome já existe
    if fc-list | grep -qi "Camingo"; then
        log_info "Fonte ${font_name} parece já estar instalada. Pulando."
        return 0
    fi

    mkdir -p "$user_fonts_dir"

    log_info "Baixando ${font_name}.zip de ${font_zip_url}..."
    if curl -LfsS "$font_zip_url" -o "$tmp_dir/${font_name}.zip"; then
        log_info "Descompactando fontes em $tmp_dir..."
        # O zip da CamingoCode contém um diretório, então descompactamos para o diretório de fontes do usuário
        if unzip -qj "$tmp_dir/${font_name}.zip" -d "$user_fonts_dir"; then
            log_info "Fontes extraídas para $user_fonts_dir."
            log_info "Atualizando cache de fontes..."
            fc-cache -fv
            log_info "${font_name} instalada com sucesso."
        else
            log_error "Falha ao descompactar ${font_name}.zip. Pode estar corrompido ou ter uma estrutura inesperada."
        fi
    else
        log_error "Falha ao baixar ${font_name}.zip. Verifique a URL (${font_zip_url}) ou sua conexão."
    fi
    log_info "Instalação da Fonte concluída."
}

# 13. Instalar npm (se não estiver presente) - NOVO
install_npm() {
    log_info "Verificando e instalando npm (Node Package Manager)..."
    if command -v npm &> /dev/null; then
        log_info "npm já está instalado."
        npm --version
    else
        log_info "npm não encontrado. Tentando instalar via dnf..."
        # No Fedora, o pacote 'npm' instala o 'nodejs' como dependência.
        # Esta é a maneira correta de garantir que ambos estejam presentes.
        if sudo dnf install -y npm; then
            log_info "npm instalado com sucesso."
            if command -v npm &> /dev/null; then
                npm --version
            else
                log_error "A instalação do npm via dnf foi concluída, mas o comando 'npm' ainda não foi encontrado no PATH."
                return 1
            fi
        else
            log_error "Falha ao instalar o npm via dnf. Verifique os logs."
            return 1
        fi
    fi
    log_info "Instalação/verificação do npm concluída."
}

# 14. Instalar aplicativos Flatpak
install_flatpak_apps() {
    log_info "Instalando aplicativos Flatpak selecionados..."
    
    local flatpaks_to_install=(
        "com.bitwarden.desktop"
        "com.jetbrains.IntelliJ-IDEA-Ultimate"
    )

    for app_id in "${flatpaks_to_install[@]}"; do
        log_info "Tentando instalar/atualizar $app_id via Flatpak..."
        if flatpak install flathub "$app_id" -y; then
            log_info "$app_id instalado/atualizado com sucesso."
        else
            log_error "Falha ao instalar $app_id via Flatpak. Tente manualmente: flatpak install flathub $app_id"
        fi
    done
    log_info "Instalação de aplicativos Flatpak concluída."
}

# 15. Instalar Drivers da NVIDIA (para placas compatíveis)
install_nvidia_drivers() {
    log_info "Verificando a presença de uma placa de vídeo NVIDIA..."
    if ! lspci | grep -qi "NVIDIA"; then
        log_info "Nenhuma placa NVIDIA detectada. Pulando instalação dos drivers."
        return 0
    fi

    log_warn "Placa NVIDIA detectada. Preparando para instalar os drivers proprietários."
    log_warn "IMPORTANTE: Isso requer a instalação dos repositórios RPM Fusion."

    # Passo 1: Instalar repositórios RPM Fusion (Free e Non-free)
    log_info "Instalando repositórios RPM Fusion..."
    if ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
        sudo dnf install -y \
            "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
            "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
        log_info "Repositórios RPM Fusion instalados. Atualizando metadados do dnf..."
        sudo dnf group update core -y # Sincroniza os metadados do novo repositório
    else
        log_info "Repositórios RPM Fusion já parecem estar instalados."
    fi

    # Passo 2: Instalar os drivers da NVIDIA via akmod
    # Adicionamos 'xorg-x11-drv-nvidia-cuda' para suporte a CUDA, muito útil para a RTX 3060
    log_info "Instalando os drivers da NVIDIA (akmod-nvidia e suporte a CUDA)..."
    if sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda --enablerepo='rpmfusion-nonfree*'; then
        log_info "Pacotes de driver NVIDIA instalados com sucesso."
    else
        log_error "Falha ao instalar os pacotes do driver NVIDIA. Verifique os logs do DNF."
        return 1
    fi

    # Passo 3: Avisos cruciais sobre o pós-instalação
    log_warn "Aguarde alguns minutos! O sistema está compilando o módulo do kernel (akmod) em segundo plano."
    log_warn "Uma reinicialização é NECESSÁRIA para carregar o novo driver."
    log_warn "ATENÇÃO AO SECURE BOOT:"
    log_warn "Se você usa Secure Boot, na próxima reinicialização, uma tela azul (MOK Manager) aparecerá."
    log_warn "Você DEVE selecionar 'Enroll MOK' ou 'Enroll key', confirmar e inserir a senha que você usa para o sudo/login quando solicitado."
    log_warn "Se você ignorar este passo no Secure Boot, o sistema pode não carregar a interface gráfica."
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
    install_neovim_lazyvim
    install_dev_tools

    # Drivers de Hardware
    install_nvidia_drivers
    
    # Ferramentas de Desenvolvimento Adicionais
    install_sdkman
    install_maven
    install_podman_compose
    install_npm # Adicionado para garantir que o npm esteja instalado
    
    # Fontes e Aplicativos GUI
    install_camingocode_font # Função de fonte atualizada
    install_flatpak_apps

    echo ""
    echo "-------------------------------------------------------"
    log_info "Configuração inicial concluída!"
    echo "-------------------------------------------------------"
    local font_display_name="CamingoCode"
    echo "Próximos Passos CRÍTICOS:"
    echo "1. REINICIE O SISTEMA AGORA. Uma reinicialização é obrigatória para:"
    echo "   - Carregar o driver da NVIDIA recém-instalado."
    echo "   - Ativar o Zsh como seu shell padrão."
    echo "   - Carregar o SDKMAN! no novo shell."
    echo "2. ATENÇÃO - SECURE BOOT: Se você usa Secure Boot, após reiniciar, uma tela azul (MOK Management) aparecerá."
    echo "   -> Selecione 'Enroll MOK' -> 'Continue'."
    echo "   -> Confirme a chave e insira sua senha quando solicitado."
    echo "   -> Se você pular isso, sua sessão gráfica pode não iniciar!"
    echo ""
    echo "Após a reinicialização bem-sucedida:"
    echo " - Abra o terminal Kitty e configure-o para usar a fonte '${font_display_name}'."
    echo " - Inicie o Zellij com: zellij"
    echo " - Abra o Neovim (nvim) para que o LazyVim finalize a configuração."
    echo " - Verifique os aplicativos e ferramentas instalados."
    echo "-------------------------------------------------------"
}

# Executar a função principal
main

exit 0
