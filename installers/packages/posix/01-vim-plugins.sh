#!/usr/bin/env bash

pkg_name="vim-plugins"

plug_file="${XDG_CONFIG_HOME:-$HOME/.config}/vim/autoload/plug.vim"
plug_url="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

install_vim_plugins() {
  if ! check_installed vim; then
    return 0
  fi

  mkdir -p "$(dirname "$plug_file")"

  if [ ! -f "$plug_file" ]; then
    curl_download -o "$plug_file" "$plug_url" ||
      {
        echo "Warning: Could not download vim-plug." >&2
        return 0
      }
  fi

  vim -n -es -u "${XDG_CONFIG_HOME:-$HOME/.config}/vim/vimrc" -i NONE +PlugInstall! +qall! 2>/dev/null ||
    echo "Warning: run :PlugInstall inside vim to finish." >&2
}

install_vim_plugins
