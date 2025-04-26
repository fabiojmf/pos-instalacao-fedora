#!/usr/bin/env zsh
set -e # Sair imediatamente se um comando falhar

# Este script deve ser executado DEPOIS do pos-instalacao.sh
# e APÓS fazer logout/login, DENTRO do terminal Kitty.

echo "Removendo GNOME Terminal..."
sudo dnf remove -y gnome-terminal

# Mensagem de conclusão
echo "Configuração final concluída! GNOME Terminal foi removido."
echo "Seu Fedora está pronto com Zsh, Kitty e suas outras ferramentas."
