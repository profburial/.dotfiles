#!/bin/bash

ask_should_symlink() {
  while true; do
    read -p "Do you want to symlink $1 to $2 ? " yn
    case $yn in
      [Yy]* ) symlink_safe $1 $2; break;;
      [Nn]* ) return ;;
      * ) echo "Please answer yes or no.";
      esac
  done
}

symlink_or_ask() {
  if [ -f $2 ]; then
    ask_should_symlink $1 $2
  else
    ln -s $1 $2
  fi
}

# NvChad
git clone https://github.com/NvChad/starter ~/.config/nvim
mkdir -p ~/config/nvim/lua/custom

# Symlinks
symlink_or_ask ~/.dotfiles/nvim/custom ~/.config/nvim/lua/custom
symlink_or_ask ~/.dotfiles/.antigenrc ~/.antigenrc
symlink_or_ask ~/.dotfiles/.zshrc ~/.zshrc
