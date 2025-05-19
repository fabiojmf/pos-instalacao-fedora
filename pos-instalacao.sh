#!/bin/bash
set -e # Sair imediatamente se um comando falhar

# Função para logar mensagens
log_info() {
    echo "INFO: $1"
}

log_warn() {
    echo "WARN: $1"
}

log_error() {
    echo "ERROR: $1" >&2
}

# 0. Pré-requisitos e atualização do sistema
install_prerequisites_and_update() {
    log_info "Instalando dependências básicas (curl, git, util-linux-user, unzip)..."
    sudo dnf install -y curl git util-linux-user unzip # util-linux-user para chsh, unzip para fontes

    log_info "Atualizando o sistema..."
    sudo dnf update -y
}

# 1. Remover todos os jogos
remove_games() {
    log_info "Removendo jogos..."
    sudo dnf remove -y gnome-mines gnome-sudoku aisleriot quadrapassel iagno lightsoff \
                       swell-foop five-or-more four-in-a-row hitori gnome-klotski \
                       gnome-robots gnome-tetravex tali || log_warn "Alguns jogos não foram encontrados ou já removidos."
}

# 2. Instalar Zsh e Oh My Zsh
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

# 3. Instalar Kitty
install_kitty() {
    log_info "Instalando Kitty..."
    sudo dnf install -y kitty
}

# 4. Instalar Neovim e LazyVim
install_neovim_lazyvim() {
    log_info "Instalando Neovim..."
    sudo dnf install -y neovim python3-neovim

    log_info "Instalando LazyVim..."
    if [ ! -d "$HOME/.config/nvim" ]; then
        log_info "Clonando LazyVim starter..."
        git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
        # rm -rf "$HOME/.config/nvim/.git" # Opcional
        log_info "LazyVim starter clonado para $HOME/.config/nvim."
        log_info "Abra o nvim pela primeira vez para finalizar a instalação dos plugins."
    else
        log_info "Diretório $HOME/.config/nvim já existe. Pulando clone do LazyVim."
    fi
}

# 5. Garantir que o GCC e ferramentas de desenvolvimento estejam instaladas
install_dev_tools() {
    log_info "Garantindo que GCC e ferramentas de desenvolvimento estejam instaladas..."

    local dnf_version_major
    # Extrai o primeiro número da versão do DNF (e.g., 4 ou 5)
    # Se dnf --version falhar, dnf_version_major ficará vazio, e o else será usado.
    dnf_version_major=$(dnf --version 2>/dev/null | head -n1 | cut -d' ' -f1 | cut -d'.' -f1)

    local group_install_cmd

    if [[ "$dnf_version_major" == "5" ]]; then
        log_info "DNF versão $dnf_version_major detectada. Usando sintaxe DNF5: 'dnf group install'"
        group_install_cmd="sudo dnf group install -y"
    elif [[ "$dnf_version_major" =~ ^[0-4]$ ]]; then # Assume versões 0-4 como DNF clássico
        log_info "DNF versão $dnf_version_major detectada. Usando sintaxe DNF clássica: 'dnf groupinstall'"
        group_install_cmd="sudo dnf groupinstall -y"
    else
        log_warn "Não foi possível determinar a versão principal do DNF (saída: '$(dnf --version 2>/dev/null | head -n1)')."
        log_info "Tentando 'sudo dnf group install -y' (DNF5) como padrão moderno."
        # Como fallback, tenta a sintaxe do DNF5, que é a mais provável em sistemas novos/atualizados.
        # Se isso falhar, o fallback de instalar gcc individualmente ainda se aplica.
        group_install_cmd="sudo dnf group install -y"
    fi

    log_info "Tentando instalar o grupo 'Development Tools' (inclui GCC, G++, make, etc.) usando: ${group_install_cmd} \"Development Tools\""
    if ${group_install_cmd} "Development Tools"; then
        log_info "Comando '${group_install_cmd} \"Development Tools\"' executado com sucesso ou o grupo já estava instalado."
    else
        log_warn "Falha ao executar '${group_install_cmd} \"Development Tools\"'."
        log_info "Tentando instalar 'gcc' e 'gcc-c++' explicitamente como fallback..."
        if sudo dnf install -y gcc gcc-c++; then
            log_info "GCC e G++ (compilador C++) instalados explicitamente com sucesso."
        else
            log_error "Falha ao instalar 'gcc' e 'gcc-c++' explicitamente. Verifique os logs do DNF e a saída de erro."
            log_error "Pode ser necessário instalar manualmente: sudo dnf install gcc gcc-c++ make"
            return 1 # Indica falha
        fi
    fi

    # Verificação explícita do GCC
    log_info "Verificando a presença do compilador GCC..."
    if command -v gcc &>/dev/null; then
        log_info "GCC encontrado:"
        gcc --version
    else
        log_error "GCC não foi encontrado mesmo após as tentativas de instalação."
        log_error "Por favor, verifique os logs do DNF e tente instalar o GCC manualmente: sudo dnf install gcc"
        return 1 # Indica falha
    fi

    # Opcional: Verificar outras ferramentas comuns como 'make'
    log_info "Verificando a presença do 'make'..."
    if command -v make &>/dev/null; then
        log_info "'make' encontrado:"
        make --version
    else
        log_warn "'make' não encontrado. Se necessário, instale com: sudo dnf install make"
        # Você pode querer adicionar 'make' ao fallback de instalação individual se for crítico.
        # Ex: if sudo dnf install -y gcc gcc-c++ make; then ...
    fi

    log_info "Instalação/verificação de ferramentas de desenvolvimento concluída."
}

# 6. Remover aplicativos específicos do GNOME
remove_gnome_apps() {
    log_info "Removendo aplicativos específicos do GNOME..."
    sudo dnf remove -y gnome-contacts gnome-weather gnome-maps gnome-boxes simple-scan \
                       totem rhythmbox gnome-tour gnome-characters gnome-connections \
                       evince loupe gnome-text-editor gnome-logs gnome-abrt \
                       gnome-system-monitor gnome-clocks gnome-calendar gnome-camera || log_warn "Alguns aplicativos GNOME não foram encontrados ou já removidos."
    log_info "Removendo LibreOffice..."
    sudo dnf remove -y libreoffice* || log_warn "LibreOffice não encontrado ou já removido."
}

# 7. Instalar SDKMAN!
install_sdkman() {
    log_info "Verificando SDKMAN!..."
    if [ -d "$HOME/.sdkman" ]; then
        log_info "SDKMAN! já está instalado em $HOME/.sdkman. Pulando instalação."
    else
        log_info "Instalando SDKMAN!..."
        curl -s "https://get.sdkman.io" | bash
        log_info "SDKMAN! instalado."
        log_info "Para usar o SDKMAN! na sessão atual do script, execute: source \"\$HOME/.sdkman/bin/sdkman-init.sh\""
    fi
}

# 8. Instalar Maven
install_maven() {
    log_info "Instalando Maven via dnf..."
    sudo dnf install -y maven
    log_info "Maven instalado a partir dos repositórios do Fedora."
}

# 9. Instalar Nerd Font (CodeNewRoman)
install_nerd_fonts() {
    local font_name="CodeNewRoman"
    # Verifique a URL mais recente ou a desejada no site do Nerd Fonts
    local font_zip_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CodeNewRoman.zip" 
    local user_fonts_dir="$HOME/.local/share/fonts"
    local tmp_dir
    tmp_dir=$(mktemp -d) # Cria diretório temporário seguro

    log_info "Instalando Nerd Font: ${font_name}..."

    # Verifica se a fonte já está instalada para evitar retrabalho
    if fc-list | grep -qi "${font_name// /.*}"; then # Ajusta para nomes com espaços
        log_info "Fonte ${font_name} Nerd Font parece já estar instalada. Pulando."
        rm -rf "$tmp_dir" # Limpa o diretório temporário
        return 0
    fi

    mkdir -p "$user_fonts_dir"

    log_info "Baixando ${font_name}.zip de ${font_zip_url}..."
    if curl -LfsS "$font_zip_url" -o "$tmp_dir/${font_name}.zip"; then # -sS para silenciar progresso mas mostrar erros, -f para falhar silenciosamente em erros HTTP
        log_info "Descompactando fontes em $tmp_dir..."
        # Unzip silencioso, sobrescreve sem perguntar, para o diretório de extração
        if unzip -qjo "$tmp_dir/${font_name}.zip" "*.ttf" "*.otf" -d "$user_fonts_dir"; then # Extrai apenas .ttf e .otf diretamente para o destino
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
    
    log_info "Limpando arquivos temporários de $tmp_dir..."
    rm -rf "$tmp_dir" # Sempre remove o diretório temporário
}


# --- Execução Principal ---
main() {
    install_prerequisites_and_update
    # remove_games
    install_zsh_ohmyzsh
    install_kitty
    install_nerd_fonts
    install_neovim_lazyvim
    install_dev_tools
    remove_gnome_apps
    install_sdkman
    install_maven

    echo ""
    echo "-------------------------------------------------------"
    log_info "Configuração inicial concluída!"
    echo "-------------------------------------------------------"
    echo "Próximos Passos:"
    echo "1. FAÇA LOGOUT E LOGIN NOVAMENTE (ou reinicie o sistema) para que o Zsh seja seu shell ativo e as fontes sejam reconhecidas."
    echo "   Isso também garantirá que o SDKMAN! seja carregado no seu ambiente Zsh."
    echo "2. Abra o terminal Kitty (que foi instalado) e configure-o para usar a fonte '${font_name:-CodeNewRoman} Nerd Font'."
    echo "3. No Kitty, execute o segundo script: ./finalizacao.sh"
    echo "   (Este script removerá o GNOME Terminal)."
    echo "4. Após executar finalizacao.sh, abra o Neovim (nvim) pela primeira vez para que o LazyVim configure os plugins."
    echo "5. Após o login/reinicialização, você pode usar o SDKMAN! (ex: 'sdk list java', 'sdk install java VERSAO_DESEJADA', 'sdk install maven')."
    echo "-------------------------------------------------------"
}

# Executar a função principal
main

exit 0
