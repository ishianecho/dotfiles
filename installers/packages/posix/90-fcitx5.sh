#!/usr/bin/env bash

pkg_name="fcitx5"

install_fcitx5() {
  local packages=()
  local item
  for item in fcitx5 fcitx5-chinese-addons fcitx5-rime librime; do
    check_installed "$item" || packages+=("$item")
  done

  if [ ${#packages[@]} -gt 0 ]; then
    try_package_manager "${packages[@]}" ||
      echo "Warning: Could not install fcitx5 automatically. Install fcitx5, fcitx5-chinese-addons, fcitx5-rime, and librime manually if needed." >&2
  else
    echo "fcitx5, Chinese input, and Rime are already installed"
  fi

  if [ "$pkg_manager" = "pacman" ] && command -v paru >/dev/null 2>&1; then
    if ! pacman -Q rime-frost-git >/dev/null 2>&1; then
      echo "Installing rime-frost-git (白霜拼音) from AUR..."
      paru -S --needed --noconfirm rime-frost-git ||
        echo "Warning: Could not install rime-frost-git from AUR." >&2
    else
      echo "rime-frost-git is already installed"
    fi
  fi

  return 0
}

install_fcitx5
