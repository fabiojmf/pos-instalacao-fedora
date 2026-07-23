#!/usr/bin/env bash

install_nvidia_if_present() {
  if ! lspci | grep -qi NVIDIA; then
    log_info "Nenhuma GPU NVIDIA detectada."
    return 0
  fi

  log_info "GPU NVIDIA detectada; configurando RPM Fusion e driver proprietário..."
  local fedora_version
  fedora_version=$(rpm -E %fedora)
  run sudo dnf install -y \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm" \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_version}.noarch.rpm"
  run sudo dnf upgrade --refresh -y
  run sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda

  log_warn "Aguarde a compilação do módulo akmod antes de reiniciar."
  if command_exists mokutil && mokutil --sb-state 2>/dev/null | grep -qi enabled; then
    log_warn "Secure Boot está ativo. Consulte /usr/share/doc/akmods/README.secureboot antes de reiniciar."
  fi
}
