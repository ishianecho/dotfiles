#!/usr/bin/env bash

set -euo pipefail

config="${XDG_CONFIG_HOME:-$HOME/.config}/proxy/config"
[ -f "$config" ] || exit 0

proxy="$HOME/.local/bin/proxy"
[ -x "$proxy" ] || {
  echo "Warning: proxy is not installed; skipping proxy synchronization." >&2
  exit 0
}

"$proxy" sync
