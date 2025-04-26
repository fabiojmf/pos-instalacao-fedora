#!/bin/bash

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
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo "Configurando Zsh como shell padrão..."
chsh -s $(which zsh)

# 3. Instalar Kitty
echo "Instalando Kitty..."
sudo dnf install -y kitty

# 4. Instalar Neovim e LazyVim
echo "Instalando Neovim..."
sudo dnf install -y neovim

echo "Instalando LazyVim..."
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

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
echo "Configuração inicial concluída! Agora, abra o Kitty e execute o segundo script (finalizacao.sh) para remover o Bash e o GNOME Terminal."
