#!/bin/bash

ask_should_symlink() {
  local src="$1"
  local dest="$2"

  while true; do
    read -p "Do you want to symlink $src -> $dest ? [y/n] " yn
    case $yn in
      [Yy]*)
        ln -sfn "$src" "$dest"
        break
        ;;
      [Nn]*) return ;;
      *) echo "Please answer yes or no." ;;
    esac
  done
}

symlink_or_ask() {
  local src="$1"
  local dest="$2"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    ask_should_symlink "$src" "$dest"
  else
    ln -s "$src" "$dest"
  fi
}

DOTFILES="$HOME/.dotfiles"

# Nuke neovim config
rm -rf ~/.config/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.local/share/nvim

# Install
symlink_or_ask "$DOTFILES/nvim" "$HOME/.config/nvim"
symlink_or_ask "$DOTFILES/aerospace" "$HOME/.config/aerospace"
symlink_or_ask "$DOTFILES/ghostty" "$HOME/.config/ghostty"
symlink_or_ask "$DOTFILES/k9s" "$HOME/.config/k9s"
symlink_or_ask "$DOTFILES/.antigenrc" "$HOME/.antigenrc"
symlink_or_ask "$DOTFILES/.zshrc" "$HOME/.zshrc"
