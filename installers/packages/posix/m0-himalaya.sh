#!/usr/bin/env bash

pkg_name="himalaya"

himalaya_release_asset() {
  case "${arch}-${os}" in
  amd64-linux) echo "himalaya.x86_64-linux.tgz" ;;
  aarch64-linux) echo "himalaya.aarch64-linux.tgz" ;;
  amd64-darwin) echo "himalaya.x86_64-darwin.tgz" ;;
  aarch64-darwin) echo "himalaya.aarch64-darwin.tgz" ;;
  *) echo "" ;;
  esac
}

install_himalaya() {
  if check_installed himalaya; then
    return 0
  fi

  if try_package_manager "$pkg_name"; then
    return 0
  fi

  local asset
  asset="$(himalaya_release_asset)"
  if [ -z "$asset" ]; then
    echo "Warning: No himalaya release asset for this platform." >&2
    return 0
  fi

  download_binary himalaya latest "https://github.com/pimalaya/himalaya/releases/latest/download/$asset" himalaya "$USR_HOME/bin/himalaya" ||
    echo "Warning: Could not install himalaya." >&2
}

install_himalaya
