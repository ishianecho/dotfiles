#!/usr/bin/env bash

pkg_name="mutagen"

mutagen_release_asset() {
  case "${arch}-${os}" in
  amd64-linux) echo "mutagen_linux_amd64" ;;
  arm64-linux) echo "mutagen_linux_arm64" ;;
  amd64-darwin) echo "mutagen_darwin_amd64" ;;
  arm64-darwin) echo "mutagen_darwin_arm64" ;;
  *) echo "" ;;
  esac
}

mutagen_latest_version() {
  curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/mutagen-io/mutagen/releases/latest | sed 's|.*/tag/||'
}

install_mutagen() {
  if check_installed mutagen; then
    return 0
  fi

  local asset version
  asset="$(mutagen_release_asset)"
  if [ -z "$asset" ]; then
    echo "Skipping mutagen: no release asset for this platform"
    return 0
  fi
  version="$(mutagen_latest_version)" || version=""
  if [ -z "$version" ]; then
    echo "Warning: Could not resolve latest mutagen release." >&2
    return 0
  fi

  local temp_dir="/tmp/mutagen.$$"
  mkdir -p "$temp_dir" || return 1

  if ! download_extract "https://github.com/mutagen-io/mutagen/releases/download/$version/${asset}_${version}.tar.gz" "$temp_dir"; then
    rm -rf "$temp_dir"
    echo "Warning: Could not install mutagen." >&2
    return 0
  fi

  local bin_dir="$USR_HOME/bin"
  mkdir -p "$bin_dir"

  local tool tmp
  for tool in mutagen mutagen-agent; do
    tmp="$bin_dir/$tool.tmp.$$"
    if [ -f "$temp_dir/$tool" ] && cp "$temp_dir/$tool" "$tmp" && chmod +x "$tmp" && mv "$tmp" "$bin_dir/$tool"; then
      echo "Installed $tool"
    else
      rm -f "$tmp"
      echo "Warning: $tool was not installed." >&2
    fi
  done

  rm -rf "$temp_dir"
}

install_mutagen
