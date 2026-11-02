#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 0 ]; then
  echo "Usage: $0" >&2
  exit 2
fi

DOTFILES=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
case "$CONFIG_HOME" in
/*) ;;
*)
  echo 'XDG_CONFIG_HOME must be an absolute path.' >&2
  exit 1
  ;;
esac
PLATFORM=$(uname -s)
case "$PLATFORM" in
Linux | Darwin) ;;
*)
  echo "Unsupported platform: $PLATFORM" >&2
  exit 1
  ;;
esac

for source in nvim ghostty herdr/config.toml k9s/config.yaml k9s/aliases.yaml k9s/skins .antigenrc .zshrc antigen.zsh; do
  [ -e "$DOTFILES/$source" ] || {
    echo "Missing source: $DOTFILES/$source" >&2
    exit 1
  }
done
if [ "$PLATFORM" = Darwin ] && [ ! -d "$DOTFILES/aerospace" ]; then
  echo "Missing source: $DOTFILES/aerospace" >&2
  exit 1
fi

backup_config() {
  local destination=$1 backup suffix=0
  backup="${destination}.backup.$(date +%Y%m%d-%H%M%S)"
  while [ -e "$backup" ] || [ -L "$backup" ]; do
    suffix=$((suffix + 1))
    backup="${destination}.backup.$(date +%Y%m%d-%H%M%S).$suffix"
  done
  mv "$destination" "$backup"
  printf 'Backed up: %s -> %s\n' "$destination" "$backup"
}

link_config() {
  local source=$1 destination=$2
  if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source" ]; then
    printf 'Already linked: %s\n' "$destination"
    return
  fi
  mkdir -p "$(dirname -- "$destination")"
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    backup_config "$destination"
  fi
  ln -s "$source" "$destination"
  printf 'Linked: %s -> %s\n' "$destination" "$source"
}

link_config "$DOTFILES/nvim" "$CONFIG_HOME/nvim"
link_config "$DOTFILES/ghostty" "$CONFIG_HOME/ghostty"
link_config "$DOTFILES/herdr/config.toml" "$CONFIG_HOME/herdr/config.toml"
if [ "$PLATFORM" = Darwin ]; then
  link_config "$DOTFILES/aerospace" "$CONFIG_HOME/aerospace"
fi
# Older installs linked all of k9s, including machine-specific runtime state.
if [ -L "$CONFIG_HOME/k9s" ] || { [ -e "$CONFIG_HOME/k9s" ] && [ ! -d "$CONFIG_HOME/k9s" ]; }; then
  backup_config "$CONFIG_HOME/k9s"
fi
mkdir -p "$CONFIG_HOME/k9s"
for source in config.yaml aliases.yaml skins; do
  link_config "$DOTFILES/k9s/$source" "$CONFIG_HOME/k9s/$source"
done
link_config "$DOTFILES/antigen.zsh" "$HOME/antigen.zsh"
link_config "$DOTFILES/.antigenrc" "$HOME/.antigenrc"
link_config "$DOTFILES/.zshrc" "$HOME/.zshrc"
printf '\nInstalled. Start zsh to load the shell configuration.\n'
