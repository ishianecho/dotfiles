#!/usr/bin/env bash

pkg_name="extension-manager"

install_extension_manager() {
  if check_installed gnome-shell-extension-manager; then
    echo "Extension Manager is already installed"
  else
    try_package_manager gnome-shell-extension-manager ||
      echo "Warning: Could not install Extension Manager automatically. Install gnome-shell-extension-manager (extension-manager on Arch) manually if needed." >&2
  fi

  return 0
}

install_extension_manager
