#!/usr/bin/env bash

pkg_name="songloft-player"

install_songloft_player() {
  if [ "$os" != "linux" ]; then
    echo "Skipping songloft-player: only supported on Linux"
    return 0
  fi

  if check_installed songloft-player; then
    return 0
  fi

  local install_path="$USR_HOME/bin/songloft-player"
  local temp_install="${install_path}.tmp.$$"

  echo "Installing songloft-player latest..."
  curl_download -o "$temp_install" "https://github.com/songloft-org/songloft-player/releases/latest/download/songloft-linux-x64.AppImage" || {
    rm -f "$temp_install"
    echo "Warning: Could not install songloft-player." >&2
    return 0
  }

  chmod +x "$temp_install" && mv "$temp_install" "$install_path" || {
    rm -f "$temp_install"
    echo "Warning: Could not install songloft-player." >&2
    return 0
  }
}

install_songloft_player
