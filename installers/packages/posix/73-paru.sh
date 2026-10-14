#!/usr/bin/env bash

pkg_name="paru"

install_paru() {
  if [ "$os" != "linux" ] || ! is_arch_family; then
    echo "Skipping paru: only supported on Arch-based systems"
    return 0
  fi

  if check_installed paru; then
    return 0
  fi

  if ! command -v makepkg >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
    echo "Warning: makepkg or git not found; install base-devel and git first." >&2
    return 0
  fi

  echo "Building paru from source..."

  local build_dir="$SRC_HOME/paru"
  rm -rf "$build_dir"
  mkdir -p "$(dirname "$build_dir")" || return 0

  if ! git clone https://aur.archlinux.org/paru.git "$build_dir"; then
    echo "Warning: Could not clone paru from AUR." >&2
    rm -rf "$build_dir"
    return 0
  fi

  if ! (cd "$build_dir" && makepkg -si --noconfirm --needed); then
    echo "Warning: Could not build paru from source." >&2
    rm -rf "$build_dir"
    return 0
  fi

  rm -rf "$build_dir"
}

install_paru
