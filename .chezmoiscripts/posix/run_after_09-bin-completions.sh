#!/usr/bin/env bash

set -euo pipefail

zfunc_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zfunc"
bash_completions_dir="${XDG_CONFIG_HOME:-$HOME/.config}/bash/completions"
mkdir -p "$zfunc_dir" "$bash_completions_dir"

tmp=""
for tool in ghf proxy xrayctl sbctl; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    continue
  fi

  tmp="$(mktemp "$zfunc_dir/.${tool}.XXXXXX")" || continue
  if "$tool" completion zsh >"$tmp" && [ -s "$tmp" ]; then
    chmod 0644 "$tmp"
    mv "$tmp" "$zfunc_dir/_$tool"
  else
    rm -f "$tmp"
  fi

  tmp="$(mktemp "$bash_completions_dir/.${tool}.XXXXXX")" || continue
  if "$tool" completion bash >"$tmp" && [ -s "$tmp" ]; then
    chmod 0644 "$tmp"
    mv "$tmp" "$bash_completions_dir/$tool.bash"
  else
    rm -f "$tmp"
  fi
done

rm -f "$zfunc_dir/_set-proxy" "$bash_completions_dir/set-proxy.bash"
