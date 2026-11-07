# Completion setup, mirroring zsh/completion.zsh.

. "$XDG_CONFIG_HOME/shell/completions"

if command -v yq > /dev/null 2>&1; then
  _uv_run_scripts() {
    if [ "${COMP_WORDS[1]:-}" = run ] && [ "$COMP_CWORD" -eq 2 ] && [ "${COMP_WORDS[COMP_CWORD]:0:1}" != - ]; then
      local script
      while IFS= read -r script; do
        [ -n "$script" ] && COMPREPLY+=("$script")
      done < <(yq '.project.scripts | keys | .[]' pyproject.toml 2> /dev/null)
    fi
    local f
    for f in *.py; do
      [ -e "$f" ] && COMPREPLY+=("$f")
    done
  }
  complete -F _uv_run_scripts uv
fi
