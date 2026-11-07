# Kitty integration for bash selectors, mirroring zsh/kitty.zsh.

_kitty_selector_mode() {
  local mode=$1 value
  [ -n "${KITTY_WINDOW_ID:-}" ] || return 0
  case $mode in
  completion) value=MQ== ;;
  fzf) value=Mg== ;;
  *)
    [ "${_KITTY_SELECTOR_MODE:-}" = none ] && return 0
    _KITTY_SELECTOR_MODE=none
    printf '\033]1337;SetUserVar=ZSH_SELECTOR_MODE\007'
    return 0
    ;;
  esac
  [ "${_KITTY_SELECTOR_MODE:-}" = "$mode" ] && return 0
  _KITTY_SELECTOR_MODE=$mode
  printf '\033]1337;SetUserVar=ZSH_SELECTOR_MODE=%s\007' "$value"
}

_kitty_selector_run() {
  local ret=0
  _kitty_selector_mode fzf
  "$@" || ret=$?
  _kitty_selector_mode
  return $ret
}

_kitty_wrap_selector_widget() {
  local widget=$1 original=_kitty_original_$1
  declare -F "$widget" > /dev/null 2>&1 || return 0
  declare -F "$original" > /dev/null 2>&1 && return 0
  eval "${original} () $(declare -f "$widget" | tail -n +2)"
  eval "$widget() { _kitty_selector_run $original \"\$@\"; }"
}

_kitty_wrap_selector_widget fzf-file-widget
_kitty_wrap_selector_widget __fzf_history__
_kitty_wrap_selector_widget __fzf_cd__

ghf() {
  local ret=0
  _kitty_selector_mode fzf
  command ghf "$@" || ret=$?
  _kitty_selector_mode
  return $ret
}

unset -f _kitty_wrap_selector_widget
