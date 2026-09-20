#!/usr/bin/env bash

install_vm_guest() {
  log_info "Instalando integrações para o guest KVM/SPICE..."
  run sudo dnf install -y qemu-guest-agent spice-vdagent

  if [[ ! -e /dev/virtio-ports/org.qemu.guest_agent.0 ]]; then
    log_warn "Canal do QEMU Guest Agent ainda não disponível; habilite-o na configuração da VM."
  fi
}
