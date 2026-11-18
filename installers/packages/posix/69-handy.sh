#!/usr/bin/env bash

pkg_name="ghf"

install_handy() {
  local bin_dir="$HOME/.local/bin"
  mkdir -p "$bin_dir"

  local raw_base="https://raw.githubusercontent.com/ishianecho/bin/main/posix"
  local tool tmp
  for tool in ghf updnvim notify port; do
    if [ -e "$bin_dir/$tool" ]; then
      continue
    fi
    tmp="$bin_dir/$tool.tmp.$$"
    if curl -fsSL "$raw_base/$tool" -o "$tmp" && chmod +x "$tmp" && mv "$tmp" "$bin_dir/$tool"; then
      echo "Installed $tool"
    else
      rm -f "$tmp"
      echo "Warning: $tool was not installed." >&2
    fi
  done
}

install_handy
