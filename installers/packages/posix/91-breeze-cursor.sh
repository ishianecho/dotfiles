#!/usr/bin/env bash

pkg_name="breeze-cursor-theme"

install_breeze_cursor() {
  if [ "$os" != "linux" ]; then
    return 0
  fi

  if check_installed "$pkg_name"; then
    echo "breeze-cursor-theme is already installed"
    return 0
  fi

  if try_package_manager breeze-cursor-theme; then
    return 0
  fi

  echo "Warning: Could not install breeze-cursor-theme automatically. Install it manually if needed." >&2
  return 0
}

install_breeze_cursor
