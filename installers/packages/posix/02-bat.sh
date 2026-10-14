#!/usr/bin/env bash

pkg_name="bat"

install_bat() {
  if check_installed bat; then
    return 0
  fi

  try_package_manager bat ||
    echo "Warning: bat was not installed." >&2
}

install_bat
