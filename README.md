# Pós-instalação do Fedora

Configuração pessoal e idempotente para uma instalação nova do Fedora Workstation. O projeto instala o ambiente de terminal, desenvolvimento e agentes de IA utilizado por Fabio.

> Revise o código antes de executar. O perfil padrão atualiza o sistema, remove aplicativos e instala drivers e ferramentas.

## Principais escolhas

- **Terminal:** WezTerm nightly, sem Kitty ou Zellij.
- **Shell:** Zsh, Oh My Zsh, Powerlevel10k, autosuggestions e syntax highlighting.
- **Node:** somente pelo mise; pacotes Node/npm em RPM são removidos.
- **Java:** o Java gerenciado pelo Fedora não é alterado. O script instala apenas o SDKMAN; versões adicionais são escolhidas manualmente.
- **Agentes:** Claude Code, Kiro CLI, Pi e Herdr são gerenciados pelo mise.
- **Segredos:** URLs corporativas, deployments, chaves e tokens nunca fazem parte do repositório.
- **LibreOffice:** removido.
- **PJeOffice:** não é instalado.

Não existe mais `finalizacao.sh`: a configuração do WezTerm é aplicada pelo instalador principal e não exige reinicialização.

## Uso

```bash
git clone https://github.com/fabiojmf/pos-instalacao-fedora.git
cd pos-instalacao-fedora
chmod +x install.sh
./install.sh
```

Para inspecionar as ações principais sem alterar a máquina:

```bash
./install.sh --dry-run
```

### Perfis

O padrão executa:

```text
base,terminal,development,ai,nvidia,desktop,maintenance
```

Também é possível selecionar perfis:

```bash
./install.sh --profile base,terminal,development
./install.sh --profile base,ai
./install.sh --profile all
```

| Perfil | Conteúdo |
|---|---|
| `base` | atualização, Flathub, remoções, Zsh, SDKMAN, mise e Node LTS |
| `terminal` | WezTerm nightly e JetBrains Mono |
| `development` | ferramentas de compilação, Neovim/LazyVim, Maven, Podman Compose, kubectl, IntelliJ e DBeaver |
| `ai` | layout persistente e Claude, Kiro, Pi, Herdr e pi-web-access |
| `nvidia` | RPM Fusion e driver NVIDIA, somente quando a GPU é detectada |
| `desktop` | Chrome, Bitwarden, fontes e preferências GNOME |
| `maintenance` | timers diários para Fedora e mise, autoremove e retenção de dois kernels |

Para uma instalação parcial, recomenda-se incluir `base`, pois ele fornece os pré-requisitos comuns.

## Manutenção automática

O perfil `maintenance` instala dois timers independentes:

```text
fedora-maintenance.timer (sistema/root)
├── dnf upgrade --refresh -y
├── dnf remove --oldinstallonly --limit=2 -y
└── dnf autoremove -y

mise-maintenance.timer (usuário)
├── mise self-update -y
└── mise upgrade -y
```

O DNF recebe `installonly_limit=2`, mantendo o kernel atual e um fallback. O comando `--oldinstallonly` não remove o kernel em execução; temporariamente podem existir três versões até o próximo boot e a manutenção seguinte.

O timer do Fedora só executa quando o computador está conectado à energia AC. Ambos são agendados diariamente para as 10h, com um pequeno atraso aleatório, e são persistentes: se a máquina estiver desligada nesse horário, executam depois que ela voltar a ficar disponível.

Não habilite `dnf5-automatic.timer` ao mesmo tempo. O instalador desabilita timers DNF automáticos concorrentes se estiverem presentes.

Consultas úteis:

```bash
systemctl list-timers fedora-maintenance.timer
systemctl --user list-timers mise-maintenance.timer
sudo journalctl -u fedora-maintenance.service
journalctl --user -u mise-maintenance.service
```

Para executar manualmente:

```bash
sudo systemctl start fedora-maintenance.service
systemctl --user start mise-maintenance.service
```

## Layout dos agentes de IA

O instalador cria:

```text
~/.local/share/ai-agents/
├── claude/
├── kiro/
└── pi/
    └── agent/
```

E os links:

```text
~/.kiro -> ~/.local/share/ai-agents/kiro
~/.pi   -> ~/.local/share/ai-agents/pi
```

O Claude usa `CLAUDE_CONFIG_DIR`; Kiro usa `KIRO_HOME`. Históricos, sessões, autenticação e caches permanecem locais e não são versionados.

### Ferramentas gerenciadas pelo mise

A configuração global resultante contém, em essência:

```toml
[tools]
node = "lts"
claude = "latest"
kiro-cli = "latest"
"github:ogulcancelik/herdr" = "latest"
"npm:@earendil-works/pi-coding-agent" = "latest"
```

Atualize essas ferramentas exclusivamente pelo mise:

```bash
mise outdated
mise upgrade
```

Não use `claude update`, `kiro-cli update` ou `herdr update` para instalações controladas pelo mise. O auto-updater do Claude é desabilitado no template inicial.

O pacote adicional do Pi é instalado pelo próprio Pi:

```bash
pi install npm:pi-web-access
```

As integrações de estado são instaladas pelo Herdr:

```bash
herdr integration install claude
herdr integration install pi
```

## Endpoints e credenciais

O repositório contém somente:

```text
config/ai-agents/endpoints.zsh.example
```

Na primeira instalação ele é copiado, vazio, para:

```text
~/.config/ai-agents/endpoints.zsh
```

O arquivo recebe permissão `0600`. Preencha-o manualmente e nunca o envie ao GitHub.

Depois da instalação, autentique manualmente as ferramentas que utilizar:

```bash
claude
kiro-cli
pi
```

## Java e SDKMAN

O instalador não instala, remove, registra ou seleciona nenhuma versão Java. O Maven instalado pelo Fedora pode trazer uma dependência OpenJDK, que permanece sob controle do DNF.

Para adicionar versões por conta própria:

```bash
sdk list java
sdk install java <identificador>
sdk default java <identificador>
```

## Configurações versionadas

```text
config/
├── ai-agents/endpoints.zsh.example
├── claude/settings.json
├── pi/settings.json
├── wezterm/wezterm.lua
└── zsh/
    ├── p10k.zsh
    └── zshrc
```

Ao substituir uma configuração gerenciada existente, o instalador cria um backup com timestamp. Configurações e credenciais dos agentes já existentes são preservadas.

## NVIDIA e Secure Boot

O perfil `nvidia` só age quando `lspci` encontra uma GPU NVIDIA. Após instalar `akmod-nvidia`, aguarde a compilação do módulo antes de reiniciar.

Quando Secure Boot estiver ativo, siga as instruções locais em:

```text
/usr/share/doc/akmods/README.secureboot
```

O script não presume que uma tela de enrollment MOK aparecerá automaticamente.

## Pós-instalação

1. Feche e abra o terminal para carregar Zsh, mise e SDKMAN.
2. Preencha `~/.config/ai-agents/endpoints.zsh`, se necessário.
3. Autentique Claude, Kiro e Pi manualmente.
4. Instale as versões Java desejadas pelo SDKMAN.
5. Reinicie apenas se houve instalação de driver NVIDIA/kernel ou se desejar aplicar imediatamente a troca do shell padrão.
