# Scripts de Configuração Pós-Instalação do Fedora

Este repositório contém um conjunto de scripts para automatizar a configuração de um ambiente de desenvolvimento (foco em **JAVA**) e personalização em uma instalação recente do Fedora Workstation.

**AVISO:** Estes scripts realizam alterações significativas no sistema, incluindo a instalação e remoção de pacotes, e a modificação de arquivos de configuração. Execute-os por sua conta e risco. Revise os scripts cuidadosamente antes de executá-los para entender o que eles fazem.

## Visão Geral

O processo de configuração é dividido em dois scripts principais:

1.  **`pos-instalacao.sh`**: Script principal que realiza a maior parte da instalação de software, configuração do sistema, instalação de drivers e ambiente de desenvolvimento base.
2.  **`finalizacao.sh`**: Script secundário que aplica configurações finais, como a personalização detalhada do terminal Kitty. **Este script deve ser executado APÓS o `pos-instalacao.sh` e uma reinicialização completa do sistema.**


## Script 1: `pos-instalacao.sh`

Este é o script principal para a configuração inicial.

### O que este script faz?

*   **Pré-requisitos e Atualização do Sistema:**
    *   Instala dependências básicas (`curl`, `git`, `util-linux-user`, `unzip`, `tar`, `flatpak`, `jq`).
    *   Atualiza todos os pacotes do sistema (`sudo dnf update -y`).
    *   Configura o repositório Flathub para Flatpak.
*   **Limpeza do Sistema:**
    *   Remove jogos do GNOME (descomente na função `main` para ativar).
    *   Remove aplicativos padrão do GNOME (Contatos, Mapas, Clima, Boxes, Simple Scan, Totem, Rhythmbox, Tour, Caracteres, Connections, Evince, Loupe, Logs, ABRT, Monitor do Sistema, Relógios, Calendário, Câmera).
    *   Remove o LibreOffice (`libreoffice*`).
    *   Remove `tmux` (se instalado).
*   **Ambiente de Shell e Terminal:**
    *   Instala `Zsh`.
    *   Instala `Oh My Zsh` (se ainda não instalado) e configura Zsh como shell padrão para o usuário atual.
    *   Instala o emulador de terminal `Kitty`.
    *   Instala o multiplexador de terminal `Zellij` (baixa a última versão compatível com a arquitetura do sistema a partir do GitHub).
*   **Drivers de Hardware:**
    *   **Detecta e instala os drivers proprietários da NVIDIA** (se uma placa NVIDIA for encontrada), incluindo suporte a CUDA. Configura os repositórios RPM Fusion necessários.
*   **Ferramentas de Desenvolvimento:**
    *   Instala `Neovim` e `python3-neovim`.
    *   Clona o starter do `LazyVim` para `~/.config/nvim` (se o diretório não existir).
    *   Garante que o grupo de pacotes "Development Tools" (incluindo `gcc`, `make`, etc.) esteja instalado.
    *   Instala `SDKMAN!` para gerenciamento de SDKs e o configura para o `.zshrc`.
    *   Instala `Maven` e `npm` (Node Package Manager) via dnf.
    *   Instala `podman-compose` via dnf.
*   **Fontes e Aplicativos:**
    *   Instala a Nerd Font **`CodeNewRoman`**.
    *   Instala `Bitwarden Desktop` via Flatpak.
    *   **Instala o IntelliJ IDEA Ultimate manualmente:** busca a versão mais recente na API da JetBrains, baixa o arquivo `.tar.gz` e o extrai para o diretório `/opt`.

### Pré-requisitos para `pos-instalacao.sh`

*   Uma instalação do Fedora Workstation (preferencialmente recente).
*   Acesso à internet para baixar pacotes e arquivos.
*   Um usuário com privilégios `sudo`.

### Como Usar `pos-instalacao.sh`

1.  **Clone o repositório ou baixe os scripts:**
    ```bash
    git clone <url_do_seu_repositorio>
    cd <nome_do_repositorio>
    ```
    Ou simplesmente salve o conteúdo dos scripts em arquivos locais.

2.  **Torne o script `pos-instalacao.sh` executável:**
    ```bash
    chmod +x pos-instalacao.sh
    ```

3.  **Execute o script `pos-instalacao.sh`:**
    ```bash
    ./pos-instalacao.sh
    ```
    Você será solicitado a fornecer sua senha `sudo` quando necessário.

### Pós-Execução do `pos-instalacao.sh` (Passos Críticos!)

Após a conclusão bem-sucedida do `pos-instalacao.sh`:

1.  **REINICIE O SISTEMA IMEDIATAMENTE:**
    *   Uma reinicialização completa é **obrigatória** para:
        *   Carregar o driver da NVIDIA recém-instalado (se aplicável).
        *   Ativar o Zsh como seu shell padrão.
        *   Permitir que o SDKMAN! seja carregado corretamente no novo shell.
2.  **ATENÇÃO AO SECURE BOOT (SE INSTALOU DRIVERS NVIDIA):**
    *   Após reiniciar, uma tela azul chamada **MOK Management** aparecerá.
    *   Você **DEVE** selecionar **"Enroll MOK"** -> "Continue" -> e inserir sua senha de usuário quando solicitado para autorizar o novo driver.
    *   Se você pular este passo, sua sessão gráfica pode não iniciar!
3.  **Após a reinicialização bem-sucedida:**
    *   **IntelliJ IDEA**: foi instalado em `/opt/`. Para executá-lo, procure pelo script `idea.sh` dentro do diretório criado (ex: `/opt/idea-IU-*/bin/idea.sh`). Recomenda-se criar um atalho (`.desktop`) para facilitar o acesso.
    *   Abra o terminal (que agora deve ser o Kitty) e prossiga para o script `finalizacao.sh`.


## Script 2: `finalizacao.sh`

Este script aplica as configurações finais, principalmente para o terminal Kitty.

### O que este script faz?

*   **Configuração do Kitty:**
    *   Cria o diretório de configuração `~/.config/kitty/`.
    *   Cria o arquivo `~/.config/kitty/kitty.conf` com configurações predefinidas para:
        *   Tema (incluindo o arquivo `GruvBox_DarkHard.conf`).
        *   Opacidade e blur.
        *   Fonte (`CodeNewRoman Nerd Font`).
        *   Customização do cursor, layout de janelas, abas e atalhos.
    *   Cria o arquivo de tema `~/.config/kitty/GruvBox_DarkHard.conf`.
*   **Aviso sobre o GNOME Terminal:**
    *   Verifica se o `gnome-terminal` está instalado e, em caso afirmativo, **avisa sobre os riscos de removê-lo**, recomendando mantê-lo como um terminal de "fallback". A remoção não é mais automática.

### Pré-requisitos para `finalizacao.sh`

*   O script `pos-instalacao.sh` deve ter sido executado com sucesso.
*   Você deve ter **REINICIADO O SISTEMA**.
*   `Zsh` deve ser o shell ativo.

### Como Usar `finalizacao.sh`

1.  **Certifique-se de que os pré-requisitos acima foram atendidos.**
2.  **Abra o terminal (Kitty).**
3.  **Navegue até o diretório onde o script está salvo.**
    ```bash
    cd <caminho_para_o_diretorio_dos_scripts>
    ```
4.  **Torne o script `finalizacao.sh` executável:**
    ```bash
    chmod +x finalizacao.sh
    ```
5.  **Execute o script `finalizacao.sh`:**
    ```bash
    ./finalizacao.sh
    ```

### Pós-Execução do `finalizacao.sh`

1.  **Feche e Reabra o Kitty:**
    *   Para que as novas configurações de tema e fonte sejam aplicadas, feche todas as instâncias do Kitty e abra-o novamente.
2.  **Verifique seu Ambiente:**
    *   **Kitty:** Deverá estar com o tema e fontes configurados.
    *   **Neovim:** Abra o Neovim (`nvim`) pela primeira vez para que o LazyVim finalize a instalação dos plugins.
    *   **SDKMAN!:** Verifique se está funcionando com `sdk version`.
    *   **Zellij:** Teste iniciando com o comando `zellij`.

Seu ambiente de desenvolvimento deve estar pronto!

## Solução de Problemas (Troubleshooting)

*   **Falha em `dnf`:** Verifique sua conexão com a internet e os repositórios do Fedora.
*   **Falha no download de arquivos (Zellij, IntelliJ):** Verifique as URLs nos scripts e sua conexão. APIs e links de releases podem mudar.
*   **Sessão gráfica não inicia (tela preta) após reboot:** Se você instalou os drivers NVIDIA, provavelmente pulou ou falhou no passo de "Enroll MOK" no Secure Boot. Reinicie e preste atenção à tela azul.
*   **Zsh não é o shell padrão:** Verifique se o comando `chsh` foi executado com sucesso no `pos-instalacao.sh`. Uma reinicialização completa geralmente resolve isso.
*   **SDKMAN! não encontrado:** Certifique-se de que as linhas de `source` foram adicionadas corretamente ao seu arquivo `.zshrc` e que você reiniciou o sistema e abriu um novo terminal.
