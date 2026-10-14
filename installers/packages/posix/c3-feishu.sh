#!/usr/bin/env bash

pkg_name="feishu"

install_feishu() {
  if [ "$os" != "linux" ] || ! is_arch_family; then
    echo "Skipping feishu: only supported on Arch-based systems"
    return 0
  fi

  check_installed feishu && return 0

  try_package_manager feishu ||
    echo "Warning: Could not install feishu." >&2
}

install_feishu
