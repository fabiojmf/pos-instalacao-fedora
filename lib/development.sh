#!/usr/bin/env bash

install_development() {
  install_development_packages
  install_neovim
  install_kubectl
  install_intellij
  install_dbeaver
}

install_development_packages() {
  log_info "Instalando ferramentas de desenvolvimento..."
  run sudo dnf install -y @development-tools neovim python3-neovim maven ripgrep
}

install_neovim() {
  if [[ -d $HOME/.config/nvim ]]; then
    log_info "Configuração do Neovim já existe; preservando."
  else
    clone_or_update https://github.com/LazyVim/starter "$HOME/.config/nvim"
    if (( ! DRY_RUN )); then
      rm -rf "$HOME/.config/nvim/.git"
    fi
  fi
}

install_kubectl() {
  if command_exists kubectl; then
    log_info "kubectl já está instalado."
    return 0
  fi

  local minor=${KUBERNETES_MINOR:-v1.34}
  log_info "Instalando kubectl do canal Kubernetes $minor..."
  if (( DRY_RUN )); then
    log_info "Criaria /etc/yum.repos.d/kubernetes.repo e instalaria kubectl."
    return 0
  fi
  cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo >/dev/null
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/${minor}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/${minor}/rpm/repodata/repomd.xml.key
EOF
  sudo dnf install -y kubectl
}

install_intellij() {
  if compgen -G '/opt/idea-IU-*' >/dev/null; then
    log_info "IntelliJ IDEA Ultimate já está instalado em /opt."
    create_intellij_launcher
    return 0
  fi

  log_info "Instalando a versão mais recente do IntelliJ IDEA Ultimate..."
  if (( DRY_RUN )); then
    log_info "Baixaria o IntelliJ pela API oficial da JetBrains."
    return 0
  fi

  local api='https://data.services.jetbrains.com/products/releases?code=IIU&latest=true&type=release'
  local metadata url checksum_url expected_checksum tmp archive
  metadata=$(curl -fsSL "$api")
  url=$(jq -r '.IIU[0].downloads.linux.link' <<<"$metadata")
  checksum_url=$(jq -r '.IIU[0].downloads.linux.checksumLink' <<<"$metadata")
  [[ -n $url && $url != null ]] || die "A API da JetBrains não retornou o download do IntelliJ."
  [[ -n $checksum_url && $checksum_url != null ]] || die "A API da JetBrains não retornou o checksum do IntelliJ."

  tmp=$(mktemp -d)
  archive=$tmp/idea.tar.gz
  curl -fL "$url" -o "$archive" || { rm -rf "$tmp"; die "Falha no download do IntelliJ."; }
  expected_checksum=$(curl -fsSL "$checksum_url" | awk '{print $1}') || {
    rm -rf "$tmp"
    die "Falha ao obter o checksum do IntelliJ."
  }
  [[ $expected_checksum =~ ^[[:xdigit:]]{64}$ ]] || {
    rm -rf "$tmp"
    die "Checksum inválido retornado pela JetBrains."
  }
  printf '%s  %s\n' "$expected_checksum" "$archive" | sha256sum --check --status || {
    rm -rf "$tmp"
    die "O download do IntelliJ não corresponde ao checksum oficial."
  }

  sudo tar -xzf "$archive" -C /opt || { rm -rf "$tmp"; die "Falha ao extrair o IntelliJ."; }
  rm -rf "$tmp"
  create_intellij_launcher
}

create_intellij_launcher() {
  local idea_dir
  idea_dir=$(find /opt -maxdepth 1 -type d -name 'idea-IU-*' -printf '%f\n' 2>/dev/null | sort -V | tail -1)
  [[ -n $idea_dir ]] || return 0
  local destination=$HOME/.local/share/applications/jetbrains-idea.desktop
  if (( DRY_RUN )); then
    log_info "Criaria launcher do IntelliJ em $destination"
    return 0
  fi
  mkdir -p "$(dirname "$destination")"
  cat >"$destination" <<EOF
[Desktop Entry]
Type=Application
Name=IntelliJ IDEA Ultimate Edition
Icon=/opt/${idea_dir}/bin/idea.svg
Exec="/opt/${idea_dir}/bin/idea.sh" %f
Comment=Capable and Ergonomic IDE for JVM
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-idea
EOF
  chmod 0644 "$destination"
}

install_dbeaver() {
  if rpm -q dbeaver-ce >/dev/null 2>&1; then
    log_info "DBeaver CE já está instalado."
  else
    log_info "Instalando DBeaver CE pelo RPM oficial..."
    run sudo dnf install -y https://dbeaver.io/files/dbeaver-ce-latest-stable.x86_64.rpm
  fi
}
