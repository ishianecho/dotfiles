#!/usr/bin/env bash

pkg_name="xray"

xray_release_asset() {
  case "${arch}-${os}" in
  amd64-linux) echo "Xray-linux-64.zip" ;;
  arm64-linux) echo "Xray-linux-arm64-v8a.zip" ;;
  *) echo "" ;;
  esac
}

install_xray() {
  if [ "$os" != "linux" ]; then
    echo "Skipping xray: only supported on Linux"
    return 0
  fi

  if check_installed xray; then
    return 0
  fi

  if [ "$pkg_manager" = "pacman" ] && is_arch_family; then
    if try_package_manager xray-bin; then
      return 0
    fi
  elif [ "$pkg_manager" = "apt" ] || [ "$pkg_manager" = "dnf" ]; then
    if try_package_manager xray; then
      return 0
    fi
  fi

  local asset
  asset="$(xray_release_asset)"
  if [ -z "$asset" ]; then
    echo "Warning: No Xray release asset for this platform." >&2
    return 0
  fi

  download_binary xray latest "https://github.com/XTLS/Xray-core/releases/latest/download/$asset" xray "$USR_HOME/bin/xray" ||
    echo "Warning: Could not install xray." >&2
}

install_xray
