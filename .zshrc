typeset -U path fpath
path=("$HOME/bin" "$HOME/.local/bin" "$HOME/.bun/bin" "$HOME/.opencode/bin" $path)

# Homebrew is macOS-only here; shellenv sets PATH, MANPATH, INFOPATH and HOMEBREW_PREFIX before the runtime managers load.
if [[ "$OSTYPE" == darwin* ]]; then
  for brew_executable in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_executable" ]]; then
      eval "$("$brew_executable" shellenv)"
      break
    fi
  done
  unset brew_executable
fi
[[ -d /usr/local/go/bin ]] && path+=(/usr/local/go/bin)
export PATH

export K9S_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/k9s"
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt append_history share_history hist_ignore_dups hist_ignore_space
setopt auto_cd interactive_comments
unsetopt correct correct_all
bindkey -e

export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
[[ -r "$HOME/.asdf/asdf.sh" ]] && source "$HOME/.asdf/asdf.sh"
[[ -d "$ASDF_DATA_DIR/shims" ]] && path=("$ASDF_DATA_DIR/shims" $path)
[[ -d "${ASDF_DIR:-$HOME/.asdf}/completions" ]] && fpath=("${ASDF_DIR:-$HOME/.asdf}/completions" $fpath)

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
for nvm_script in "$NVM_DIR/nvm.sh" "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/nvm/nvm.sh" /usr/local/opt/nvm/nvm.sh; do
  if [[ -r "$nvm_script" ]]; then
    source "$nvm_script"
    break
  fi
done
unset nvm_script

export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
[[ -d "$PYENV_ROOT/bin" ]] && path=("$PYENV_ROOT/bin" $path)
if (( $+commands[pyenv] )); then
  eval "$(pyenv init - zsh)"
fi

for completion_directory in "${XDG_DATA_HOME:-$HOME/.local/share}/zsh-completions/src" "${HOMEBREW_PREFIX:-/usr/local}/share/zsh-completions" /usr/local/share/zsh-completions /usr/share/zsh-completions; do
  [[ -d "$completion_directory" ]] && fpath=("$completion_directory" $fpath)
done
unset completion_directory
autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list ''
zstyle ':completion:*' menu select

export STARSHIP_CONFIG="${STARSHIP_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml}"
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
else
  PROMPT='%n@%m %~ %# '
fi

if (( $+commands[nvim] )); then
  export EDITOR=nvim
  alias vi=nvim vim=nvim
elif (( $+commands[vim] )); then
  export EDITOR=vim
else
  export EDITOR=vi
fi
export VISUAL="$EDITOR"
[[ -t 0 ]] && export GPG_TTY="$(tty)"

aws_profile() {
  if (( $# != 1 )); then
    print -u2 'Usage: aws_profile PROFILE'
    return 2
  fi
  export AWS_PROFILE="$1"
}

port_forward() {
  case "$OSTYPE" in
    darwin*) sudo sysctl -w net.inet.ip.forwarding=1 ;;
    linux*) sudo sysctl -w net.ipv4.ip_forward=1 ;;
    *) print -u2 "Unsupported platform: $OSTYPE"; return 1 ;;
  esac
}

ssh_copy() {
  local public_key="${1:-$HOME/.ssh/id_ed25519.pub}"
  if (( $# == 0 )) && [[ ! -r "$public_key" ]]; then
    public_key="$HOME/.ssh/id_rsa.pub"
  fi
  [[ -r "$public_key" ]] || { print -u2 "Cannot read public key: $public_key"; return 1; }
  if (( $+commands[pbcopy] )); then
    pbcopy < "$public_key"
  elif [[ -n "$WAYLAND_DISPLAY" ]] && (( $+commands[wl-copy] )); then
    wl-copy < "$public_key"
  elif [[ -n "$DISPLAY" ]] && (( $+commands[xclip] )); then
    xclip -selection clipboard < "$public_key"
  elif [[ -n "$DISPLAY" ]] && (( $+commands[xsel] )); then
    xsel --clipboard --input < "$public_key"
  else
    print -u2 'Install a clipboard provider: wl-copy (Wayland), xclip/xsel (X11), or pbcopy (macOS).'
    return 1
  fi
}

if (( $+commands[doppler] )); then
  alias rails='doppler run -- rails'
  alias rspec="doppler run -- bundle exec rspec"
fi

alias prof-utils='ssh profburial@192.168.1.79'
alias k8s-control='ssh profburial@192.168.1.84'
alias k8s-1='ssh profburial@192.168.1.207'

# Local overrides keep drive mounts, GPU selection and secrets machine-specific.
if [[ -r "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi

# Highlighting must load after widgets and local keybindings are defined.
for highlighting_script in "${XDG_DATA_HOME:-$HOME/.local/share}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" "${HOMEBREW_PREFIX:-/usr/local}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  if [[ -r "$highlighting_script" ]]; then
    source "$highlighting_script"
    break
  fi
done
unset highlighting_script
