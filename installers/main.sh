#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cleanup_temp_files() {
  rm -f /tmp/*.tmp.$$
  rm -rf /tmp/*-*.$$
  rm -f "$HOME/.local/bin/"*.tmp.$$
}

trap cleanup_temp_files EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

source "$SCRIPT_DIR/lib/posix/env.sh"
source "$SCRIPT_DIR/lib/posix/helpers.sh"

category_enabled() {
  case "$1" in
    shell)
      [ "$install_shell" = "true" ]
      ;;
    build)
      [ "$install_build" = "true" ]
      ;;
    runtimes)
      [ "$install_runtimes" = "true" ]
      ;;
    editor)
      [ "$install_editor" = "true" ]
      ;;
    ai)
      [ "$install_ai" = "true" ]
      ;;
    utilities)
      [ "$install_utilities" = "true" ]
      ;;
    operations)
      [ "$install_operations" = "true" ]
      ;;
    terminal)
      [ "$install_terminal" = "true" ]
      ;;
    input)
      [ "$install_input" = "true" ]
      ;;
    gaming)
      [ "$install_gaming" = "true" ]
      ;;
    desktop)
      [ "$install_desktop" = "true" ]
      ;;
    *)
      return 2
      ;;
  esac
}

echo "==> Starting package installation"

install_shell="${DOTS_INSTALL_SHELL:-true}"
install_build="${DOTS_INSTALL_BUILD:-true}"
install_runtimes="${DOTS_INSTALL_RUNTIMES:-true}"
install_editor="${DOTS_INSTALL_EDITOR:-true}"
install_ai="${DOTS_INSTALL_AI:-true}"
install_utilities="${DOTS_INSTALL_UTILITIES:-true}"
install_operations="${DOTS_INSTALL_OPERATIONS:-true}"
install_terminal="${DOTS_INSTALL_TERMINAL:-true}"
install_input="${DOTS_INSTALL_INPUT:-false}"
install_gaming="${DOTS_INSTALL_GAMING:-true}"
install_desktop="${DOTS_INSTALL_DESKTOP:-false}"

shopt -s nullglob
packages=("$SCRIPT_DIR/packages/posix/"*.sh)
shopt -u nullglob

if [ ${#packages[@]} -eq 0 ]; then
  echo "No packages found in $SCRIPT_DIR/packages/posix/"
else
  sorted_packages=()
  while IFS= read -r -d '' file; do
    sorted_packages+=("$file")
  done < <(printf '%s\0' "${packages[@]}" | sort -z)

  echo "==> Found ${#sorted_packages[@]} packages"

  for pkg_file in "${sorted_packages[@]}"; do
    pkg_basename=$(basename "$pkg_file" .sh)
    if [ "$pkg_basename" = "00-init" ]; then
      continue
    fi
    pkg_category=""
    case "$pkg_basename" in
      0[0-9]-*)
        pkg_category=shell
        ;;
      1[0-9]-* | 2[0-9]-*)
        pkg_category=build
        ;;
      3[0-9]-*)
        pkg_category=runtimes
        ;;
      4[0-9]-*)
        pkg_category=editor
        ;;
      5[0-9]-*)
        pkg_category=ai
        ;;
      6[0-9]-*)
        pkg_category=utilities
        ;;
      7[0-9]-*)
        pkg_category=operations
        ;;
      8[0-9]-*)
        pkg_category=terminal
        ;;
      9[0-9]-*)
        pkg_category=input
        ;;
      g[0-9]-*)
        pkg_category=gaming
        ;;
      d[0-9]-*)
        pkg_category=desktop
        ;;
    esac

    case "$pkg_category" in
      shell | build | runtimes | editor | ai | utilities | operations | terminal | input | gaming | desktop)
        if ! category_enabled "$pkg_category"; then
          echo "==> Skipping $pkg_basename"
          continue
        fi
        ;;
    esac

    echo "==> Processing: $pkg_basename"

    source "$pkg_file"
  done
fi

install_completions="${DOTS_INSTALL_COMPLETIONS:-true}"

if [ "$install_completions" != "true" ]; then
  echo ""
  echo "==> Skipping shell completions"
else
  echo ""
  echo "==> Generating shell completions"

  shopt -s nullglob
  completion_scripts=("$SCRIPT_DIR/completions/posix/"*.sh)
  shopt -u nullglob

  if [ ${#completion_scripts[@]} -eq 0 ]; then
    echo "No completion generators found in $SCRIPT_DIR/completions/"
  else
    sorted_completion_scripts=()
    while IFS= read -r -d '' file; do
      sorted_completion_scripts+=("$file")
    done < <(printf '%s\0' "${completion_scripts[@]}" | sort -z)

    echo "==> Found ${#sorted_completion_scripts[@]} completion generators"

    for completion_script in "${sorted_completion_scripts[@]}"; do
      completion_basename=$(basename "$completion_script" .sh)
      echo "==> Processing completion: $completion_basename"

      if ! (
        set +e
        source "$completion_script"
      ); then
        echo "Warning: Completion generator failed: $completion_basename" >&2
      fi
    done

    rm -f "${ZDOTDIR:-$HOME}"/.zcompdump*
  fi
fi

echo ""
echo "==> Installation complete!"
