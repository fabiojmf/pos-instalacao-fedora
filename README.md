# Configuração Pós-Instalação do Fedora

Este projeto contém scripts para automatizar a configuração do Fedora após uma nova instalação. Ele remove pacotes indesejados, como jogos e aplicativos específicos do GNOME, e instala ferramentas preferidas, como Zsh, Oh My Zsh, Kitty, Neovim, LazyVim e GCC. O objetivo é economizar tempo e garantir consistência em múltiplas instalações do sistema.


## Estrutura do Projeto

- **`pos-instalacao.sh`**: Script principal que realiza a maior parte das configurações, incluindo:
  - Remoção de jogos e aplicativos específicos do GNOME.
  - Instalação de Zsh, Oh My Zsh, Kitty, Neovim, LazyVim e GCC.
- **`finalizacao.sh`**: Script secundário que remove o Bash e o GNOME Terminal após a configuração inicial.

## Ferramentas Específicas

- **KeePassXC**: Escolhido por ser um gerenciador de senhas seguro, de código aberto e fácil de usar, garantindo proteção e acesso prático às credenciais.
- **Mise (mise-en-place)**: Selecionado para gerenciar versões de linguagens e ferramentas de desenvolvimento, simplificando a criação de ambientes consistentes.

## Instruções de Uso

### Pré-requisitos
- Uma instalação recente do Fedora com o ambiente GNOME.
- Conexão à internet para baixar pacotes e scripts.
- Permissões de superusuário (usando `sudo`).

### Passos para Executar

 1. **Clone ou baixe este repositório**:
   ```bash
   git clone https://github.com/seu-usuario/seu-repositorio.git
   cd seu-repositorio
```
 2. **Dê permissão de execução aos scripts**:
```bash
chmod +x pos-instalacao.sh finalizacao.sh
```
 3. **Execute o primeiro script no GNOME Terminal**:
```bash
./pos-instalacao.sh
```
 4. **Abra o Kitty e execute o segundo script**:
Após o término do primeiro script, abra o terminal Kitty e execute:
```sh
./finalizacao.sh
```

## Personalização

-   Adicionar ou remover pacotes:
    
    -   Edite os comandos ```dnf install``` e ```dnf remove``` nos scripts para incluir ou excluir pacotes conforme suas necessidades.
        
-   Configurações adicionais:
    
    -   Adicione comandos ao final dos scripts para personalizar o sistema, como instalar extensões do GNOME ou configurar temas.

## Avisos e Cuidados

-   Remoção do Bash:
    
    -   Certifique-se de que o Zsh está funcionando corretamente antes de executar o script finalizacao.sh. A remoção do Bash pode afetar ferramentas ou scripts que dependem dele.
        
-   Remoção do GNOME Terminal:
    
    -   Após removê-lo, verifique se o Kitty está configurado e funcionando como seu terminal padrão.
        
-   Teste em ambiente seguro:
    
    -   Recomenda-se testar os scripts em uma máquina virtual ou ambiente de teste antes de aplicá-los em um sistema de produção.
