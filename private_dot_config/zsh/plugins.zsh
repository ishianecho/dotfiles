ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"

VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
VI_MODE_SET_CURSOR=true
zinit snippet OMZP::vi-mode

zinit light zsh-users/zsh-completions
fpath=("$XDG_CONFIG_HOME/zfunc" "$XDG_DATA_HOME/zsh/site-functions" $fpath)
autoload -Uz compinit
mkdir -p "$XDG_CACHE_HOME/zsh"
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
zinit snippet OMZL::clipboard.zsh
zinit snippet OMZL::directories.zsh
zinit snippet OMZP::git
zinit snippet OMZP::gradle
zinit snippet OMZP::sudo
zinit snippet OMZP::extract
zinit snippet OMZP::z
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-autosuggestions
zinit light hlissner/zsh-autopair
zinit light zsh-users/zsh-syntax-highlighting
