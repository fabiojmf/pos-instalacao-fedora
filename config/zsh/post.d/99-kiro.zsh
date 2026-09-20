# O bloco post do Kiro deve carregar por último, quando disponível.
[[ -f "$HOME/.local/share/kiro-cli/shell/zshrc.post.zsh" ]] && \
  builtin source "$HOME/.local/share/kiro-cli/shell/zshrc.post.zsh"
