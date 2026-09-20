#!/usr/bin/env bash

install_virtualization() {
  log_info "Instalando KVM, libvirt e virt-manager..."
  run sudo dnf install -y \
    @virtualization \
    edk2-ovmf \
    swtpm \
    guestfs-tools

  run sudo systemctl enable --now libvirtd.socket

  if (( DRY_RUN )); then
    log_info "Habilitaria e iniciaria a rede NAT padrão do libvirt."
    return 0
  fi

  if ! sudo virsh net-info default >/dev/null 2>&1; then
    log_warn "A rede padrão do libvirt não foi encontrada; configure-a antes de criar a VM."
    return 0
  fi

  sudo virsh net-autostart default
  if ! sudo virsh net-list --name | grep -qx default; then
    sudo virsh net-start default
  fi
}
