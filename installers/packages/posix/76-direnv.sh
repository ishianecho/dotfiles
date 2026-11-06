#!/usr/bin/env bash

pkg_name="direnv"

install_direnv() {
  if check_installed direnv; then
    return 0
  fi

  try_package_manager "$pkg_name"
}

install_direnv
