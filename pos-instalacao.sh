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
    log_info "Instalando dependências básicas (curl, git, util-linux-user)..."
    sudo dnf install -y curl git util-linux-user # util-linux-user para chsh

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
        export ZSH_DISABLE_COMPFIX="true" # Evita alguns prompts se já houver arquivos zsh
        export RUNZSH=no CHSH=no # Impede Oh My Zsh de tentar mudar o shell ou iniciar o zsh
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
        # set -e cuidará da saída
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
    sudo dnf install -y neovim python3-neovim # python3-neovim é útil para plugins

    log_info "Instalando LazyVim..."
    if [ ! -d "$HOME/.config/nvim" ]; then
        log_info "Clonando LazyVim starter..."
        git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
        # rm -rf "$HOME/.config/nvim/.git" # Opcional
        log_info "LazyVim starter clonado para $HOME/.config/nvim."
        log_info "Abra o nvim pela primeira vez para finalizar a instalação dos plugins."
    else
        log_info "Diretório $HOME/.config/nvim já existe. Pulando clone do LazyVim."
        log_info "Se desejar uma instalação limpa do LazyVim, remova o diretório $HOME/.config/nvim e $HOME/.local/share/nvim manualmente e rode o script novamente."
    fi
}

# 5. Garantir que o GCC e ferramentas de desenvolvimento estejam instaladas
install_dev_tools() {
    log_info "Instalando GCC e ferramentas de desenvolvimento básicas..."
    sudo dnf groupinstall -y "Development Tools"
}

# 6. Remover aplicativos específicos do GNOME
remove_gnome_apps() {
    log_info "Removendo aplicativos específicos do GNOME..."
    sudo dnf remove -y gnome-contacts gnome-weather gnome-maps gnome-boxes simple-scan \
                       totem rhythmbox gnome-tour gnome-characters gnome-connections \
                       evince loupe gnome-text-editor gnome-logs gnome-abrt \
                       gnome-system-monitor # Considere manter este último ou instalar um substituto
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
        # SDKMAN! deve ser instalado como o usuário atual, não com sudo.
        # O script do SDKMAN! lida com a adição ao .bashrc/.zshrc.
        curl -s "https://get.sdkman.io" | bash
        log_info "SDKMAN! instalado."
        log_info "Para usar o SDKMAN! na sessão atual do script (se necessário para passos subsequentes), você precisaria executar:"
        log_info "source \"\$HOME/.sdkman/bin/sdkman-init.sh\""
        log_info "Em novas sessões de terminal (após o Zsh ser definido como padrão e o .zshrc ser carregado), o SDKMAN! estará disponível."
    fi
}

# 8. Instalar Maven
install_maven() {
    log_info "Instalando Maven via dnf..."
    sudo dnf install -y maven
    log_info "Maven instalado a partir dos repositórios do Fedora."
    log_info "Se preferir, após configurar o SDKMAN! e reiniciar o shell, você pode instalar e gerenciar versões do Maven com: sdk install maven"
}

# --- Execução Principal ---
main() {
    install_prerequisites_and_update
    # remove_games
    install_zsh_ohmyzsh # Instala Zsh e OhMyZsh, modifica .zshrc
    install_kitty
    install_neovim_lazyvim
    install_dev_tools
    remove_gnome_apps
    
    # Assegure que $HOME se refere ao diretório do usuário que executa o script, não root.
    # Este script é projetado para ser executado como um usuário normal, usando `sudo` apenas quando necessário.
    install_sdkman    # Instala SDKMAN!, modifica .zshrc/bashrc
    install_maven     # Instala Maven via dnf

    echo ""
    echo "-------------------------------------------------------"
    log_info "Configuração inicial concluída!"
    echo "-------------------------------------------------------"
    echo "Próximos Passos:"
    echo "1. FAÇA LOGOUT E LOGIN NOVAMENTE (ou reinicie o sistema) para que o Zsh seja seu shell ativo."
    echo "   Isso também garantirá que o SDKMAN! seja carregado no seu ambiente Zsh."
    echo "2. Abra o terminal Kitty (que foi instalado)."
    echo "3. No Kitty, execute o segundo script: ./finalizacao.sh"
    echo "   (Este script removerá o GNOME Terminal)."
    echo "4. Após executar finalizacao.sh, abra o Neovim (nvim) pela primeira vez para que o LazyVim configure os plugins."
    echo "5. Após o login/reinicialização, você pode usar o SDKMAN! (ex: 'sdk list java', 'sdk install java VERSAO_DESEJADA', 'sdk install maven')."
    echo "-------------------------------------------------------"
}

# Executar a função principal
main

exit 0


Script finalizacao.sh (atualizado para mencionar SDKMAN!):

#!/bin/bash
set -e

echo "INFO: Removendo GNOME Terminal..."
sudo dnf remove -y gnome-terminal

echo "INFO: GNOME Terminal removido."
echo "INFO: Processo de pós-instalação finalizado."
echo "INFO: Lembre-se de abrir o Neovim (nvim) para o LazyVim instalar os plugins, se ainda não o fez."
echo "INFO: Verifique se o SDKMAN! está funcionando ('sdk version') e instale as SDKs desejadas (ex: 'sdk install java')."
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Bash
IGNORE_WHEN_COPYING_END
