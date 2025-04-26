# Configuração Pós-Instalação do Fedora

Este projeto contém scripts para automatizar a configuração do Fedora após uma nova instalação. Ele remove pacotes indesejados, como jogos e aplicativos específicos do GNOME, e instala ferramentas preferidas, como Zsh, Oh My Zsh, Kitty, Neovim (com LazyVim), GCC, KeePassXC e Mise. O objetivo é criar um ambiente de desenvolvimento mais minimalista e consistente rapidamente.

## Estrutura do Projeto

-   **`pos-instalacao.sh`**: Script principal que realiza a maior parte das configurações, incluindo:
    -   Atualização do sistema.
    -   Remoção de jogos e aplicativos específicos do GNOME.
    -   Instalação de Zsh, Oh My Zsh, Kitty, Neovim, LazyVim, GCC, KeePassXC e Mise.
    -   Configuração do Zsh como shell padrão do usuário.
-   **`finalizacao.sh`**: Script secundário que remove o GNOME Terminal. **Deve ser executado no Kitty após o primeiro script e um logout/login.**

## Ferramentas Específicas

-   **KeePassXC**: Escolhido por ser um gerenciador de senhas seguro, de código aberto e multiplataforma.
-   **Mise (mise-en-place)**: Selecionado para gerenciar versões de linguagens e ferramentas de desenvolvimento (`asdf` reescrito em Rust).
-   **Zsh + Oh My Zsh**: Um shell poderoso com um framework popular para gerenciamento de configurações e plugins.
-   **Kitty**: Um emulador de terminal rápido, baseado em GPU e altamente configurável.
-   **Neovim + LazyVim**: Um editor de texto Vim moderno com uma distribuição pré-configurada focada em facilidade de uso e funcionalidades modernas.

## Instruções de Uso

### Pré-requisitos

-   Uma instalação recente do Fedora Workstation (com ambiente GNOME padrão).
-   Conexão à internet para baixar pacotes e scripts.
-   Permissões de superusuário (o script usará `sudo`).

### Passos para Executar

1.  **Clone ou baixe este repositório**:
    ```bash
    git clone https://github.com/seu-usuario/seu-repositorio.git # Substitua pela URL correta
    cd seu-repositorio
    ```

2.  **Dê permissão de execução aos scripts**:
    ```bash
    chmod +x pos-instalacao.sh finalizacao.sh
    ```

3.  **Execute o primeiro script no GNOME Terminal**:
    Abra o terminal padrão do GNOME e execute:
    ```bash
    ./pos-instalacao.sh
    ```
    Preste atenção às mensagens de saída.

4.  **Faça Logout e Login (ou Reinicie)**:
    Após a conclusão do `pos-instalacao.sh`, é **essencial** fazer logout da sua sessão GNOME e fazer login novamente, ou reiniciar o computador. Isso garante que o Zsh seja carregado como seu novo shell padrão.

5.  **Abra o Kitty e execute o segundo script**:
    Após fazer login novamente, procure e abra o terminal **Kitty**. Dentro do Kitty, navegue até o diretório do repositório clonado e execute:
    ```zsh
    ./finalizacao.sh
    ```
    Este comando removerá o GNOME Terminal.

6.  **Primeira execução do Neovim**:
    Abra o Neovim pela primeira vez para que o LazyVim instale seus plugins:
    ```zsh
    nvim
    ```

## Personalização

-   **Adicionar ou remover pacotes**:
    -   Edite os comandos `sudo dnf install -y ...` e `sudo dnf remove -y ...` no script `pos-instalacao.sh` para ajustar a seleção de software às suas preferências.
-   **Configurações adicionais**:
    -   Adicione comandos ao final dos scripts para outras personalizações, como instalar extensões do GNOME (`gnome-extensions install ...`), configurar temas (GSettings), ou clonar seus dotfiles.

## Avisos e Cuidados

-   **Remoção do GNOME Terminal**:
    -   O script `finalizacao.sh` remove o GNOME Terminal. Certifique-se de que o Kitty foi instalado corretamente e está funcionando *antes* de executar este script, pois você ficará sem o terminal padrão do GNOME após a execução. O fluxo de execução (rodar no Kitty) ajuda a garantir isso.
-   **Teste em Ambiente Seguro**:
    -   É **altamente recomendável** testar estes scripts em uma máquina virtual (VM) ou em um ambiente de teste isolado antes de aplicá-los em seu sistema principal. Isso permite identificar e corrigir problemas sem impactar seu ambiente de trabalho.
-   **Dependências de Pacotes**:
    -   A remoção agressiva de pacotes GNOME e `libreoffice*` pode remover funcionalidades que você espera. Revise a lista de remoção no `pos-instalacao.sh` se você precisar de algum desses aplicativos.
-   **Efeito da Mudança de Shell**:
    -   O passo de logout/login (ou reinicialização) após `pos-instalacao.sh` é crucial para que o sistema reconheça o Zsh como seu shell padrão antes de prosseguir.
