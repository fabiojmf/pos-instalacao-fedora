# Scripts de Configuração Pós-Instalação do Fedora

Este repositório contém um conjunto de scripts para automatizar a configuração de um ambiente de desenvolvimento (foco em **JAVA**) e personalização em uma instalação recente do Fedora Workstation.

**AVISO:** Estes scripts realizam alterações significativas no sistema, incluindo a instalação e remoção de pacotes, e a modificação de arquivos de configuração. Execute-os por sua conta e risco. Revise os scripts cuidadosamente antes de executá-los para entender o que eles fazem.

## Visão Geral

O processo de configuração é dividido em dois scripts principais:

1.  **`pos-instalacao.sh`**: Script principal que realiza a maior parte da instalação de software, configuração do sistema e ambiente de desenvolvimento base.
2.  **`finalizacao.sh`**: Script secundário que aplica configurações finais, como a configuração detalhada do terminal Kitty e a remoção do GNOME Terminal. **Este script deve ser executado APÓS o `pos-instalacao.sh` e um logout/login, e preferencialmente dentro do terminal Kitty.**

---

## Script 1: `pos-instalacao.sh`

Este é o script principal para a configuração inicial.

### O que este script faz?

*   **Pré-requisitos e Atualização do Sistema:**
    *   Instala dependências básicas (`curl`, `git`, `util-linux-user`, `unzip`, `tar`, `flatpak`).
    *   Atualiza todos os pacotes do sistema (`sudo dnf update -y`).
    *   Configura o repositório Flathub para Flatpak.
*   **Remoções (Opcionais e Padrão):**
    *   Remove jogos do GNOME (comentado por padrão na função `main`).
    *   Remove aplicativos padrão do GNOME (Contatos, Mapas, Clima, Boxes, Simple Scan, Totem, Rhythmbox, Tour, Caracteres, Connections, Evince, Loupe, Logs, ABRT, Monitor do Sistema, Relógios, Calendário, Câmera).
    *   Remove o LibreOffice.
    *   Remove `tmux` (se instalado).
*   **Ambiente de Shell e Terminal:**
    *   Instala `Zsh`.
    *   Instala `Oh My Zsh` (se ainda não instalado) e configura Zsh como shell padrão para o usuário atual.
    *   **Instala** o emulador de terminal `Kitty` (a configuração detalhada é feita pelo `finalizacao.sh`).
    *   Instala o multiplexador de terminal `Zellij` (baixa a última versão do GitHub).
    *   Instala a Nerd Font `CodeNewRoman` para uso com ícones em terminais e editores.
*   **Ferramentas de Desenvolvimento:**
    *   Instala `Neovim` e `python3-neovim`.
    *   Clona o starter do `LazyVim` para `~/.config/nvim` (se o diretório não existir).
    *   Garante que as "Ferramentas de Desenvolvimento" (incluindo `gcc`, `make`, etc.) estejam instaladas.
    *   Instala `SDKMAN!` para gerenciamento de SDKs (Java, Groovy, etc.) e o configura para `.zshrc` e `.bashrc`.
    *   Instala `Maven` via dnf.
    *   Instala `podman-compose` via dnf.
*   **Aplicativos via Flatpak:**
    *   Instala `Bitwarden Desktop`.
    *   Instala `IntelliJ IDEA Ultimate`.

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

### Pós-Execução do `pos-instalacao.sh` (Importante!)

Após a conclusão bem-sucedida do `pos-instalacao.sh`:

1.  **REINICIE A SESSÃO OU O SISTEMA:**
    *   Faça logout e login novamente, ou reinicie o seu computador. Isso é crucial para:
        *   Ativar o Zsh como seu shell padrão.
        *   Carregar as configurações do SDKMAN!
        *   Garantir que as fontes instaladas sejam reconhecidas globalmente.
        *   Assegurar que `Zellij` esteja no PATH global.
        *   Integrar completamente os aplicativos Flatpak.
2.  **Abra o Terminal Kitty:**
    *   Após o login, procure e abra o terminal Kitty. Ele ainda não estará com a configuração final.
3.  **Prossiga para o script `finalizacao.sh`** (instruções abaixo).

### Personalização do `pos-instalacao.sh`

Você pode personalizar o script `pos-instalacao.sh` editando-o antes de executar:

*   **Remoção de Jogos:** A função `remove_games()` está comentada na função `main()`. Descomente a linha `remove_games` se desejar remover os jogos.
*   **Aplicativos GNOME:** Modifique a lista de pacotes na função `remove_gnome_apps()`.
*   **Aplicativos Flatpak:** Edite o array `flatpaks_to_install` na função `install_flatpak_apps()`.
*   **Nerd Font:** Altere as variáveis `font_name` e `latest_nerd_font_release_tag` (ou `font_zip_url`) na função `install_nerd_fonts()`.

---

## Script 2: `finalizacao.sh`

Este script aplica as configurações finais, principalmente para o terminal Kitty.

### O que este script faz?

*   **Configuração do Kitty:**
    *   Cria o diretório de configuração `~/.config/kitty/` (se não existir).
    *   Cria/Substitui `~/.config/kitty/kitty.conf` com configurações predefinidas para:
        *   Tema (incluindo `GruvBox_DarkHard.conf`).
        *   Opacidade e blur.
        *   Fonte (`Code New Roman Nerd Font`).
        *   Gerenciamento de tamanho de fonte.
        *   Customização do cursor.
        *   Configurações de scrollback e mouse.
        *   Layout e gerenciamento de janelas/abas.
        *   Estilo da barra de abas.
    *   Cria/Substitui `~/.config/kitty/GruvBox_DarkHard.conf` com as definições de cores do tema.
*   **Remoção do GNOME Terminal:**
    *   Remove o `gnome-terminal` se estiver instalado.

### Pré-requisitos para `finalizacao.sh`

*   O script `pos-instalacao.sh` deve ter sido executado com sucesso.
*   Você deve ter feito **logout e login novamente** (ou reiniciado o sistema).
*   `Zsh` deve ser o shell ativo.
*   O script deve ser executado **dentro do terminal Kitty**.

### Como Usar `finalizacao.sh`

1.  **Certifique-se de que os pré-requisitos acima foram atendidos.**
2.  **Abra o terminal Kitty.**
3.  **Navegue até o diretório onde o script está salvo.**
    ```bash
    cd <caminho_para_o_diretorio_dos_scripts>
    ```
4.  **Torne o script `finalizacao.sh` executável (se ainda não o fez):**
    ```bash
    chmod +x finalizacao.sh
    ```
5.  **Execute o script `finalizacao.sh` (usando `zsh`):**
    ```bash
    zsh ./finalizacao.sh
    # ou se o Zsh já for seu shell padrão e o shebang estiver correto:
    # ./finalizacao.sh
    ```

### Pós-Execução do `finalizacao.sh`

1.  **Recarregue a Configuração do Kitty:**
    *   As configurações do Kitty devem ser aplicadas. Se você executou o script dentro do Kitty, pode ser necessário recarregar a configuração (geralmente `Ctrl+Shift+F5`) ou simplesmente fechar e reabrir o Kitty para ver todas as alterações.
2.  **Verifique seu Ambiente:**
    *   **Kitty:** Deverá estar com o tema e fontes configurados.
    *   **Neovim:** Abra o Neovim (`nvim`) pela primeira vez para que o LazyVim configure os plugins.
    *   **SDKMAN!:** Verifique se está funcionando (`sdk version`).
    *   **Zellij:** Teste iniciando com `zellij`.
    *   **podman-compose:** Verifique com `podman-compose --version`.
    *   **Aplicativos Flatpak:** Verifique se Bitwarden e IntelliJ IDEA Ultimate estão acessíveis.

Seu ambiente de desenvolvimento deve estar pronto!

## Observações Gerais

*   Os scripts usam `set -e`, o que significa que sairão imediatamente se qualquer comando falhar.
*   Muitas operações que envolvem instalação de pacotes ou configuração de sistema usam `sudo` e solicitarão sua senha.
*   Uma conexão com a internet é necessária.

## Solução de Problemas (Troubleshooting)

*   **Falha em `dnf`:** Verifique sua conexão com a internet e os repositórios do Fedora.
*   **Falha no download de arquivos (Zellij, Nerd Font):** Verifique as URLs nos scripts e sua conexão. Releases no GitHub podem mudar.
*   **Zsh não é o shell padrão após o login:** Verifique se o comando `chsh` foi executado com sucesso no `pos-instalacao.sh`. Pode ser necessário reiniciar em vez de apenas fazer logout/login.
*   **SDKMAN! não encontrado:** Certifique-se de que as linhas de `source` foram adicionadas corretamente aos seus arquivos `.zshrc` ou `.bashrc` pelo `pos-instalacao.sh` e que você abriu um novo terminal após o login.
*   **Configurações do Kitty não aplicadas:** Certifique-se de que o `finalizacao.sh` foi executado sem erros e que você recarregou a configuração do Kitty ou o reiniciou. Verifique também se o arquivo `~/.config/kitty/kitty.conf` foi criado corretamente.
