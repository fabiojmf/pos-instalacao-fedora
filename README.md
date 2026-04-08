# Scripts de Configuração Pós-Instalação do Fedora

Este repositório contém scripts para automatizar a configuração de um ambiente de desenvolvimento (foco em **JAVA**) e personalização em uma instalação recente do Fedora Workstation.

**AVISO:** Estes scripts realizam alterações significativas no sistema, incluindo a instalação e remoção de pacotes, e a modificação de arquivos de configuração. Execute-os por sua conta e risco. Revise os scripts cuidadosamente antes de executá-los.

## Visão Geral

O processo é dividido em dois scripts:
1. **`pos-instalacao.sh`**: Script principal — instalação de software, drivers, ferramentas de desenvolvimento e configuração do sistema.
2. **`finalizacao.sh`**: Script secundário — configuração do terminal Kitty. **Deve ser executado APÓS o `pos-instalacao.sh` e uma reinicialização completa.**

## Script 1: `pos-instalacao.sh`

### O que este script faz?

* **Pré-requisitos e Atualização do Sistema:**
  * Instala dependências básicas (`curl`, `git`, `util-linux-user`, `unzip`, `tar`, `flatpak`, `jq`).
  * Atualiza todos os pacotes do sistema.
  * Configura o repositório Flathub para Flatpak.

* **Limpeza do Sistema:**
  * Remove jogos do GNOME (descomente na função `main` para ativar).
  * Remove aplicativos padrão do GNOME (Contatos, Mapas, Clima, Boxes, Simple Scan, Totem, Rhythmbox, Tour, Caracteres, Connections, Evince, Loupe, Logs, ABRT, Monitor do Sistema, Relógios, Calendário, Câmera).
  * Remove o LibreOffice.
  * Remove `tmux` (se instalado).

* **Ambiente de Shell e Terminal:**
  * Instala `Zsh` e `Oh My Zsh`.
  * Instala o tema `Powerlevel10k` para o Zsh.
  * Configura Zsh como shell padrão.
  * Instala o emulador de terminal `Kitty`.
  * Instala o multiplexador de terminal `Zellij` (última versão do GitHub).

* **Drivers de Hardware:**
  * Detecta e instala os drivers proprietários da **NVIDIA** (se detectada), incluindo suporte a CUDA.

* **Ferramentas de Desenvolvimento:**
  * Instala `Neovim` com `LazyVim` starter.
  * Instala o grupo `Development Tools` (gcc, make, etc.).
  * Instala `SDKMAN!` para gerenciamento de SDKs Java.
  * Instala `Maven` via dnf.
  * Instala `podman-compose` via dnf.
  * Instala `mise` — gerenciador de runtimes (Node, Python, etc.).

* **Ferramentas CLI:**
  * Instala `ripgrep` (busca rápida em arquivos).
  * Instala `kubectl` (cliente Kubernetes).

* **Fontes e Aplicativos:**
  * Instala a fonte `MesloLGS NF` (recomendada pelo Powerlevel10k).
  * Instala `Bitwarden Desktop` via Flatpak.
  * Instala `Google Chrome` via repositório oficial.
  * Instala o `IntelliJ IDEA Ultimate` (última versão da API JetBrains).

### Como Usar

```bash
chmod +x pos-instalacao.sh
./pos-instalacao.sh
```

### Pós-Execução (Passos Críticos!)

1. **REINICIE O SISTEMA IMEDIATAMENTE:**
   * Carregar o driver da NVIDIA (se aplicável).
   * Ativar o Zsh como shell padrão.
   * Carregar o SDKMAN! e mise no novo shell.

2. **ATENÇÃO AO SECURE BOOT (SE INSTALOU DRIVERS NVIDIA):**
   * Após reiniciar, uma tela azul **MOK Management** aparecerá.
   * Selecione **"Enroll MOK"** → "Continue" → insira sua senha.
   * Se pular este passo, sua sessão gráfica pode não iniciar!

3. **Após a reinicialização:**
   * Execute `p10k configure` para configurar o Powerlevel10k.
   * IntelliJ IDEA: executável em `/opt/idea-IU-*/bin/idea.sh`.
   * Abra o Neovim (`nvim`) para que o LazyVim finalize a instalação dos plugins.
   * Use `mise use node@<version>` para instalar o Node.js.
   * Prossiga para o script `finalizacao.sh`.

## Script 2: `finalizacao.sh`

### O que este script faz?

* **Configuração do Kitty:**
  * Cria `~/.config/kitty/kitty.conf` com:
    * Tema Gruvbox Dark Hard.
    * Fonte `MesloLGS NF` (tamanho 11).
    * Opacidade, cursor, layout de janelas, abas e atalhos.
  * Cria o arquivo de tema `~/.config/kitty/GruvBox_DarkHard.conf`.

* **Aviso sobre o GNOME Terminal:**
  * Verifica se está instalado e avisa sobre os riscos de removê-lo.

### Como Usar

```bash
chmod +x finalizacao.sh
./finalizacao.sh
```

### Pós-Execução

1. Feche e reabra o Kitty para aplicar as configurações.
2. Verifique seu ambiente:
   * **Kitty:** tema Gruvbox e fonte MesloLGS NF.
   * **Neovim:** abra `nvim` para finalizar plugins do LazyVim.
   * **SDKMAN!:** `sdk version`
   * **mise:** `mise ls`
   * **Zellij:** `zellij`

## Solução de Problemas

* **Falha em `dnf`:** Verifique conexão com a internet e repositórios.
* **Falha no download (Zellij, IntelliJ):** Verifique URLs e conexão. APIs podem mudar.
* **Tela preta após reboot:** Se instalou NVIDIA, provavelmente pulou o "Enroll MOK". Reinicie e preste atenção à tela azul.
* **Zsh não é o shell padrão:** Verifique se `chsh` foi executado. Reinicialização resolve.
* **SDKMAN! não encontrado:** Verifique as linhas no `.zshrc` e reinicie o terminal.
* **mise não encontrado:** Verifique se `$HOME/.local/bin` está no PATH e se `eval "$(mise activate zsh)"` está no `.zshrc`.
