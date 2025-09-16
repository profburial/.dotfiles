#!/bin/bash

ask_should_symlink() {
  while true; do
    read -p "Do you want to symlink $1 to $2 ? " yn
    case $yn in
    [Yy]*)
      symlink_safe $1 $2
      break
      ;;
    [Nn]*) return ;;
    *) echo "Please answer yes or no." ;;
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

# Symlinks
symlink_or_ask ~/.dotfiles/nvim ~/.config/nvim
symlink_or_ask ~/.dotfiles/aerospace ~/.config/aerospace
symlink_or_ask ~/.dotfiles/ghostty ~/.config/ghostty
symlink_or_ask ~/.dotfiles/k9s ~/.config/k9s
symlink_or_ask ~/.dotfiles/.antigenrc ~/.antigenrc
symlink_or_ask ~/.dotfiles/.zshrc ~/.zshrc
