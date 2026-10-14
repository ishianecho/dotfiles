#!/usr/bin/env bash

pkg_name="discord"

install_discord() {
  if [ "$os" != "linux" ] || ! is_arch_family; then
    echo "Skipping discord: only supported on Arch-based systems"
    return 0
  fi

  check_installed discord && return 0

  try_package_manager discord ||
    echo "Warning: Could not install discord." >&2
}

install_discord
