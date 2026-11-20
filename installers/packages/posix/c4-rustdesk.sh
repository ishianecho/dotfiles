#!/usr/bin/env bash

pkg_name="rustdesk-bin"

install_rustdesk() {
  if [ "$os" != "linux" ] || ! is_arch_family; then
    echo "Skipping rustdesk: only supported on Arch-based systems"
    return 0
  fi

  check_installed rustdesk-bin && return 0

  try_package_manager rustdesk-bin ||
    echo "Warning: Could not install rustdesk." >&2
}

install_rustdesk
