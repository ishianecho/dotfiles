zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
[[ -n "$LS_COLORS" ]] && zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

. "$XDG_CONFIG_HOME/shell/completions"

compdef _gradle gradlew ./gradlew
compdef -d gradle gw

_uv_run_scripts() {
  local -a scripts
  scripts=(${(f)"$(yq '.project.scripts | keys | .[]' pyproject.toml 2> /dev/null)"})
  if (($#scripts)); then
    _describe -t project-scripts 'project script' scripts
  fi
  _files -g '*.py(-.)'
}

if [[ -f $XDG_CONFIG_HOME/zfunc/_uv ]]; then
  autoload -Uz +X _uv
  functions[_uv_upstream]=$functions[_uv]
  unfunction _uv
  _uv() {
    if (( $+commands[yq] )) && [[ $words[2] == run && $PREFIX != -* ]] && ((CURRENT == 3)); then
      _uv_run_scripts
      return
    fi
    _uv_upstream "$@"
  }
fi
