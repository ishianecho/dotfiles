# Shell options and history, mirroring zsh/opt.zsh.

HISTFILE="$XDG_DATA_HOME/bash/history"
HISTSIZE=50000
HISTFILESIZE=50000
mkdir -p "$(dirname -- "$HISTFILE")"

shopt -s histappend
HISTCONTROL=ignoredups:ignorespace
HISTTIMEFORMAT='%F %T '

shopt -s autocd
shopt -s cdspell
shopt -s dirspell
shopt -s checkwinsize
shopt -s interactive_comments
