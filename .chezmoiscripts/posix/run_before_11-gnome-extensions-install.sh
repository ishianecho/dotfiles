#!/usr/bin/env bash

set -euo pipefail

command -v gnome-shell >/dev/null 2>&1 || exit 0
command -v curl >/dev/null 2>&1 || exit 0
command -v unzip >/dev/null 2>&1 || exit 0

extensions_dir="${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions"
shell_major="$(gnome-shell --version | awk '{print $3}')"
shell_major="${shell_major%%.*}"

install_extension() {
  local uuid="$1"
  local tmp_dir="/tmp/${uuid}.$$"

  if [ -f "$extensions_dir/$uuid/metadata.json" ]; then
    return 0
  fi

  echo "Installing GNOME Shell extension $uuid for shell $shell_major..."
  mkdir -p "$tmp_dir" "$extensions_dir/$uuid"
  if ! curl -fL --progress-bar -o "$tmp_dir/ext.zip" \
    "https://extensions.gnome.org/download-extension/${uuid}.shell-extension.zip?shell_version=${shell_major}"; then
    echo "Warning: Could not download $uuid from extensions.gnome.org." >&2
    rm -rf "$tmp_dir" "$extensions_dir/$uuid"
    return 0
  fi

  unzip -oq "$tmp_dir/ext.zip" -d "$extensions_dir/$uuid"
  rm -rf "$tmp_dir"

  if command -v jq >/dev/null 2>&1; then
    jq --arg v "$shell_major" '.["shell-version"] |= (. + [$v] | unique)' \
      "$extensions_dir/$uuid/metadata.json" >"$extensions_dir/$uuid/metadata.json.tmp" &&
      mv "$extensions_dir/$uuid/metadata.json.tmp" "$extensions_dir/$uuid/metadata.json"
  fi
}

install_extension "just-perfection-desktop@just-perfection"
install_extension "kimpanel@kde.org"
