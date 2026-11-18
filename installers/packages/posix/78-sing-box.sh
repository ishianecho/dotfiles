#!/usr/bin/env bash

pkg_name="sing-box"
pkg_version="${SING_BOX_VERSION:-1.14.4}"

install_sing_box() {
  if check_installed sing-box; then
    return 0
  fi

  if try_package_manager "$pkg_name"; then
    return 0
  fi

  case "$os" in
    darwin | linux)
      ;;
    *)
      echo "Unsupported operating system for sing-box: $os"
      return 0
      ;;
  esac

  local version="${pkg_version#v}"
  local archive_name="sing-box-${version}-${os}-${arch}"
  local url="https://github.com/SagerNet/sing-box/releases/download/v${version}/${archive_name}.tar.gz"

  download_binary \
    "$pkg_name" "$version" "$url" \
    "${archive_name}/sing-box" \
    "$HOME/.local/bin/sing-box"
}

install_sing_box
