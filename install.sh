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

# Symlinks
symlink_or_ask ~/.dotfiles/bash_profile ~/.bash_profile
symlink_or_ask ~/.dotfiles/gitconfig ~/.gitconfig
symlink_or_ask ~/.dotfiles/gitignore_global ~/.gitignore_global
symlink_or_ask ~/.dotfiles/vimrc ~/.vimrc
symlink_or_ask ~/.dotfiles/gvimrc ~/.gvimrc

# VIM
vim +BundleInstall +BundleClean +BundleClean +quitall

