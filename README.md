# Pós-instalação do Fedora

Configuração pessoal e idempotente para uma instalação nova do Fedora Workstation. O projeto instala o ambiente de terminal, desenvolvimento e agentes de IA utilizado por Fabio.

> Revise o código antes de executar. O perfil padrão atualiza o sistema, remove aplicativos e instala drivers e ferramentas.

## Principais escolhas

- **Terminal:** WezTerm nightly, Zsh, Oh My Zsh, Powerlevel10k e plugins, separados entre os perfis `terminal` e `shell`.
- **Node:** somente pelo mise; pacotes Node/npm em RPM são removidos pelo perfil `toolchains`.
- **Containers:** Podman e Podman Compose ficam em um perfil independente, utilizável tanto no host quanto na VM.
- **Virtualização:** KVM, libvirt e virt-manager ficam em um perfil exclusivo do host.
- **Java:** o Java gerenciado pelo Fedora não é alterado. O perfil `toolchains` instala apenas o SDKMAN; versões adicionais são escolhidas manualmente.
- **Agentes:** Claude Code, Pi e Herdr são gerenciados pelo mise; Kiro CLI é instalado e atualizado manualmente.
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

Sem argumentos, o instalador usa o preset `host`. Para inspecionar as ações sem alterar a máquina:

```bash
./install.sh --dry-run
./install.sh --preset work-vm --dry-run
```

### Presets

| Preset | Finalidade | Perfis |
|---|---|---|
| `host` | Host pessoal com Podman e KVM, sem ferramentas corporativas | `base,cleanup,shell,terminal,desktop,browser,personal,containers,virtualization,nvidia,maintenance` |
| `work-vm` | VM corporativa de desenvolvimento | `base,cleanup,shell,terminal,desktop,browser,toolchains,containers,development,ai,vm-guest,maintenance` |
| `standalone` | Máquina física para uso pessoal e profissional, sem KVM por padrão | `base,cleanup,shell,terminal,desktop,browser,personal,toolchains,containers,development,ai,nvidia,maintenance` |

Uso recomendado:

```bash
./install.sh --preset host
./install.sh --preset work-vm
./install.sh --preset standalone
```

Um perfil pode complementar um preset. Por exemplo, para manter KVM no cenário standalone:

```bash
./install.sh --preset standalone --profile virtualization
```

### Perfis

| Perfil | Conteúdo |
|---|---|
| `base` | pré-requisitos, atualização do Fedora e Flathub |
| `cleanup` | remoção dos aplicativos GNOME e LibreOffice não desejados |
| `shell` | Zsh, Oh My Zsh, Powerlevel10k e plugins |
| `terminal` | WezTerm nightly, JetBrains Mono e MesloLGS NF |
| `desktop` | preferências GNOME e favoritos compatíveis com os perfis selecionados |
| `browser` | Google Chrome |
| `personal` | Bitwarden |
| `toolchains` | SDKMAN, mise e Node LTS; remove Node/npm fornecidos por RPM |
| `containers` | Podman e Podman Compose |
| `development` | ferramentas de compilação, Neovim/LazyVim, Maven, kubectl, IntelliJ e DBeaver |
| `ai` | layout persistente, Claude, Pi, Herdr e pi-web-access; prepara o diretório do Kiro sem instalá-lo |
| `virtualization` | KVM/QEMU, libvirt, virt-manager, UEFI, TPM virtual e guestfs-tools |
| `vm-guest` | QEMU Guest Agent e integração de desktop SPICE para a VM |
| `nvidia` | RPM Fusion e driver NVIDIA, somente quando a GPU é detectada |
| `maintenance` | atualização do Fedora, autoremove e retenção de dois kernels; atualiza mise somente quando instalado |
| `all` | todos os perfis; destinado a testes ou uso deliberado |

Sem `--preset`, `--profile` seleciona exatamente a lista informada. Recomenda-se incluir `base` em instalações novas.

Os presets são aditivos: instalam e configuram o ambiente selecionado, mas não desinstalam componentes pertencentes a outro preset. Ao migrar uma máquina `standalone` para `host`, a remoção das ferramentas corporativas deve ser feita como uma etapa separada e deliberada.

## Manutenção automática

O perfil `maintenance` instala dois timers independentes:

```text
fedora-maintenance.timer (sistema/root)
├── dnf upgrade --refresh -y
├── dnf remove --oldinstallonly --limit=2 -y
└── dnf autoremove -y

mise-maintenance.timer (usuário, somente quando mise está instalado)
├── mise self-update -y
├── mise upgrade -y
└── mise prune --yes --tools
```

O DNF recebe `installonly_limit=2`, mantendo o kernel atual e um fallback. O comando `--oldinstallonly` não remove o kernel em execução; temporariamente podem existir três versões até o próximo boot e a manutenção seguinte.

O timer do Fedora só executa quando o computador está conectado à energia AC. Ambos são agendados diariamente para as 10h, com um pequeno atraso aleatório, e são persistentes: se a máquina estiver desligada nesse horário, executam depois que ela voltar a ficar disponível.

O perfil também configura o `systemd-journald` para reter logs por no máximo dois dias. Essa retenção é global: vale para o sistema inteiro, inclusive para os logs dos serviços de manutenção. Na instalação, o journal é rotacionado e os arquivos anteriores ao período são removidos imediatamente.

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

## Containers e virtualização

O perfil `containers` instala Podman e Podman Compose sem apagar imagens, contêineres ou volumes existentes. Ele deve ser selecionado tanto no host pessoal quanto na VM quando houver uso de contêineres.

O perfil `virtualization` é destinado ao host físico. Ele instala o grupo de virtualização do Fedora, `edk2-ovmf`, `swtpm` e `guestfs-tools`, habilita o socket do libvirt e ativa a rede NAT padrão. Ele não cria VMs nem altera discos automaticamente.

O perfil `vm-guest` instala `qemu-guest-agent` e `spice-vdagent` dentro da VM. O canal do QEMU Guest Agent também precisa estar habilitado na configuração da VM no virt-manager.

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

O Claude usa `CLAUDE_CONFIG_DIR`; Kiro usa `KIRO_HOME`. Históricos, sessões, autenticação e caches permanecem locais e não são versionados. O diretório e o link do Kiro são preparados para preservar o layout personalizado, mas o binário não é instalado pelo script.

### Ferramentas gerenciadas pelo mise

A configuração global resultante contém, em essência:

```toml
[tools]
node = "lts"
claude-code = "latest"
"github:ogulcancelik/herdr" = "latest"
"npm:@earendil-works/pi-coding-agent" = "latest"
```

Atualize essas ferramentas exclusivamente pelo mise:

```bash
mise outdated
mise upgrade
```

Não use `claude update` ou `herdr update` para instalações controladas pelo mise. O auto-updater do Claude é desabilitado no template inicial.

### Kiro CLI

O Kiro CLI não é baixado, instalado ou atualizado por este projeto. Sua instalação é manual, usando o método oficial escolhido pelo usuário. O script apenas prepara `KIRO_HOME`, o link `~/.kiro` e carregamentos condicionais da integração de shell; eles não causam erro quando o Kiro está ausente.

Depois de instalado manualmente, o Kiro continua usando seu próprio mecanismo de atualização:

```bash
kiro-cli update
```

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

Depois da instalação, autentique manualmente Claude e Pi:

```bash
claude
pi
```

A instalação e autenticação do Kiro são etapas manuais independentes deste projeto.

## Java e SDKMAN

O perfil `toolchains` instala o SDKMAN, mas não instala, remove, registra ou seleciona nenhuma versão Java. O Maven instalado pelo Fedora pode trazer uma dependência OpenJDK, que permanece sob controle do DNF.

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
    ├── zshrc
    ├── pre.d/50-ai-agents.zsh
    └── post.d/
        ├── 20-toolchains.zsh
        └── 99-kiro.zsh
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
3. Autentique Claude e Pi manualmente; instale e configure o Kiro separadamente, se desejar.
4. Instale as versões Java desejadas pelo SDKMAN.
5. Reinicie apenas se houve instalação de driver NVIDIA/kernel ou se desejar aplicar imediatamente a troca do shell padrão.
