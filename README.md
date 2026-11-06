# Dotfiles

Hi. These are my dotfiles. If you're reading this, you probably think I'm super cool and want to be just like me. 


You can use my config if you want. It's maybe a pretty okay idea, but probably not worth your time.  


You'll probably want to use these on a *nix machine, preferably osx. If your toaster follows POSIX they might work there.
Give it a shot. If they don't you should probably submit an issue.   

## Install

Clone this repository anywhere, then run from its root:

```sh
bash install.sh
exec zsh
```

The installer requires Bash and standard system utilities. It installs missing shell dependencies before linking configuration: Zsh, Starship, zsh-completions and zsh-syntax-highlighting. Existing installations are kept, and reruns do not update them.

On macOS it uses Homebrew, downloading the [official Homebrew installer](https://brew.sh/) if Homebrew is absent. Homebrew setup may request administrator access. Only missing formulae are passed to `brew install`.

On Linux it supports Ubuntu/Debian (`apt-get`), Fedora (`dnf`) and Arch (`pacman`). It installs missing Zsh and download tools with the system package manager, using sudo when not running as root. Missing Starship is installed through its [official installer](https://starship.rs/) into `~/.local/bin`. If no system copy of a plugin is found, the installer clones zsh-completions **0.36.0** and zsh-syntax-highlighting **0.8.0** into `${XDG_DATA_HOME:-$HOME/.local/share}`. Both XDG directory overrides must be absolute paths. Incomplete local plugin directories are reported rather than overwritten.

Network access is needed only when dependencies are missing. Package or download failures stop installation before configuration links are changed. Successfully installed dependencies remain available for a retry. Application packages, fonts and language runtimes remain separate prerequisites.

The shell recognizes the user-local plugin locations, Homebrew's share directories, `/usr/local/share/zsh-completions`, `/usr/share/zsh-completions` and the corresponding syntax-highlighting paths. Distribution-provided completions also use Zsh's default `fpath`.

Shell startup does not download plugins. If Starship is absent, the shell uses a plain prompt; completion still works without the optional extra definitions. Syntax highlighting is enabled when its script is installed.

The installer uses the checkout's actual location and `${XDG_CONFIG_HOME:-$HOME/.config}`. Keep the checkout in place because installed files are symlinks. It installs AeroSpace only on macOS. K9s gets shared config, aliases and skins; cluster state and screen dumps stay local. Herdr gets only `config.toml`; its session, logs and socket stay local. Ghostty supplies both `config` and `config.ghostty` filenames for compatibility across versions.

Existing files, directories and conflicting symlinks are moved to adjacent `.backup.TIMESTAMP` paths, with a numeric suffix when needed. The installer prints each backup location. Correct links are left alone on reruns. Neovim data, cache and state are preserved. To restore a config, remove only the installed symlink after checking its destination, then move its backup back into place. With the old installer, the K9s directory itself may have been a symlink; it is backed up before individual files are linked.

Install the applications used on each machine with its package manager. To make Zsh the login shell, use `chsh -s "$(command -v zsh)"` after ensuring that path is listed in `/etc/shells`.

## Neovim

TVIM requires Neovim **0.12.5+**, Git, ripgrep, curl, tar, a C compiler and tree-sitter CLI **0.26.1+**. Install a Nerd Font, such as the configured RobotoMono Nerd Font, for icons. macOS compilation needs Xcode command-line tools. Linux needs its distribution's compiler toolchain. Clipboard support needs a system provider: `pbcopy` on macOS, `wl-copy` on Wayland, or `xclip`/`xsel` on X11.

Language tools also need their runtimes: Node/npm, Ruby/gem/Bundler, Python/pip and Go for the corresponding languages. Runtime managers are optional and are initialized only when present. Configure each project's runtime versions and install its bundle or dependencies before expecting language servers to work.

After installing prerequisites:

```sh
nvim
```

First launch downloads plugins, language tools and parsers. Let installation finish, then inspect `:checkhealth`, `:Mason` and `:ConformInfo`. Use `:MasonToolsInstallSync` to retry missing tools and `:TSInstall <language>` to retry parsers. Existing language-tool versions are not automatically upgraded. The old editor's plugin directories remain on disk; TVIM selects plugins through its own lockfile. When migrating an existing NvChad installation, restore the locked versions before the next editing session:

```sh
cp nvim/lazy-lock.json nvim/lazy-lock.json.before-migration
nvim --headless '+Lazy! restore' +qa
cp nvim/lazy-lock.json.before-migration nvim/lazy-lock.json
nvim --headless '+Lazy! restore' +qa
```

Run these commands from the dotfiles root. The saved lockfile protects the intended versions if Lazy rewrites entries while installing missing plugins. An old Treesitter version can report a configuration error during the migration; restart Neovim after the final restore finishes.

See [TVIM's README](nvim/README.md) for shortcuts, formatting, language setup and maintenance commands.

## Shell

Zsh runs directly without Oh My Zsh or Antigen. Tab completion is case-sensitive and supports menu selection. Command spelling correction is disabled. History is saved to `~/.zsh_history` and shared across shells; commands starting with a space are excluded. The shell uses Emacs editing keys and allows changing directories by typing their path.

`starship.toml` supplies a Spaceship-like two-line prompt: directory, Git branch/status, detected language versions, AWS profile/region, Kubernetes context/namespace and command duration above a green input arrow that turns red after failure. AWS information is shown when available, even without detected credentials; Kubernetes reads the current kubeconfig. These modules use Starship's [configuration options](https://starship.rs/config/). Ghostty already selects a Nerd Font.

The installer links the prompt config at `${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml`. Set `STARSHIP_CONFIG` before shell initialization to select a different file. Old `~/antigen.zsh` and `~/.antigenrc` symlinks pointing into this checkout are moved to backup paths; unrelated files and plugin caches are left alone. The Antigen sources are removed from this checkout, so restoring those old links requires restoring the corresponding repository revision too. Oh My Zsh plugin aliases and helpers are no longer loaded; custom functions and aliases in `.zshrc` are retained.

## Machine settings

Put private or machine-specific settings in `~/.zshrc.local`.

On macOS the shell loads Homebrew through `brew shellenv` from the Apple Silicon or Intel prefix, so `HOMEBREW_PREFIX`, `MANPATH` and `INFOPATH` are set alongside `PATH`. Linux does not use Homebrew. Runtime managers (asdf, nvm, pyenv) are initialized afterwards when present.

The shared config keeps personal SSH aliases. `rails` and `rspec` use Doppler only when it is installed. `ssh_copy [public-key-path]` supports macOS, Wayland and X11 clipboards; its default key is Ed25519, falling back to RSA. `port_forward` enables IPv4 forwarding through the platform's sysctl and requests sudo when called.

## Verify

Run the isolated installer and shell checks with Bash, Python 3 and Zsh:

```sh
bash tests/run.sh
bash -n install.sh tests/run.sh
zsh -n .zshrc
```

Tests use temporary homes and package/download fixtures; they do not modify the real home directory, install real packages or download plugins. Linux and Darwin installer branches are checked with a controlled `uname`. Native package installation still needs validation on the target operating system.

For Neovim development, the integration suite uses the retained launcher to isolate test dependencies from the default profile. It requires Python 3.9+ and a provisioned `tvim` plugin/parser tree. From the dotfiles root:

```sh
cd nvim
./bin/tvim --headless '+Lazy! restore' +qa
./bin/tvim --headless "+lua require('nvim-treesitter').install(require('configs.languages').parsers):wait(300000)" +qa
./tests/run.sh
```

These tests use external-tool fixtures. They do not exercise system package installation or replace manual visual review of the terminal and editor.
