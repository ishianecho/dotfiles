# Readline and fzf keybindings, mirroring zsh/keybinds.zsh.

set -o vi

_vi_cursor_block() { printf '\e[2 q' >&2; }
_vi_cursor_beam() { printf '\e[6 q' >&2; }
_vi_cursor_prompt() { _vi_cursor_beam; }

bind -m vi-insert -x '"\C-x\C-b": _vi_cursor_block'
bind -m vi-insert '"\C-x\C-v": vi-movement-mode'
bind -m vi-insert '"\e": "\C-x\C-b\C-x\C-v"'
bind -m vi-insert '"jj": "\C-x\C-b\C-x\C-v"'
bind -m vi-command -x '"\C-x\C-n": _vi_cursor_beam'
for key in i a I A s S c C R; do
  fn=$(bind -m vi-command -p | awk -v k="\"$key\":" '$1==k{print $2}')
  [ -n "$fn" ] || continue
  bind -m vi-command "\"\C-x$key\": $fn"
  bind -m vi-command "\"$key\": \"\C-x\C-n\C-x$key\""
done
unset key fn

case ";${PROMPT_COMMAND[*]:-};" in
*";_vi_cursor_prompt;"*) ;;
*)
  if [[ "$(declare -p PROMPT_COMMAND 2>&1)" == "declare -a"* ]]; then
    PROMPT_COMMAND=(_vi_cursor_prompt "${PROMPT_COMMAND[@]}")
  else
    PROMPT_COMMAND="_vi_cursor_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
  fi
  ;;
esac

for keymap in emacs-standard vi-insert vi-command; do
  bind -m "$keymap" '"\C-o": clear-screen'
done
unset keymap

_bind_key() {
  local seq
  seq=$(tput "$1" 2>/dev/null) || return 0
  [ -n "$seq" ] && bind -m emacs-standard -m vi-insert -m vi-command "\"$seq\": $2"
}
_bind_key khome beginning-of-line
_bind_key kend end-of-line
_bind_key kich1 overwrite-mode
_bind_key kdch1 delete-char
_bind_key kpp up-line-or-history
_bind_key knp down-line-or-history
_bind_key kcbt reverse-menu-complete
unset -f _bind_key

if [ -f /usr/share/fzf/key-bindings.bash ]; then
  source /usr/share/fzf/key-bindings.bash
  source /usr/share/fzf/completion.bash
fi

export FZF_CTRL_R_OPTS="${FZF_CTRL_R_OPTS:+$FZF_CTRL_R_OPTS }--bind=ctrl-j:down,ctrl-k:up,ctrl-u:half-page-up,ctrl-d:half-page-down"
export FZF_CTRL_T_OPTS="${FZF_CTRL_T_OPTS:+$FZF_CTRL_T_OPTS }--bind=ctrl-j:down,ctrl-k:up,ctrl-u:half-page-up,ctrl-d:half-page-down"
