#!/usr/bin/env bash

install_maintenance_automation() {
  log_info "Configurando manutenção automática do Fedora e do mise..."
  configure_installonly_limit
  install_system_maintenance
  install_user_maintenance
}

configure_installonly_limit() {
  local config=/etc/dnf/dnf.conf
  if grep -qE '^[[:space:]]*installonly_limit[[:space:]]*=[[:space:]]*2[[:space:]]*$' "$config"; then
    log_info "DNF já está configurado para manter dois kernels."
    return 0
  fi

  if (( DRY_RUN )); then
    log_info "Configuraria installonly_limit=2 em $config"
    return 0
  fi

  if grep -qE '^[[:space:]]*installonly_limit[[:space:]]*=' "$config"; then
    sudo sed -Ei 's/^[[:space:]]*installonly_limit[[:space:]]*=.*/installonly_limit=2/' "$config"
  elif grep -qE '^\[main\][[:space:]]*$' "$config"; then
    sudo sed -i '/^\[main\][[:space:]]*$/a installonly_limit=2' "$config"
  else
    printf '\n[main]\ninstallonly_limit=2\n' | sudo tee -a "$config" >/dev/null
  fi
}

install_system_maintenance() {
  run sudo install -m 0755 "$ROOT_DIR/config/systemd/system/fedora-maintenance" \
    /usr/local/sbin/fedora-maintenance
  run sudo install -m 0644 "$ROOT_DIR/config/systemd/system/fedora-maintenance.service" \
    /etc/systemd/system/fedora-maintenance.service
  run sudo install -m 0644 "$ROOT_DIR/config/systemd/system/fedora-maintenance.timer" \
    /etc/systemd/system/fedora-maintenance.timer

  # Não deixe dois mecanismos concorrentes de atualização automática.
  if systemctl list-unit-files dnf5-automatic.timer --no-legend 2>/dev/null | grep -q dnf5-automatic; then
    run sudo systemctl disable --now dnf5-automatic.timer
  fi
  if systemctl list-unit-files dnf-automatic.timer --no-legend 2>/dev/null | grep -q dnf-automatic; then
    run sudo systemctl disable --now dnf-automatic.timer
  fi

  run sudo systemctl daemon-reload
  run sudo systemctl enable --now fedora-maintenance.timer
}

install_user_maintenance() {
  install_config "$ROOT_DIR/config/systemd/user/mise-maintenance.service" \
    "$HOME/.config/systemd/user/mise-maintenance.service" 0644
  install_config "$ROOT_DIR/config/systemd/user/mise-maintenance.timer" \
    "$HOME/.config/systemd/user/mise-maintenance.timer" 0644
  run systemctl --user daemon-reload
  run systemctl --user enable --now mise-maintenance.timer
}
