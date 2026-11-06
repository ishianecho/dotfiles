#!/usr/bin/env bash

pkg_name="cf"

install_cf() {
  if check_installed cf || check_installed cloudflare; then
    return 0
  fi

  if ! check_installed pnpm; then
    echo "Skipping cf: pnpm not found (install pnpm first)"
    return 0
  fi

  echo "Installing cf (Cloudflare CLI) via pnpm..."
  pnpm add -g --allow-build=workerd cf || return 1
}

install_cf
