#!/usr/bin/env bash

pkg_name="wechat"

install_wechat() {
  if [ "$os" != "linux" ] || ! is_arch_family; then
    echo "Skipping wechat: only supported on Arch-based systems"
    return 0
  fi

  check_installed wechat && return 0

  try_package_manager wechat ||
    echo "Warning: Could not install wechat." >&2
}

install_wechat
