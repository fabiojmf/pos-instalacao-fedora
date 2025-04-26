#!/bin/sh

# 1. Remover Bash
echo "Removendo Bash..."
sudo dnf remove -y bash

# 2. Remover GNOME Terminal
echo "Removendo GNOME Terminal..."
sudo dnf remove -y gnome-terminal

# Mensagem de conclusão
echo "Configuração final concluída! Seu Fedora está pronto."
