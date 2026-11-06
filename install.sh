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

for source in nvim ghostty herdr/config.toml k9s/config.yaml k9s/aliases.yaml k9s/skins .zshrc starship.toml; do
  [ -e "$DOTFILES/$source" ] || {
    echo "Missing source: $DOTFILES/$source" >&2
    exit 1
  }
done
if [ "$PLATFORM" = Darwin ] && [ ! -d "$DOTFILES/aerospace" ]; then
  echo "Missing source: $DOTFILES/aerospace" >&2
  exit 1
fi

DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
case "$DATA_HOME" in
/*) ;;
*) echo 'XDG_DATA_HOME must be an absolute path.' >&2; exit 1 ;;
esac
export PATH="$HOME/.local/bin:$PATH"
BREW_PREFIX=""
if [ "$PLATFORM" = Darwin ]; then
  if ! command -v brew >/dev/null 2>&1; then
    for brew_executable in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      if [ -x "$brew_executable" ]; then
        export PATH="$(dirname -- "$brew_executable"):$PATH"
        break
      fi
    done
  fi
  if command -v brew >/dev/null 2>&1; then
    BREW_PREFIX=$(brew --prefix)
  fi
fi

shell_dependency_present() {
  local dependency=$1 directory
  case "$dependency" in
  zsh | starship) command -v "$dependency" >/dev/null 2>&1 ;;
  zsh-completions)
    for directory in "$DATA_HOME/zsh-completions/src" "${BREW_PREFIX:-/usr/local}/share/zsh-completions" /usr/local/share/zsh-completions /usr/share/zsh-completions; do
      if compgen -G "$directory/_*" >/dev/null; then return 0; fi
    done
    if command -v dpkg-query >/dev/null 2>&1 && [ "$(dpkg-query -W -f='${Status}' zsh-completions 2>/dev/null)" = 'install ok installed' ]; then return 0; fi
    if command -v rpm >/dev/null 2>&1 && rpm -q --quiet zsh-completions; then return 0; fi
    if command -v pacman >/dev/null 2>&1 && pacman -Qq zsh-completions >/dev/null 2>&1; then return 0; fi
    return 1
    ;;
  zsh-syntax-highlighting)
    for directory in "$DATA_HOME/zsh-syntax-highlighting" "${BREW_PREFIX:-/usr/local}/share/zsh-syntax-highlighting" /usr/local/share/zsh-syntax-highlighting /usr/share/zsh-syntax-highlighting; do
      if [ -r "$directory/zsh-syntax-highlighting.zsh" ]; then return 0; fi
    done
    return 1
    ;;
  esac
}

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "Missing sudo; install the required system packages as root and rerun." >&2
    exit 1
  fi
}

INSTALL_TEMP=""
trap 'if [ -n "$INSTALL_TEMP" ]; then rm -rf -- "$INSTALL_TEMP"; fi' EXIT
download_installer() {
  local url=$1
  if [ -z "$INSTALL_TEMP" ]; then INSTALL_TEMP=$(mktemp -d); fi
  curl --fail --show-error --silent --location "$url" --output "$INSTALL_TEMP/install.sh"
}

missing_dependencies=()
for dependency in zsh starship zsh-completions zsh-syntax-highlighting; do
  if ! shell_dependency_present "$dependency"; then missing_dependencies+=("$dependency"); fi
done

if [ "${#missing_dependencies[@]}" -gt 0 ]; then
  printf 'Installing missing shell dependencies: %s\n' "${missing_dependencies[*]}"
  if [ "$PLATFORM" = Darwin ]; then
    if ! command -v brew >/dev/null 2>&1; then
      download_installer https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
      /bin/bash "$INSTALL_TEMP/install.sh"
      for brew_executable in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$brew_executable" ]; then
          export PATH="$(dirname -- "$brew_executable"):$PATH"
          break
        fi
      done
    fi
    BREW_PREFIX=$(brew --prefix)
    HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_UPGRADE=1 brew install "${missing_dependencies[@]}"
  else
    missing_packages=()
    for executable in zsh curl git tar gzip; do
      if ! command -v "$executable" >/dev/null 2>&1; then missing_packages+=("$executable"); fi
    done
    if [ "${#missing_packages[@]}" -gt 0 ]; then
      if command -v apt-get >/dev/null 2>&1; then
        run_as_root apt-get update
        run_as_root apt-get install -y "${missing_packages[@]}" ca-certificates
      elif command -v dnf >/dev/null 2>&1; then
        run_as_root dnf install -y "${missing_packages[@]}" ca-certificates
      elif command -v pacman >/dev/null 2>&1; then
        run_as_root pacman -S --needed --noconfirm "${missing_packages[@]}" ca-certificates
      else
        echo "No supported package manager found. Install ${missing_packages[*]} with your distribution's package manager and rerun." >&2
        exit 1
      fi
    fi
    if ! shell_dependency_present starship; then
      mkdir -p "$HOME/.local/bin"
      download_installer https://starship.rs/install.sh
      sh "$INSTALL_TEMP/install.sh" --yes --bin-dir "$HOME/.local/bin"
    fi
    for dependency in zsh-completions zsh-syntax-highlighting; do
      if ! shell_dependency_present "$dependency"; then
        if [ -e "$DATA_HOME/$dependency" ] || [ -L "$DATA_HOME/$dependency" ]; then
          echo "Incomplete installation at $DATA_HOME/$dependency; move it aside and rerun." >&2
          exit 1
        fi
        if [ -z "$INSTALL_TEMP" ]; then INSTALL_TEMP=$(mktemp -d); fi
        case "$dependency" in
        zsh-completions) release=0.36.0 ;;
        zsh-syntax-highlighting) release=0.8.0 ;;
        esac
        git clone --depth 1 --branch "$release" "https://github.com/zsh-users/$dependency.git" "$INSTALL_TEMP/$dependency"
        mkdir -p "$DATA_HOME"
        mv "$INSTALL_TEMP/$dependency" "$DATA_HOME/$dependency"
      fi
    done
  fi
fi

for dependency in zsh starship zsh-completions zsh-syntax-highlighting; do
  if ! shell_dependency_present "$dependency"; then
    echo "Dependency installation did not provide $dependency; configuration links were not changed." >&2
    exit 1
  fi
done

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
for obsolete in antigen.zsh .antigenrc; do
  if [ -L "$HOME/$obsolete" ] && [ "$(readlink "$HOME/$obsolete")" = "$DOTFILES/$obsolete" ]; then
    backup_config "$HOME/$obsolete"
  fi
done
link_config "$DOTFILES/starship.toml" "$CONFIG_HOME/starship.toml"
link_config "$DOTFILES/.zshrc" "$HOME/.zshrc"
printf '\nInstalled. Start zsh to load the shell configuration.\n'
