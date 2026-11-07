# Prompt theme, mirroring zsh/theme.zsh.

__git_branch() {
  local b
  b=$(git symbolic-ref --short HEAD 2> /dev/null) || return 0
  printf ' (%s)' "$b"
}

PS1='\[\e[31m\]>>\[\e[0m\]\[\e[1;31m\]>\[\e[0m\] \[\e[1;36m\]${PWD##*/}\[\e[0m\]\[\e[1;34m\]$(__git_branch)\[\e[0m\] '
