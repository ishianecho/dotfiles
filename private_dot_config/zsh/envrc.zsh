if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi

autoload -Uz add-zsh-hook

typeset -g _ENVRC_DIR=
typeset -ga _ENVRC_ALIASES

_envrc_dir() {
  local d=$PWD
  while [[ $d != / ]]; do
    [[ -f $d/.envrc ]] && { REPLY=$d; return 0 }
    d=${d:h}
  done
  return 1
}

_envrc() {
  if [[ -n $_ENVRC_DIR ]]; then
    if _envrc_dir && [[ $REPLY == $_ENVRC_DIR ]]; then
      REPLY=
      return
    fi
    REPLY=
    local a
    for a in "${_ENVRC_ALIASES[@]}"; do unalias "$a" 2>/dev/null; done
    _ENVRC_DIR= _ENVRC_ALIASES=()
  fi
  if _envrc_dir; then
    local -a _before
    _before=(${(k)aliases})
    ENVRC_ALIAS_SOURCE=1 builtin source "$REPLY/.envrc"
    _ENVRC_DIR=$REPLY
    _ENVRC_ALIASES=(${(k)aliases:|_before})
    REPLY=
  fi
}

add-zsh-hook chpwd _envrc
_envrc
