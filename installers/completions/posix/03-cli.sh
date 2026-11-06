#!/usr/bin/env bash

completion_command() {
  case "$1" in
  gh) echo "completion -s" ;;
  uv) echo "generate-shell-completion" ;;
  cf) echo "complete" ;;
  *) echo "completion" ;;
  esac
}

generate_cli_completions() {
  local zfunc_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zfunc"
  local bash_dir="${XDG_CONFIG_HOME:-$HOME/.config}/bash/completions"

  if ! mkdir -p "$zfunc_dir" "$bash_dir"; then
    echo "Warning: Could not create completion directories" >&2
    return 0
  fi

  local tool args tmp
  for tool in buf cf chezmoi codex gh kubectl mise pnpm uv; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      continue
    fi

    args="$(completion_command "$tool")"

    tmp="$(mktemp "$zfunc_dir/.${tool}.XXXXXX")" || continue
    if "$tool" $args zsh >"$tmp" && [ -s "$tmp" ]; then
      chmod 0644 "$tmp"
      mv "$tmp" "$zfunc_dir/_$tool"
    else
      rm -f "$tmp"
    fi

    tmp="$(mktemp "$bash_dir/.${tool}.XXXXXX")" || continue
    if "$tool" $args bash >"$tmp" && [ -s "$tmp" ]; then
      chmod 0644 "$tmp"
      mv "$tmp" "$bash_dir/${tool}.bash"
    else
      rm -f "$tmp"
    fi
  done
}

generate_cli_completions
