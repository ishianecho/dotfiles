#!/usr/bin/env bash

pkg_name="linuxqq"

install_linuxqq() {
  if [ "$os" != "linux" ] || ! is_arch_family; then
    echo "Skipping linuxqq: only supported on Arch-based systems"
    return 0
  fi

  check_installed linuxqq && return 0

  try_package_manager linuxqq ||
    echo "Warning: Could not install linuxqq." >&2
}

install_linuxqq
