#!/usr/bin/env bash

set -euo pipefail

completion="$HOME/.local/bin/completion"
[ -x "$completion" ] || exit 0

zfunc_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zfunc"
bash_completions_dir="${XDG_CONFIG_HOME:-$HOME/.config}/bash/completions"
mkdir -p "$zfunc_dir" "$bash_completions_dir"

"$completion" zsh ghf > "$zfunc_dir/_ghf"
"$completion" zsh proxy > "$zfunc_dir/_proxy"
"$completion" zsh xrayctl > "$zfunc_dir/_xrayctl"
"$completion" bash ghf > "$bash_completions_dir/ghf.bash"
"$completion" bash proxy > "$bash_completions_dir/proxy.bash"
"$completion" bash xrayctl > "$bash_completions_dir/xrayctl.bash"

rm -f "$zfunc_dir/_set-proxy" "$bash_completions_dir/set-proxy.bash"
