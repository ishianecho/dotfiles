#!/usr/bin/env bash

is_arch_family() {
  case "$system_release" in
  arch | manjaro | endeavouros | garuda | artix | cachyos) return 0 ;;
  *) return 1 ;;
  esac
}

library_pattern() {
  case "$1" in
  libssl-dev) echo "ssl" ;;
  libevent-dev) echo "event" ;;
  libutf8proc-dev) echo "utf8proc" ;;
  libgpg-error-dev) echo "gpg-error" ;;
  libgcrypt20-dev) echo "gcrypt" ;;
  libassuan-dev) echo "assuan" ;;
  libksba-dev) echo "ksba" ;;
  libnpth0-dev) echo "npth" ;;
  libncurses-dev) echo "ncurses" ;;
  *) echo "" ;;
  esac
}

check_installed() {
  local item="$1" brew_package

  command -v "$item" >/dev/null 2>&1 && return 0

  case "$pkg_manager" in
  pacman)
    pacman -Q "$(pacman_package_name "$item")" >/dev/null 2>&1 && return 0
    ;;
  dnf)
    dnf list --installed "$(dnf_package_name "$item")" >/dev/null 2>&1 && return 0
    ;;
  apt)
    dpkg -s "$item" >/dev/null 2>&1 && return 0
    ;;
  brew)
    brew_package="$(brew_package_name "$item")"
    [ -n "$brew_package" ] && brew list "$brew_package" >/dev/null 2>&1 && return 0
    ;;
  esac

  local lib_pattern
  lib_pattern="$(library_pattern "$item")"
  [ -n "$lib_pattern" ] || return 1

  ls "$USR_HOME"/lib/lib${lib_pattern}* >/dev/null 2>&1 ||
    ls "$USR_HOME"/lib64/lib${lib_pattern}* >/dev/null 2>&1 ||
    ls /usr/lib/lib${lib_pattern}* >/dev/null 2>&1 ||
    ls /usr/lib64/lib${lib_pattern}* >/dev/null 2>&1 ||
    ls /usr/local/lib/lib${lib_pattern}* >/dev/null 2>&1 ||
    ls /usr/local/lib64/lib${lib_pattern}* >/dev/null 2>&1 ||
    ls /opt/homebrew/opt/*/lib/lib${lib_pattern}* >/dev/null 2>&1 ||
    ls /opt/homebrew/lib/lib${lib_pattern}* >/dev/null 2>&1
}

curl_download() {
  curl -fL --progress-bar "$@"
}

pkg_lock_file="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/dots-pkg-lock"

pkg_lock() {
  if command -v flock >/dev/null 2>&1; then
    flock "$pkg_lock_file" "$@"
  else
    "$@"
  fi
}

apt_update_done=false
install_via_apt() {
  if [ "$pkg_manager" != "apt" ] || [ "$has_sudo" != "true" ]; then
    return 1
  fi

  echo "Installing via apt: $*"
  if [ "$apt_update_done" != "true" ]; then
    pkg_lock sudo apt-get update || return 1
    apt_update_done=true
  fi
  pkg_lock sudo apt-get install -y "$@"
}

pacman_package_name() {
  case "$1" in
  build-essential) echo "base-devel" ;;
  pkg-config) echo "pkgconf" ;;
  libssl-dev) echo "openssl" ;;
  libevent-dev) echo "libevent" ;;
  libncurses-dev) echo "ncurses" ;;
  libutf8proc-dev) echo "libutf8proc" ;;
  libgpg-error-dev) echo "libgpg-error" ;;
  libgcrypt20-dev) echo "libgcrypt" ;;
  libassuan-dev) echo "libassuan" ;;
  libksba-dev) echo "libksba" ;;
  libnpth0-dev) echo "npth" ;;
  fd-find) echo "fd" ;;
  netcat-openbsd) echo "openbsd-netcat" ;;
  sqlite3) echo "sqlite" ;;
  openssh-client) echo "openssh" ;;
  breeze-cursor-theme) echo "breeze" ;;
  gnome-shell-extension-manager) echo "extension-manager" ;;
  *) echo "$1" ;;
  esac
}

pacman_sync_done=false
install_via_pacman() {
  if [ "$pkg_manager" != "pacman" ]; then
    return 1
  fi

  local package
  local packages=()
  for package in "$@"; do
    packages+=("$(pacman_package_name "$package")")
  done

  local sync_flags=()
  if [ "$pacman_sync_done" != "true" ]; then
    sync_flags=(-y)
    pacman_sync_done=true
  fi

  if [ "$has_sudo" = "true" ]; then
    echo "Installing via pacman: ${packages[*]}"
    if pkg_lock sudo pacman -S "${sync_flags[@]}" --needed --noconfirm "${packages[@]}"; then
      return 0
    fi
  fi

  if command -v paru >/dev/null 2>&1; then
    echo "Installing via paru: ${packages[*]}"
    pkg_lock paru -S "${sync_flags[@]}" --needed --noconfirm "${packages[@]}"
    return $?
  fi

  return 1
}

brew_package_name() {
  case "$1" in
  build-essential) echo "" ;;
  libssl-dev) echo "openssl@3" ;;
  libevent-dev) echo "libevent" ;;
  libncurses-dev) echo "ncurses" ;;
  libutf8proc-dev) echo "utf8proc" ;;
  libgpg-error-dev) echo "libgpg-error" ;;
  libgcrypt20-dev) echo "libgcrypt" ;;
  libassuan-dev) echo "libassuan" ;;
  libksba-dev) echo "libksba" ;;
  libnpth0-dev) echo "npth" ;;
  fd-find) echo "fd" ;;
  sqlite3) echo "sqlite" ;;
  breeze-cursor-theme) echo "" ;;
  fcitx5 | fcitx5-chinese-addons | fcitx5-rime | librime | wl-clipboard | xclip | xray | gnome-shell-extension-manager) echo "" ;;
  *) echo "$1" ;;
  esac
}

install_via_brew() {
  if [ "$pkg_manager" != "brew" ]; then
    return 1
  fi

  local package
  local packages=()
  for package in "$@"; do
    package="$(brew_package_name "$package")"
    [ -n "$package" ] && packages+=("$package")
  done

  if [ ${#packages[@]} -eq 0 ]; then
    return 1
  fi

  echo "Installing via brew: ${packages[*]}"
  pkg_lock brew install "${packages[@]}"
}

dnf_package_name() {
  case "$1" in
  build-essential) echo "@development-tools" ;;
  pkg-config) echo "pkgconf-pkg-config" ;;
  libssl-dev) echo "openssl-devel" ;;
  libevent-dev) echo "libevent-devel" ;;
  libncurses-dev) echo "ncurses-devel" ;;
  libutf8proc-dev) echo "utf8proc-devel" ;;
  libgpg-error-dev) echo "libgpg-error-devel" ;;
  libgcrypt20-dev) echo "libgcrypt-devel" ;;
  libassuan-dev) echo "libassuan-devel" ;;
  libksba-dev) echo "libksba-devel" ;;
  libnpth0-dev) echo "npth-devel" ;;
  netcat-openbsd) echo "nmap-ncat" ;;
  sqlite3) echo "sqlite" ;;
  openssh-client) echo "openssh-clients" ;;
  gnupg) echo "gnupg2" ;;
  *) echo "$1" ;;
  esac
}

install_via_dnf() {
  if [ "$pkg_manager" != "dnf" ] || [ "$has_sudo" != "true" ]; then
    return 1
  fi

  local package
  local packages=()
  for package in "$@"; do
    packages+=("$(dnf_package_name "$package")")
  done

  echo "Installing via dnf: ${packages[*]}"
  pkg_lock sudo dnf install -y "${packages[@]}"
}

try_package_manager() {
  if [ "$pkg_manager" = "apt" ] && [ "$has_sudo" = "true" ]; then
    install_via_apt "$@"
    return $?
  fi
  if [ "$pkg_manager" = "dnf" ] && [ "$has_sudo" = "true" ]; then
    install_via_dnf "$@"
    return $?
  fi
  if [ "$pkg_manager" = "pacman" ]; then
    install_via_pacman "$@"
    return $?
  fi
  if [ "$pkg_manager" = "brew" ]; then
    install_via_brew "$@"
    return $?
  fi
  return 1
}

download_extract() {
  local url="$1"
  local dest_dir="$2"
  shift 2
  local tar_flags=("$@")

  mkdir -p "$dest_dir" || return 1

  local base_archive
  base_archive="$(basename "$url")"

  local extract_flag
  case "$base_archive" in
  *.tar.gz | *.tgz) extract_flag="-z" ;;
  *.tar.xz | *.txz) extract_flag="-J" ;;
  *.tar.bz2 | *.tbz) extract_flag="-j" ;;
  *.tar) extract_flag="" ;;
  esac

  if [ -n "${extract_flag-}" ]; then
    (
      set -o pipefail
      curl_download "$url" |
        tar -x ${extract_flag} -f - ${tar_flags[@]+"${tar_flags[@]}"} -C "$dest_dir"
    ) || return 1
    return 0
  fi

  if [[ "$base_archive" == *.zip ]]; then
    local archive="/tmp/${base_archive}.tmp.$$"
    curl_download -o "$archive" "$url" || return 1
    if command -v unzip >/dev/null 2>&1; then
      unzip -q "$archive" -d "$dest_dir" || {
        rm -f "$archive"
        return 1
      }
    else
      local windows_archive windows_dest
      windows_archive="$(cygpath -w "$archive")"
      windows_dest="$(cygpath -w "$dest_dir")"
      powershell.exe -NoProfile -Command "Expand-Archive -LiteralPath '$windows_archive' -DestinationPath '$windows_dest' -Force" || {
        rm -f "$archive"
        return 1
      }
    fi
    rm -f "$archive"
    return 0
  fi

  echo "Unsupported archive format: $base_archive" >&2
  return 1
}

install_gnu_tool() {
  local name="$1"
  local version="$2"
  local url="$3"
  shift 3
  local configure_args=("$@")

  local src_dir="$SRC_HOME/${name}-${version}"

  echo "Installing ${name} ${version}..."

  download_extract "$url" "$SRC_HOME" || return 1

  cd "$src_dir" || return 1

  local env_vars=()
  local config_flags=()

  for arg in "${configure_args[@]}"; do
    if [[ "$arg" == *"="* ]] && [[ "$arg" != --* ]]; then
      env_vars+=("$arg")
    else
      config_flags+=("$arg")
    fi
  done

  env ${env_vars[@]+"${env_vars[@]}"} ./configure --prefix="$USR_HOME" ${config_flags[@]+"${config_flags[@]}"} &&
    make &&
    make install
}

install_library() {
  local name="$1"
  local version="$2"
  local url="$3"
  shift 3
  local configure_args=("$@")

  export PKG_CONFIG_PATH="$USR_HOME/lib/pkgconfig:$USR_HOME/lib64/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

  install_gnu_tool "$name" "$version" "$url" ${configure_args[@]+"${configure_args[@]}"}
}

download_binary() {
  local name="$1"
  local version="$2"
  local url="$3"
  local binary_path="$4"
  local install_path="$5"

  echo "Installing ${name} ${version}..."

  local temp_dir="/tmp/${name}-${version}.$$"
  mkdir -p "$temp_dir" || return 1

  download_extract "$url" "$temp_dir" || return 1

  local binary_file
  binary_file=$(find "$temp_dir" -name "$(basename "$binary_path")" -type f | head -1)

  if [ -z "$binary_file" ]; then
    binary_file="$temp_dir/$binary_path"
  fi

  if [ -f "$binary_file" ]; then
    local temp_install="${install_path}.tmp.$$"
    cp "$binary_file" "$temp_install" || return 1
    chmod +x "$temp_install" || return 1
    mv "$temp_install" "$install_path" || return 1
  else
    echo "Error: Binary not found in archive" >&2
    rm -rf "$temp_dir"
    return 1
  fi

  rm -rf "$temp_dir"
}

install_custom() {
  local name="$1"
  local version="$2"
  local install_fn="$3"

  echo "Installing ${name} ${version}..."

  "$install_fn"
}

multiselect() {
  local options=("$@")
  local total=${#options[@]}
  [ "$total" -eq 0 ] && return 1

  if command -v fzf >/dev/null 2>&1; then
    local sel_dir line
    sel_dir="$(mktemp -d)"
    if [ -n "${KITTY_WINDOW_ID:-}" ]; then
      printf '\033]1337;SetUserVar=ZSH_SELECTOR_MODE=Mg==\007' >&2
    fi
    printf '%s\n' "${options[@]}" | fzf \
      --multi \
      --header='Tab: toggle   Ctrl-A: select all   Ctrl-D: deselect   Enter: confirm   Esc: cancel' \
      --bind='ctrl-a:select-all,ctrl-d:deselect-all,ctrl-j:down,ctrl-k:up' \
      --listen \
      --bind="enter:execute-silent(curl -s \"http://127.0.0.1:\$FZF_PORT?limit=1000\" | jq -r '.selected[].text' >'$sel_dir/sel'; : >'$sel_dir/ok')+abort" \
      >/dev/null 2>&1 || true
    if [ -n "${KITTY_WINDOW_ID:-}" ]; then
      printf '\033]1337;SetUserVar=ZSH_SELECTOR_MODE\007' >&2
    fi
    if [ -f "$sel_dir/ok" ]; then
      while IFS= read -r line; do
        [ -n "$line" ] && printf '%s\n' "$line"
      done <"$sel_dir/sel"
      rm -rf "$sel_dir"
      return 0
    fi
    rm -rf "$sel_dir"
    return 1
  fi

  local cursor=0 top=0
  local viewport=20
  local -a state=()
  local i key seq all

  for ((i = 0; i < total; i++)); do state[i]=0; done
  if [ -n "${LINES:-}" ] && [ "$LINES" -gt 8 ]; then
    viewport=$((LINES - 6))
  fi

  printf '\e[?25l' >&2
  trap 'printf "\e[?25h\e[0m" >&2; exit 130' INT
  trap 'printf "\e[?25h\e[0m" >&2; exit 143' TERM
  while true; do
    printf '\e[H\e[2J' >&2
    echo "  ↑/↓ move   Space toggle   a toggle all   Enter install selection   q run default (all enabled)" >&2
    echo "" >&2
    [ "$top" -gt 0 ] && echo "  ↑ more" >&2 || echo "" >&2
    for ((i = top; i < top + viewport && i < total; i++)); do
      if [ "$i" -eq "$cursor" ]; then
        printf ' \e[7m' >&2
      else
        printf ' ' >&2
      fi
      if [ "${state[$i]}" -eq 1 ]; then
        printf '[x] %s\e[0m\n' "${options[$i]}" >&2
      else
        printf '[ ] %s\e[0m\n' "${options[$i]}" >&2
      fi
    done
    [ $((top + viewport)) -lt "$total" ] && echo "  ↓ more" >&2 || echo "" >&2

    IFS= read -rsn1 key
    case "$key" in
      $'\e')
        seq=""
        IFS= read -rsn2 -t 0.05 seq || true
        case "$seq" in
          '[A')
            [ "$cursor" -gt 0 ] && cursor=$((cursor - 1))
            [ "$cursor" -lt "$top" ] && top=$cursor
            ;;
          '[B')
            [ "$cursor" -lt $((total - 1)) ] && cursor=$((cursor + 1))
            [ "$cursor" -ge $((top + viewport)) ] && top=$((cursor - viewport + 1))
            ;;
          *)
            printf '\e[?25h\e[0m\n' >&2
            return 1
            ;;
        esac
        ;;
      ' ')
        state[$cursor]=$((1 - state[cursor]))
        ;;
      a | A)
        all=1
        for ((i = 0; i < total; i++)); do
          [ "${state[$i]}" -eq 0 ] && all=0
        done
        all=$((1 - all))
        for ((i = 0; i < total; i++)); do state[$i]=$all; done
        ;;
      j | J)
        [ "$cursor" -lt $((total - 1)) ] && cursor=$((cursor + 1))
        [ "$cursor" -ge $((top + viewport)) ] && top=$((cursor - viewport + 1))
        ;;
      k | K)
        [ "$cursor" -gt 0 ] && cursor=$((cursor - 1))
        [ "$cursor" -lt "$top" ] && top=$cursor
        ;;
      '')
        printf '\e[?25h\e[0m\n' >&2
        for ((i = 0; i < total; i++)); do
          [ "${state[$i]}" -eq 1 ] && printf '%s\n' "${options[$i]}"
        done
        return 0
        ;;
      q | Q)
        printf '\e[?25h\e[0m\n' >&2
        return 1
        ;;
    esac
  done
}
