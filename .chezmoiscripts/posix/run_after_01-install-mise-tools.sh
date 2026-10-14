#!/usr/bin/env bash

set -euo pipefail

mise_path="${MISE_INSTALL_PATH:-$HOME/.local/bin/mise}"
mise_config="${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mise}/config.toml"

if [ ! -x "$mise_path" ]; then
  echo "Warning: mise is not installed; skipping configured mise tools." >&2
  exit 0
fi

if [ ! -f "$mise_config" ]; then
  echo "Warning: mise config is not installed; skipping configured mise tools." >&2
  exit 0
fi

echo "Installing tools from $mise_config..."
(cd "$HOME" && "$mise_path" install)
