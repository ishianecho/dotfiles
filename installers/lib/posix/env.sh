#!/usr/bin/env bash

system_type="${DOTS_SYSTEM_TYPE:-unknown}"
system_release="${DOTS_SYSTEM_RELEASE:-unknown}"
kernel="$(uname | tr '[:upper:]' '[:lower:]')"
os="$kernel"
case "$kernel" in
  mingw* | msys* | cygwin*)
    os="windows"
    if [ -n "${USERPROFILE:-}" ]; then
      HOME="$(cygpath -u "$USERPROFILE")"
      export HOME
    fi
    ;;
esac
export os

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export USR_HOME="${USR_HOME:-$HOME/.local}"
export SRC_HOME="${SRC_HOME:-$XDG_CACHE_HOME/dots-src}"

export MISE_CONFIG_DIR="${MISE_CONFIG_DIR:-$XDG_CONFIG_HOME/mise}"
export MISE_DATA_DIR="${MISE_DATA_DIR:-$XDG_DATA_HOME/mise}"
export MISE_CACHE_DIR="${MISE_CACHE_DIR:-$XDG_CACHE_HOME/mise}"
export MISE_STATE_DIR="${MISE_STATE_DIR:-$XDG_STATE_HOME/mise}"
if [ "${MISE_INSTALL_PATH:-}" = "" ]; then
  if [ "$os" = "windows" ]; then
    MISE_INSTALL_PATH="$USR_HOME/bin/mise.exe"
  else
    MISE_INSTALL_PATH="$USR_HOME/bin/mise"
  fi
fi
export MISE_INSTALL_PATH

export CODEX_HOME="${CODEX_HOME:-$XDG_CONFIG_HOME/codex}"
export CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$XDG_CONFIG_HOME/claude}"
export CC_SWITCH_CONFIG_DIR="$XDG_CONFIG_HOME/cc-switch"
export SERENA_HOME="${SERENA_HOME:-$XDG_CONFIG_HOME/serena}"
export GH_CONFIG_DIR="${GH_CONFIG_DIR:-$XDG_CONFIG_HOME/gh}"
export PNPM_HOME="${PNPM_HOME:-$XDG_DATA_HOME/pnpm}"
export NPM_CONFIG_USERCONFIG="${NPM_CONFIG_USERCONFIG:-$XDG_CONFIG_HOME/npm/npmrc}"
export NPM_CONFIG_CACHE="${NPM_CONFIG_CACHE:-$XDG_CACHE_HOME/npm}"
export GOPATH="${GOPATH:-$XDG_DATA_HOME/go}"
export GOCACHE="${GOCACHE:-$XDG_CACHE_HOME/go-build}"
export CARGO_HOME="${CARGO_HOME:-$XDG_DATA_HOME/cargo}"
export RUSTUP_HOME="${RUSTUP_HOME:-$XDG_DATA_HOME/rustup}"
export FZF_HOME="${FZF_HOME:-$XDG_DATA_HOME/fzf}"
if [ "$os" != "windows" ]; then
  export UV_PYTHON_BIN_DIR="${UV_PYTHON_BIN_DIR:-$XDG_DATA_HOME/uv/bin}"
fi

proxy_config="$XDG_CONFIG_HOME/proxy/config"
if [ -r "$proxy_config" ]; then
  . "$proxy_config"
  PROXY_HTTP="${PROXY_HTTP:-}"
  PROXY_SOCKS="${PROXY_SOCKS:-}"
  PROXY_NO_PROXY="${PROXY_NO_PROXY:-}"
  if [ -n "$PROXY_HTTP" ]; then
    export HTTP_PROXY="$PROXY_HTTP" HTTPS_PROXY="$PROXY_HTTP"
    export http_proxy="$PROXY_HTTP" https_proxy="$PROXY_HTTP"
  else
    unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
  fi
  if [ -n "$PROXY_SOCKS" ]; then
    export ALL_PROXY="$PROXY_SOCKS" all_proxy="$PROXY_SOCKS"
  else
    unset ALL_PROXY all_proxy
  fi
  if [ -n "$PROXY_HTTP" ] || [ -n "$PROXY_SOCKS" ]; then
    export NO_PROXY="${PROXY_NO_PROXY:-localhost,127.0.0.1,::1}"
    export no_proxy="$NO_PROXY"
  else
    unset NO_PROXY no_proxy
  fi
  unset proxy_config PROXY_HTTP PROXY_SOCKS PROXY_NO_PROXY
fi

arch="$(uname -m)"
[ "$arch" = "x86_64" ] && arch=amd64
export arch

is_wsl=false
case "$(uname -r 2> /dev/null)" in
  *microsoft* | *Microsoft* | *WSL*) is_wsl=true ;;
esac
[ -n "${WSL_DISTRO_NAME:-}" ] && is_wsl=true
export is_wsl

pkg_manager=""
case "$system_release" in
  arch | manjaro | endeavouros | garuda | artix | cachyos)
    if command -v pacman > /dev/null 2>&1; then
      pkg_manager="pacman"
    fi
    ;;
esac
if [ -z "$pkg_manager" ] && [ -n "${TERMUX_VERSION:-}" ] && command -v pkg > /dev/null 2>&1; then
  pkg_manager="termux"
fi
if [ -z "$pkg_manager" ] && command -v apt-get > /dev/null 2>&1; then
  pkg_manager="apt"
fi
if [ -z "$pkg_manager" ] && command -v dnf > /dev/null 2>&1; then
  pkg_manager="dnf"
fi
if [ -z "$pkg_manager" ] && command -v pacman > /dev/null 2>&1; then
  pkg_manager="pacman"
fi
if [ -z "$pkg_manager" ] && [ "$os" = "darwin" ] && command -v brew > /dev/null 2>&1; then
  pkg_manager="brew"
fi
export pkg_manager
export system_type
export system_release

has_sudo=false
if [ "$pkg_manager" != "" ] && command -v sudo > /dev/null 2>&1; then
  has_sudo=true
fi
export has_sudo

export PATH="$USR_HOME/bin:$PNPM_HOME/bin:$PNPM_HOME:$FZF_HOME/bin:$CARGO_HOME/bin:$GOPATH/bin:$PATH"

if [ "$os" = "darwin" ]; then
  if [ -x /opt/homebrew/bin/brew ]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
  elif [ -x /usr/local/bin/brew ]; then
    export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
  fi
fi

if [ -x "$PNPM_HOME/node" ]; then
  npm_global_bin="$(dirname "$PNPM_HOME")/bin"
  if [ -d "$npm_global_bin" ]; then
    case ":$PATH:" in
    *":$npm_global_bin:"*) ;;
    *) PATH="$npm_global_bin:$PATH" && export PATH ;;
    esac
  fi
  unset npm_global_bin
fi

mkdir -p "$SRC_HOME" || exit 1
mkdir -p "$HOME/.local/bin" || exit 1
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME" \
  "$MISE_CONFIG_DIR" "$MISE_DATA_DIR" "$MISE_CACHE_DIR" "$MISE_STATE_DIR" \
  "$CODEX_HOME" "$CLAUDE_CONFIG_DIR" "$GH_CONFIG_DIR" "$GOPATH" \
  "$CARGO_HOME" "$RUSTUP_HOME" "$PNPM_HOME" \
  "$XDG_CONFIG_HOME/npm" "$XDG_CACHE_HOME/npm" \
  "$SERENA_HOME" || exit 1
