# ZLE and fzf keybindings.

_zsh_keybinds() {
  bindkey -M viins 'jj' vi-cmd-mode
  bindkey '^Y' autosuggest-accept
  for keymap in viins vicmd emacs; do
    bindkey -M "$keymap" '^O' clear-screen
  done

  typeset -gA key
  key[Home]="${terminfo[khome]}"
  key[End]="${terminfo[kend]}"
  key[Insert]="${terminfo[kich1]}"
  key[Delete]="${terminfo[kdch1]}"
  key[PageUp]="${terminfo[kpp]}"
  key[PageDown]="${terminfo[knp]}"
  key[ShiftTab]="${terminfo[kcbt]}"
  [[ -n "$key[Home]" ]] && bindkey -- "$key[Home]" beginning-of-line
  [[ -n "$key[End]" ]] && bindkey -- "$key[End]" end-of-line
  [[ -n "$key[Insert]" ]] && bindkey -- "$key[Insert]" overwrite-mode
  [[ -n "$key[Delete]" ]] && bindkey -- "$key[Delete]" delete-char
  [[ -n "$key[PageUp]" ]] && bindkey -- "$key[PageUp]" up-line-or-history
  [[ -n "$key[PageDown]" ]] && bindkey -- "$key[PageDown]" down-line-or-history
  [[ -n "$key[ShiftTab]" ]] && bindkey -- "$key[ShiftTab]" reverse-menu-complete

  if [ -f /usr/share/fzf/key-bindings.zsh ]; then
    source /usr/share/fzf/key-bindings.zsh
    source /usr/share/fzf/completion.zsh
  fi

  zmodload -i zsh/complist
  bindkey -M menuselect '^J' down-line-or-history
  bindkey -M menuselect '^K' up-line-or-history

  if ((${+widgets[fzf-tab-complete]})); then
    bindkey -M emacs '^I' fzf-tab-complete
    bindkey -M viins '^I' fzf-tab-complete
  fi
}

zstyle ':fzf-tab:*' fzf-bindings 'tab:accept' 'ctrl-j:down' 'ctrl-k:up' 'ctrl-u:half-page-up' 'ctrl-d:half-page-down'
export FZF_CTRL_R_OPTS="${FZF_CTRL_R_OPTS:+$FZF_CTRL_R_OPTS }--bind=ctrl-j:down,ctrl-k:up,ctrl-u:half-page-up,ctrl-d:half-page-down"
export FZF_CTRL_T_OPTS="${FZF_CTRL_T_OPTS:+$FZF_CTRL_T_OPTS }--bind=ctrl-j:down,ctrl-k:up,ctrl-u:half-page-up,ctrl-d:half-page-down"

_zsh_keybinds
