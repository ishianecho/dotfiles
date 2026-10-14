#!/usr/bin/env bash

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

apt_update_done=false
install_via_apt() {
  if [ "$pkg_manager" != "apt" ] || [ "$has_sudo" != "true" ]; then
    return 1
  fi

  echo "Installing via apt: $*"
  if [ "$apt_update_done" != "true" ]; then
    sudo apt-get update || return 1
    apt_update_done=true
  fi
  sudo apt-get install -y "$@"
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
  if [ "$pkg_manager" != "pacman" ] || [ "$has_sudo" != "true" ]; then
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

  echo "Installing via pacman: ${packages[*]}"
  sudo pacman -S "${sync_flags[@]}" --needed --noconfirm "${packages[@]}"
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
  brew install "${packages[@]}"
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
  sudo dnf install -y "${packages[@]}"
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
  if [ "$pkg_manager" = "pacman" ] && [ "$has_sudo" = "true" ]; then
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
