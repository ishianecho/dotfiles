zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
[[ -n "$LS_COLORS" ]] && zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

. "$XDG_CONFIG_HOME/shell/completions"

compdef _gradle gradlew ./gradlew
compdef -d gradle gw
