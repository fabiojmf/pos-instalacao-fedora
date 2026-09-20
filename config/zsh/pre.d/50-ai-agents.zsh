# Diretórios persistentes e configuração privada dos agentes de IA.
export AI_AGENTS_HOME="$HOME/.local/share/ai-agents"
export CLAUDE_CONFIG_DIR="$AI_AGENTS_HOME/claude"
export KIRO_HOME="$AI_AGENTS_HOME/kiro"

[[ -r "$HOME/.config/ai-agents/endpoints.zsh" ]] && source "$HOME/.config/ai-agents/endpoints.zsh"

# O bloco pre do Kiro deve carregar antes do prompt, quando disponível.
[[ -f "$HOME/.local/share/kiro-cli/shell/zshrc.pre.zsh" ]] && \
  builtin source "$HOME/.local/share/kiro-cli/shell/zshrc.pre.zsh"
