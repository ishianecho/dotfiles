#!/usr/bin/env bash

pkg_name="gaming-libs"

install_gaming_libs() {
  if [ "$os" != "linux" ]; then
    echo "Skipping gaming libraries: only supported on Linux"
    return 0
  fi

  local packages=()
  case "$pkg_manager" in
  pacman)
    packages=(
      vulkan-icd-loader
      lib32-vulkan-icd-loader
      lib32-mesa
      lib32-alsa-lib
      lib32-alsa-plugins
      lib32-libpulse
      gamemode
      lib32-gamemode
      libayatana-appindicator
    )
    ;;
  apt)
    packages=(
      libvulkan1
      libvulkan1:i386
      libgl1:i386
      gamemode
      libayatana-appindicator3-1
    )
    ;;
  dnf)
    packages=(
      vulkan-loader
      vulkan-loader.i686
      mesa-libGL.i686
      gamemode
      libayatana-appindicator-gtk3
    )
    ;;
  *)
    echo "Warning: Could not install gaming libraries automatically. Install Vulkan loaders (32-bit and 64-bit), libayatana-appindicator, and gamemode manually if needed." >&2
    return 0
    ;;
  esac

  if [ "$pkg_manager" = "apt" ] && [ "$has_sudo" = "true" ]; then
    if ! dpkg --print-foreign-architectures 2>/dev/null | grep -qx i386; then
      sudo dpkg --add-architecture i386
      apt_update_done=false
    fi
  fi

  local package missing=()
  for package in "${packages[@]}"; do
    if ! check_installed "$package"; then
      missing+=("$package")
    fi
  done

  if [ ${#missing[@]} -eq 0 ]; then
    echo "Gaming libraries are already installed"
    return 0
  fi

  if try_package_manager "${missing[@]}"; then
    return 0
  fi

  echo "Warning: Could not install gaming libraries automatically. Install them manually if needed." >&2
  return 0
}

install_gaming_libs
