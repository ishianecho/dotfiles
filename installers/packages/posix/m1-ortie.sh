#!/usr/bin/env bash

pkg_name="ortie"

is_arch_family() {
  case "$system_release" in
  arch | manjaro | endeavouros | garuda | artix | cachyos) return 0 ;;
  *) return 1 ;;
  esac
}

install_ortie() {
  if check_installed ortie; then
    return 0
  fi

  check_installed secret-tool || try_package_manager libsecret-tools

  if is_arch_family && [ "$pkg_manager" = "pacman" ] && command -v paru >/dev/null 2>&1; then
    if paru -S --needed --noconfirm ortie; then
      return 0
    fi
  fi

  if command -v cargo >/dev/null 2>&1; then
    if cargo install ortie; then
      return 0
    fi
  fi

  echo "Warning: Could not install ortie; requires paru (AUR) or cargo." >&2
}

install_ortie
