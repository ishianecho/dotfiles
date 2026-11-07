# Per-directory .envrc alias loading, mirroring zsh/envrc.zsh.

if command -v direnv > /dev/null 2>&1; then
  eval "$(direnv hook bash)"
fi

_ENVRC_DIR=
_ENVRC_ALIASES=()

_envrc_dir() {
  local d=$PWD
  while [ "$d" != / ]; do
    if [ -f "$d/.envrc" ]; then
      REPLY=$d
      return 0
    fi
    d=$(dirname -- "$d")
  done
  return 1
}

_envrc() {
  if [ -n "$_ENVRC_DIR" ]; then
    if _envrc_dir && [ "$REPLY" = "$_ENVRC_DIR" ]; then
      REPLY=
      return 0
    fi
    REPLY=
    local a
    for a in "${_ENVRC_ALIASES[@]}"; do unalias "$a" 2> /dev/null; done
    _ENVRC_DIR=
    _ENVRC_ALIASES=()
  fi
  if _envrc_dir; then
    local before after alias_line
    before=$(alias -p 2>/dev/null | sort)
    ENVRC_ALIAS_SOURCE=1 . "$REPLY/.envrc"
    after=$(alias -p 2>/dev/null | sort)
    _ENVRC_DIR=$REPLY
    _ENVRC_ALIASES=()
    while IFS= read -r alias_line; do
      [ -n "$alias_line" ] && _ENVRC_ALIASES+=("${alias_line#alias }")
    done < <(comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after") | sed 's/=.*//')
    REPLY=
  fi
}

case ";${PROMPT_COMMAND[*]:-};" in
*";_envrc;"*) ;;
*)
  if [[ "$(declare -p PROMPT_COMMAND 2>&1)" == "declare -a"* ]]; then
    PROMPT_COMMAND=(_envrc "${PROMPT_COMMAND[@]}")
  else
    PROMPT_COMMAND="_envrc${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
  fi
  ;;
esac

_envrc
