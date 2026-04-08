#!/bin/bash
set -e

# --- Funções de Log ---
log_info() { echo "INFO: $1"; }
log_warn() { echo "WARN: $1"; }
log_error() { echo "ERROR: $1" >&2; }

# --- Funções de Instalação e Configuração ---

# 0. Pré-requisitos, atualização do sistema e configuração do Flathub
install_prerequisites_and_update() {
    log_info "Instalando dependências básicas (curl, git, util-linux-user, unzip, tar, flatpak, jq)..."
    sudo dnf install -y curl git util-linux-user unzip tar flatpak jq

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

# 3. Instalar Zsh, Oh My Zsh e Powerlevel10k
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

    # Instalar Powerlevel10k
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [ -d "$p10k_dir" ]; then
        log_info "Powerlevel10k já está instalado. Pulando."
    else
        log_info "Instalando Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    fi

    log_info "Configurando Zsh como shell padrão para o usuário atual ($USER)..."
    if command -v zsh &> /dev/null; then
        if [ "$(basename "$SHELL")" != "zsh" ]; then
            sudo chsh -s "$(which zsh)" "$USER"
            log_info "Shell padrão alterado para Zsh. Terá efeito após logout/login ou reinicialização."
        else
            log_info "Zsh já é o shell padrão."
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
    local zellij_archive_name
    local install_dir="/usr/local/bin"
    local tmp_dir

    case "$arch" in
        "x86_64") zellij_archive_name="zellij-x86_64-unknown-linux-musl.tar.gz" ;;
        "aarch64") zellij_archive_name="zellij-aarch64-unknown-linux-musl.tar.gz" ;;
        *)
            log_error "Arquitetura $arch não suportada para Zellij."
            return 1
            ;;
    esac

    local zellij_download_url="https://github.com/zellij-org/zellij/releases/latest/download/${zellij_archive_name}"

    log_info "Instalando/Atualizando Zellij..."
    tmp_dir=$(mktemp -d -t zellij-install-XXXXXX)
    trap 'rm -rf -- "$tmp_dir"' RETURN

    if ! curl -LfsS "$zellij_download_url" -o "$tmp_dir/zellij.tar.gz"; then
        log_error "Falha ao baixar Zellij."
        return 1
    fi

    if ! tar -xzf "$tmp_dir/zellij.tar.gz" -C "$tmp_dir"; then
        log_error "Falha ao extrair Zellij."
        return 1
    fi

    local downloaded="$tmp_dir/zellij"
    if [ ! -f "$downloaded" ]; then
        log_error "Binário zellij não encontrado após extração."
        return 1
    fi

    chmod +x "$downloaded"
    local new_ver
    new_ver=$("$downloaded" --version | awk '{print $2}')

    if command -v zellij &>/dev/null; then
        local cur_ver
        cur_ver=$(zellij --version | awk '{print $2}')
        if [[ "$cur_ver" == "$new_ver" ]]; then
            log_info "Zellij $cur_ver já é a mais recente. Pulando."
            return 0
        fi
        log_warn "Atualizando Zellij de $cur_ver para $new_ver."
    fi

    sudo install -m 0755 "$downloaded" "${install_dir}/"
    log_info "Zellij $new_ver instalado em ${install_dir}/zellij"
}

# 6. Instalar Neovim e LazyVim
install_neovim_lazyvim() {
    log_info "Instalando Neovim..."
    sudo dnf install -y neovim python3-neovim

    if [ ! -d "$HOME/.config/nvim" ]; then
        log_info "Clonando LazyVim starter..."
        git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    else
        log_info "Diretório $HOME/.config/nvim já existe. Pulando clone do LazyVim."
    fi
}

# 7. Garantir que GCC e ferramentas de desenvolvimento estejam instaladas
install_dev_tools() {
    log_info "Instalando ferramentas de desenvolvimento..."
    if sudo dnf install -y @development-tools; then
        log_info "Development Tools instalado com sucesso."
    elif sudo dnf group install -y "Development Tools"; then
        log_info "Development Tools instalado via group install."
    else
        log_error "Falha ao instalar Development Tools."
        return 1
    fi

    if command -v gcc &>/dev/null; then
        log_info "GCC encontrado: $(gcc --version | head -n1)"
    else
        log_error "GCC não encontrado após instalação."
        return 1
    fi
}

# 8. Remover aplicativos específicos do GNOME e LibreOffice
remove_gnome_apps() {
    log_info "Removendo aplicativos específicos do GNOME..."
    sudo dnf remove -y gnome-contacts gnome-weather gnome-maps gnome-boxes simple-scan \
        totem rhythmbox gnome-tour gnome-characters gnome-connections \
        evince loupe gnome-logs gnome-abrt \
        gnome-system-monitor gnome-clocks gnome-calendar gnome-camera || log_warn "Alguns aplicativos GNOME não foram encontrados ou já removidos."

    log_info "Removendo LibreOffice..."
    sudo dnf remove -y libreoffice* || log_warn "LibreOffice não encontrado ou já removido."
}

# 9. Instalar SDKMAN!
install_sdkman() {
    local sdkman_dir="$HOME/.sdkman"
    if [ ! -d "$sdkman_dir" ]; then
        log_info "Instalando SDKMAN!..."
        curl -s "https://get.sdkman.io" | bash || { log_error "Falha ao instalar SDKMAN!."; return 1; }
    else
        log_info "SDKMAN! já está instalado."
    fi

    local zshrc="$HOME/.zshrc"
    [ ! -f "$zshrc" ] && touch "$zshrc"
    if ! grep -qF "sdkman-init.sh" "$zshrc"; then
        log_info "Adicionando SDKMAN! ao .zshrc..."
        {
            echo ""
            echo "#SDKMAN!"
            echo "export SDKMAN_DIR=\"$sdkman_dir\""
            echo "[[ -s \"\${SDKMAN_DIR}/bin/sdkman-init.sh\" ]] && source \"\${SDKMAN_DIR}/bin/sdkman-init.sh\""
        } >> "$zshrc"
    else
        log_info "SDKMAN! já configurado no .zshrc."
    fi
}

# 10. Instalar Maven
install_maven() {
    log_info "Instalando Maven via dnf..."
    sudo dnf install -y maven
}

# 11. Instalar podman-compose
install_podman_compose() {
    log_info "Instalando podman-compose via dnf..."
    sudo dnf install -y podman-compose || { log_error "Falha ao instalar podman-compose."; return 1; }
}

# 12. Instalar Fonte MesloLGS NF (usada pelo Powerlevel10k)
install_meslo_font() {
    local font_name="MesloLGS NF"
    local user_fonts_dir="$HOME/.local/share/fonts"

    if fc-list | grep -qi "MesloLGS NF"; then
        log_info "Fonte $font_name já está instalada. Pulando."
        return 0
    fi

    log_info "Instalando fonte $font_name..."
    mkdir -p "$user_fonts_dir"

    local base_url="https://github.com/romkatv/powerlevel10k-media/raw/master"
    local fonts=(
        "MesloLGS%20NF%20Regular.ttf"
        "MesloLGS%20NF%20Bold.ttf"
        "MesloLGS%20NF%20Italic.ttf"
        "MesloLGS%20NF%20Bold%20Italic.ttf"
    )

    for font_file in "${fonts[@]}"; do
        local decoded
        decoded=$(printf '%b' "${font_file//%/\\x}")
        if curl -LfsS "$base_url/$font_file" -o "$user_fonts_dir/$decoded"; then
            log_info "Baixada: $decoded"
        else
            log_error "Falha ao baixar: $decoded"
            return 1
        fi
    done

    fc-cache -fv
    log_info "Fonte $font_name instalada com sucesso."
}

# 13. Instalar aplicativos Flatpak (Bitwarden)
install_flatpak_apps() {
    log_info "Instalando aplicativos Flatpak..."
    local flatpaks=("com.bitwarden.desktop")

    for app_id in "${flatpaks[@]}"; do
        if flatpak list --app --columns=application | grep -q "^$app_id$"; then
            log_info "$app_id já está instalado. Pulando."
        elif flatpak install flathub "$app_id" -y; then
            log_info "$app_id instalado com sucesso."
        else
            log_error "Falha ao instalar $app_id."
        fi
    done
}

# 14. Instalar Drivers da NVIDIA
install_nvidia_drivers() {
    if ! lspci | grep -qi "NVIDIA"; then
        log_info "Nenhuma placa NVIDIA detectada. Pulando."
        return 0
    fi

    log_warn "Placa NVIDIA detectada. Instalando drivers proprietários..."

    log_info "Instalando repositórios RPM Fusion..."
    sudo dnf install -y \
        "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
        "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

    sudo dnf update -y

    log_info "Instalando drivers NVIDIA (akmod-nvidia + CUDA)..."
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda || { log_error "Falha ao instalar drivers NVIDIA."; return 1; }

    log_warn "Aguarde a compilação do módulo do kernel."
    log_warn "Reinicialização NECESSÁRIA para carregar o driver."
    log_warn "SECURE BOOT: Na próxima reinicialização, selecione 'Enroll MOK' e insira sua senha."
}

# 15. Instalar IntelliJ IDEA Ultimate
install_intellij_manual() {
    local install_dir="/opt"

    if compgen -G "${install_dir}/idea-IU-"* > /dev/null; then
        log_info "IntelliJ já encontrado em ${install_dir}. Pulando."
        return 0
    fi

    local api_url="https://data.services.jetbrains.com/products/releases?code=IIU&latest=true&type=release"
    log_info "Buscando URL de download do IntelliJ IDEA..."

    local download_url
    download_url=$(curl -fsL "$api_url" | jq -r '.IIU[0].downloads.linux.link')

    if [ -z "$download_url" ] || [ "$download_url" == "null" ]; then
        log_error "Não foi possível obter a URL de download do IntelliJ."
        return 1
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d -t intellij-install-XXXXXX)
    trap 'rm -rf -- "$tmp_dir"' RETURN

    log_info "Baixando IntelliJ de $download_url..."
    curl -LfsS -o "$tmp_dir/idea.tar.gz" "$download_url" || { log_error "Falha ao baixar IntelliJ."; return 1; }

    log_info "Extraindo para ${install_dir}..."
    sudo tar -xzf "$tmp_dir/idea.tar.gz" -C "$install_dir" || { log_error "Falha ao extrair IntelliJ."; return 1; }

    log_info "IntelliJ IDEA instalado em ${install_dir}."
}

# 16. Instalar Google Chrome
install_google_chrome() {
    if command -v google-chrome-stable &>/dev/null; then
        log_info "Google Chrome já está instalado. Pulando."
        return 0
    fi

    log_info "Instalando Google Chrome..."
    sudo dnf install -y fedora-workstation-repositories
    sudo dnf config-manager setopt google-chrome.enabled=1
    sudo dnf install -y google-chrome-stable || { log_error "Falha ao instalar Google Chrome."; return 1; }
    log_info "Google Chrome instalado com sucesso."
}

# 17. Instalar kubectl
install_kubectl() {
    if command -v kubectl &>/dev/null; then
        log_info "kubectl já está instalado: $(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1)"
        return 0
    fi

    log_info "Instalando kubectl..."
    cat <<'REPO' | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/repodata/repomd.xml.key
REPO
    sudo dnf install -y kubectl || { log_error "Falha ao instalar kubectl."; return 1; }
    log_info "kubectl instalado com sucesso."
}

# 18. Instalar ripgrep
install_ripgrep() {
    if command -v rg &>/dev/null; then
        log_info "ripgrep já está instalado. Pulando."
        return 0
    fi

    log_info "Instalando ripgrep..."
    sudo dnf install -y ripgrep || { log_error "Falha ao instalar ripgrep."; return 1; }
}

# 19. Instalar mise (gerenciador de runtimes)
install_mise() {
    if command -v mise &>/dev/null; then
        log_info "mise já está instalado. Pulando."
        return 0
    fi

    log_info "Instalando mise..."
    curl https://mise.run | sh || { log_error "Falha ao instalar mise."; return 1; }

    local zshrc="$HOME/.zshrc"
    [ ! -f "$zshrc" ] && touch "$zshrc"
    if ! grep -qF "mise activate" "$zshrc"; then
        log_info "Adicionando mise ao .zshrc..."
        {
            echo ""
            echo 'export PATH="$HOME/.local/bin:$PATH"'
            echo 'eval "$(mise activate zsh)"'
        } >> "$zshrc"
    else
        log_info "mise já configurado no .zshrc."
    fi

    log_info "mise instalado. Use 'mise use node@<version>' para instalar runtimes."
}

# --- Execução Principal ---
main() {
    install_prerequisites_and_update

    # Remoções
    # remove_games  # Descomente para executar
    remove_gnome_apps
    remove_tmux

    # Ambiente de Shell e Terminal
    install_zsh_ohmyzsh
    install_kitty
    install_zellij
    install_neovim_lazyvim
    install_dev_tools

    # Drivers de Hardware
    install_nvidia_drivers

    # Ferramentas de Desenvolvimento
    install_sdkman
    install_maven
    install_podman_compose
    install_mise

    # Ferramentas CLI
    install_ripgrep
    install_kubectl

    # Fontes e Aplicativos GUI
    install_meslo_font
    install_flatpak_apps
    install_intellij_manual
    install_google_chrome

    echo ""
    echo "-------------------------------------------------------"
    log_info "Configuração inicial concluída!"
    echo "-------------------------------------------------------"
    echo "Próximos Passos CRÍTICOS:"
    echo "1. REINICIE O SISTEMA AGORA. Uma reinicialização é obrigatória para:"
    echo "   - Carregar o driver da NVIDIA recém-instalado (se aplicável)."
    echo "   - Ativar o Zsh como seu shell padrão."
    echo "   - Carregar o SDKMAN! e mise no novo shell."
    echo "2. ATENÇÃO - SECURE BOOT: Se você usa Secure Boot e instalou os drivers NVIDIA,"
    echo "   após reiniciar, uma tela azul (MOK Management) aparecerá."
    echo "   -> Selecione 'Enroll MOK' -> 'Continue' -> Insira sua senha quando solicitado."
    echo ""
    echo "Após a reinicialização:"
    echo "  - Execute 'p10k configure' para configurar o Powerlevel10k."
    echo "  - IntelliJ IDEA: executável em /opt/idea-IU-*/bin/idea.sh"
    echo "  - Abra o Neovim (nvim) para que o LazyVim finalize a configuração."
    echo "  - Execute o script finalizacao.sh para configurar o Kitty."
    echo "-------------------------------------------------------"
}

main
exit 0
