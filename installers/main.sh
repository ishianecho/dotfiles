#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cleanup_temp_files() {
  rm -f /tmp/*.tmp.$$
  rm -rf /tmp/*-*.$$
  rm -f "$HOME/.local/bin/"*.tmp.$$
  if [ -n "${jobs_tmp:-}" ]; then
    rm -rf "$jobs_tmp"
  fi
}

trap cleanup_temp_files EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

source "$SCRIPT_DIR/lib/posix/env.sh"
source "$SCRIPT_DIR/lib/posix/helpers.sh"

pkg_category_of() {
  case "$1" in
    0[0-9]-*)
      echo "shell"
      ;;
    1[0-9]-* | 2[0-9]-*)
      echo "build"
      ;;
    3[0-9]-*)
      echo "runtimes"
      ;;
    4[0-9]-*)
      echo "editor"
      ;;
    5[0-9]-*)
      echo "ai"
      ;;
    6[0-9]-*)
      echo "utilities"
      ;;
    7[0-9]-*)
      echo "operations"
      ;;
    8[0-9]-*)
      echo "terminal"
      ;;
    9[0-9]-*)
      echo "input"
      ;;
    g[0-9]-*)
      echo "gaming"
      ;;
    c[0-9]-*)
      echo "communication"
      ;;
    d[0-9]-*)
      echo "desktop"
      ;;
  esac
}

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
    communication)
      [ "$install_communication" = "true" ]
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
install_editor="${DOTS_INSTALL_EDITOR:-false}"
install_ai="${DOTS_INSTALL_AI:-false}"
install_utilities="${DOTS_INSTALL_UTILITIES:-false}"
install_operations="${DOTS_INSTALL_OPERATIONS:-false}"
install_terminal="${DOTS_INSTALL_TERMINAL:-false}"
install_input="${DOTS_INSTALL_INPUT:-false}"
install_gaming="${DOTS_INSTALL_GAMING:-false}"
install_communication="${DOTS_INSTALL_COMMUNICATION:-false}"
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

  failed=0
  jobs_tmp="$(mktemp -d)"
  job_names=()
  job_pids=()
  job_logs=()
  job_marks=()
  if [ -t 1 ]; then
    tty_mode=true
  else
    tty_mode=false
  fi

  pick_mode="all"
  selected_packages=" "
  if [ "${DOTS_NO_PICKER:-}" != "1" ] && [ -t 0 ] && [ -t 1 ]; then
    picker_options=()
    for pkg_file in "${sorted_packages[@]}"; do
      pkg_basename=$(basename "$pkg_file" .sh)
      [ "$pkg_basename" = "00-init" ] && continue
      pkg_category="$(pkg_category_of "$pkg_basename")"
      picker_options+=("$pkg_basename (${pkg_category})")
    done
    if [ ${#picker_options[@]} -gt 0 ]; then
      echo "==> Select packages to install"
      if picker_result="$(multiselect "${picker_options[@]}")"; then
        pick_mode="selection"
        selected_packages=" $(printf '%s\n' "$picker_result" | sed 's/ (.*$//' | tr '\n' ' ') "
        picked_count=$(printf '%s\n' "$picker_result" | grep -c . || true)
        echo "==> Selected ${picked_count} package(s)"
      else
        echo "==> Picker dismissed, installing all enabled categories"
      fi
    fi
  fi

  for pkg_file in "${sorted_packages[@]}"; do
    pkg_basename=$(basename "$pkg_file" .sh)
    if [ "$pkg_basename" = "00-init" ]; then
      continue
    fi
    if [ "$pick_mode" = "selection" ]; then
      case "$selected_packages" in
        *" $pkg_basename "*) ;;
        *) continue ;;
      esac
    else
      pkg_category="$(pkg_category_of "$pkg_basename")"

      case "$pkg_category" in
        shell | build | runtimes | editor | ai | utilities | operations | terminal | input | gaming | communication | desktop)
          if ! category_enabled "$pkg_category"; then
            [ "$tty_mode" = false ] && echo "==> Skipping $pkg_basename"
            continue
          fi
          ;;
      esac
    fi

    [ "$tty_mode" = false ] && echo "==> Processing: $pkg_basename"
    job_idx=${#job_names[@]}
    job_names+=("$pkg_basename")
    job_logs+=("$jobs_tmp/$job_idx.log")
    job_marks+=("$jobs_tmp/$job_idx.mark")
    (
      rc=0
      (
        source "$pkg_file"
      ) || rc=$?
      : >"$jobs_tmp/$job_idx.mark"
      exit "$rc"
    ) >"$jobs_tmp/$job_idx.log" 2>&1 </dev/null &
    job_pids+=($!)
  done

  total_jobs=${#job_pids[@]}
  if [ "$total_jobs" -gt 0 ]; then
    if [ "$tty_mode" = true ]; then
      printf '\e[?25l'
      trap 'printf "\e[?25h" >&2; exit 130' INT
      trap 'printf "\e[?25h" >&2; exit 143' TERM
      echo "==> Installing $total_jobs package(s)"
      job_shown=()
      finished=0
      while [ "$finished" -lt "$total_jobs" ]; do
        new_line=true
        for i in "${!job_pids[@]}"; do
          [ -n "${job_shown[$i]:-}" ] && continue
          [ -f "${job_marks[$i]}" ] || continue
          if [ "$new_line" = true ]; then
            printf '\r\e[K'
            new_line=false
          fi
          job_shown[$i]=1
          finished=$((finished + 1))
          if wait "${job_pids[$i]}"; then
            printf '  ✔ %s\n' "${job_names[$i]}"
          else
            failed=1
            printf '  ✗ %s\n' "${job_names[$i]}"
            tail -n 20 "${job_logs[$i]}" | sed 's/^/    /'
          fi
        done
        printf '\r\e[K  … %d/%d' "$finished" "$total_jobs"
        sleep 0.15
      done
      printf '\r\e[K'
      printf '\e[?25h'
    else
      for i in "${!job_pids[@]}"; do
        if wait "${job_pids[$i]}"; then
          echo "[ok] ${job_names[$i]}"
        else
          failed=1
          echo "[fail] ${job_names[$i]}"
          tail -n 20 "${job_logs[$i]}" | sed 's/^/    /'
        fi
      done
    fi
  fi
  rm -rf "$jobs_tmp"
  jobs_tmp=""
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
[ "$failed" -eq 0 ] || exit 1
