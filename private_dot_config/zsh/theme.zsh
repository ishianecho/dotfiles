autoload -Uz vcs_info
precmd_functions+=(vcs_info)
zstyle ':vcs_info:git:*' formats '(%b) '
PROMPT='%F{red}>>%f%B%F{red}>%f%b %B%F{cyan}%c%f%b %B%F{blue}${vcs_info_msg_0_}%f%b'
