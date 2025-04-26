#!/bin/bash
set -e # Sair imediatamente se um comando falhar

# Atualizar o sistema antes de começar
echo "Atualizando o sistema..."
sudo dnf update -y

# 1. Remover todos os jogos
echo "Removendo jogos..."
sudo dnf remove -y gnome-mines gnome-sudoku aisleriot quadrapassel iagno lightsoff swell-foop five-or-more four-in-a-row hitori gnome-klotski gnome-robots gnome-tetravex tali

# 2. Instalar Zsh e Oh My Zsh
echo "Instalando Zsh..."
sudo dnf install -y zsh

echo "Instalando Oh My Zsh..."
# Executa sem pedir para mudar o shell aqui, pois faremos isso explicitamente depois
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo "Configurando Zsh como shell padrão para o usuário atual..."
# Verifica se o Zsh foi instalado antes de tentar mudar
if command -v zsh &> /dev/null; then
    sudo chsh -s $(which zsh) $USER
    echo "Shell padrão alterado para Zsh para o usuário $USER."
    echo "IMPORTANTE: A mudança terá efeito completo após logout/login ou reinicialização."
else
    echo "Erro: Zsh não encontrado. Não foi possível definir como shell padrão."
    exit 1
fi

# 3. Instalar Kitty
echo "Instalando Kitty..."
sudo dnf install -y kitty

# 4. Instalar Neovim e LazyVim
echo "Instalando Neovim..."
sudo dnf install -y neovim

echo "Instalando LazyVim..."
if [ ! -d ~/.config/nvim ]; then
    git clone https://github.com/LazyVim/starter ~/.config/nvim
    rm -rf ~/.config/nvim/.git
    echo "LazyVim starter clonado para ~/.config/nvim."
    echo "Abra o nvim pela primeira vez para finalizar a instalação dos plugins."
else
    echo "Diretório ~/.config/nvim já existe. Pulando clone do LazyVim."
fi

# 5. Garantir que o GCC esteja instalado
echo "Instalando GCC..."
sudo dnf install -y gcc

# 6. Remover aplicativos específicos do GNOME
echo "Removendo aplicativos específicos do GNOME..."
sudo dnf remove -y gnome-contacts gnome-weather gnome-maps gnome-boxes simple-scan totem libreoffice* rhythmbox gnome-tour gnome-characters gnome-connections evince loupe

# 7. Instalar KeePassXC e mise-en-place
echo "Instalando KeePassXC e mise-en-place..."
sudo dnf install -y keepassxc mise-en-place

# Mensagem de conclusão
echo ""
echo "-------------------------------------------------------"
echo "Configuração inicial concluída!"
echo "-------------------------------------------------------"
echo "Próximos Passos:"
echo "1. FAÇA LOGOUT E LOGIN NOVAMENTE (ou reinicie o sistema) para que o Zsh seja seu shell ativo."
echo "2. Abra o terminal Kitty (que foi instalado)."
echo "3. No Kitty, execute o segundo script: ./finalizacao.sh"
echo "   (Este script removerá o GNOME Terminal)."
echo "4. Após executar finalizacao.sh, abra o Neovim (nvim) pela primeira vez para que o LazyVim configure os plugins."
echo "-------------------------------------------------------"
