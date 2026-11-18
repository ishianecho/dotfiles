#!/usr/bin/env bash

pkg_name="proxy"

install_proxy() {
  local bin_dir="$HOME/.local/bin"
  mkdir -p "$bin_dir"

  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  case "$(uname -m)" in
  x86_64) arch=amd64 ;;
  aarch64 | arm64) arch=arm64 ;;
  *)
    echo "Warning: unsupported architecture for bin releases." >&2
    return 0
    ;;
  esac

  local binaries=(proxy xrayctl)
  [ "$os" = "linux" ] && binaries+=(sbctl)
  local release_base="https://github.com/ishianecho/bin/releases/latest/download"
  local tool tmp
  for tool in "${binaries[@]}"; do
    if check_installed "$tool"; then
      continue
    fi
    tmp="$bin_dir/$tool.tmp.$$"
    if curl -fsSL "$release_base/$tool-$os-$arch" -o "$tmp" && chmod +x "$tmp" && mv "$tmp" "$bin_dir/$tool"; then
      echo "Installed $tool"
    else
      rm -f "$tmp"
      echo "Warning: $tool was not installed." >&2
    fi
  done
}

install_proxy
