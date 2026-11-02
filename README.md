# Dotfiles

Personal Zsh, TVIM/Neovim, Ghostty, K9s and macOS AeroSpace configuration for Linux and macOS.

## Install

Clone this repository anywhere, then run from its root:

```sh
bash install.sh
exec zsh
```

The installer requires Bash and standard system utilities. Install Zsh and Git before starting the configured shell. Git and network access are needed on the first shell launch to download the Antigen plugins and Spaceship theme; Oh My Zsh is loaded through Antigen, so a separate installation is unnecessary. With Antigen or Git absent, the shell uses basic completion and a plain prompt.

The installer uses the checkout's actual location and `${XDG_CONFIG_HOME:-$HOME/.config}`. Keep the checkout in place because installed files are symlinks. It installs AeroSpace only on macOS. K9s gets shared config, aliases and skins; cluster state and screen dumps stay local. Ghostty supplies both `config` and `config.ghostty` filenames for compatibility across versions.

Existing files, directories and conflicting symlinks are moved to adjacent `.backup.TIMESTAMP` paths, with a numeric suffix when needed. The installer prints each backup location. Correct links are left alone on reruns. Neovim data, cache and state are preserved. To restore a config, remove only the installed symlink after checking its destination, then move its backup back into place. With the old installer, the K9s directory itself may have been a symlink; it is backed up before individual files are linked.

This installs configuration, not application packages, fonts or language runtimes. Install only the applications used on each machine with its package manager. To make Zsh the login shell, use `chsh -s "$(command -v zsh)"` after ensuring that path is listed in `/etc/shells`.

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

## Machine settings

Put private or machine-specific settings in `~/.zshrc.local`.

The shared config keeps personal SSH aliases. `rails` and `rspec` use Doppler only when it is installed. `ssh_copy [public-key-path]` supports macOS, Wayland and X11 clipboards; its default key is Ed25519, falling back to RSA. `port_forward` enables IPv4 forwarding through the platform's sysctl and requests sudo when called.

## Verify

Run the isolated installer and shell checks with Bash, Python 3 and Zsh:

```sh
bash tests/run.sh
bash -n install.sh tests/run.sh
zsh -n .zshrc .antigenrc
```

Tests use temporary homes and do not modify the real home directory or download plugins. Linux and Darwin installer branches are checked with a controlled `uname`; native macOS execution still needs a macOS host.

For Neovim development, the integration suite uses the retained launcher to isolate test dependencies from the default profile. It requires Python 3.9+ and a provisioned `tvim` plugin/parser tree. From the dotfiles root:

```sh
cd nvim
./bin/tvim --headless '+Lazy! restore' +qa
./bin/tvim --headless "+lua require('nvim-treesitter').install(require('configs.languages').parsers):wait(300000)" +qa
./tests/run.sh
```

These tests use external-tool fixtures. They do not exercise system package installation or replace manual visual review of the terminal and editor.
