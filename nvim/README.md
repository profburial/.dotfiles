# TVIM

Personal Neovim configuration with the Terry color scheme, language tooling, and editing shortcuts. The dotfiles installer installs this directory as the default Neovim configuration.

## Requirements

- Neovim **0.12.5+**.
- Git, ripgrep, curl, tar, a C compiler, and tree-sitter CLI **0.26.1+**.
- A Nerd Font for icons and a clipboard provider supported by `:checkhealth vim.provider`.
- Node/npm for web tooling and Prettier; Ruby/gem/Bundler for Ruby tooling; Python/pip for Python tooling; Go for gopls.

On macOS, install the Xcode command-line tools with `xcode-select --install`. On Linux, install your distribution's compiler toolchain. On Arch/Manjaro, `sudo pacman -S npm tree-sitter-cli` installs npm and the parser CLI if missing.

Check prerequisites:

```sh
nvim --version
git --version
rg --version
npm --version
tree-sitter --version
```

For Ruby projects, keep `ruby-lsp`, `ruby-lsp-rails`, and `standard` available in the project's bundle where applicable. Run `bundle install` and, for Rails projects, `bundle exec rails --version` from the project directory to check the selected Ruby and bundle.

## Install and launch

Run the installer from the dotfiles repository root:

```sh
bash install.sh
```

The installer links this directory to `${XDG_CONFIG_HOME:-$HOME/.config}/nvim`, backing up conflicting configurations. Keep the dotfiles checkout in place. See the [dotfiles README](../README.md#neovim) for migration from an existing NvChad installation.

Open Neovim from any project directory:

```sh
nvim
```

The first launch needs network access to download plugins, language tools, and parsers. Let installation finish, then check `:checkhealth`, `:Mason`, and `:ConformInfo`. Plugins and tools use the default `nvim` data directory; existing state and caches are preserved.

## Maintenance

Commands starting with `:` run inside Neovim. Run the maintenance shell commands from the installed configuration directory:

```sh
cd "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
```

### Plugins

Plugin revisions are pinned in `lazy-lock.json`; automatic update checking is disabled.

| Command | Purpose |
| --- | --- |
| `:Lazy` | Inspect plugin status and errors |
| `:Lazy restore` | Install/check out the revisions in the lockfile |
| `:Lazy update` | Upgrade plugins and update the lockfile |
| `:Lazy sync` | Install missing plugins, clean unused plugins, and update plugins |

To restore pinned versions from the shell:

```sh
nvim --headless '+Lazy! restore' +qa
```

Before upgrading, save a copy of the lockfile:

```sh
cp lazy-lock.json lazy-lock.json.bak
```

Run `:Lazy update`, then the verification commands below. Review the lockfile diff before committing it:

```sh
git diff -- lazy-lock.json
```

To roll back that upgrade:

```sh
cp lazy-lock.json.bak lazy-lock.json
nvim --headless '+Lazy! restore' +qa
```

Run `:TSUpdate` afterward to align parsers with the restored Treesitter version. The plugin lockfile does not pin Mason tool versions.

### Language servers and formatters

| Command | Purpose |
| --- | --- |
| `:Mason` | Inspect installed tools, installation errors, and available updates |
| `:MasonUpdate` | Refresh the package registry |
| `:MasonToolsInstallSync` | Install missing tools declared in the config |
| `:MasonInstall <package>` | Install or update a specific tool |
| `:ConformInfo` | Inspect formatters and their availability for the current buffer |
| `:checkhealth vim.lsp` | Inspect LSP setup and active clients |
| `:lua vim.cmd.edit(vim.lsp.log.get_filename())` | Open the LSP log |

Mason installs missing configured tools on startup; it does not automatically upgrade installed tools. Refresh the registry, then choose updates in `:Mason` or use `:MasonInstall <package>`. After installing missing runtimes such as npm, retry `:MasonToolsInstallSync`.

Edit `lua/configs/languages.lua` to maintain language support: `servers` configures LSP servers, `tools` declares Mason packages, `parsers` declares Treesitter parsers, and `formatters_by_ft` selects formatters. Restart Neovim after changing the policy. Project dependencies still belong in each project's package manager or Ruby bundle.

### Treesitter parsers

| Command | Purpose |
| --- | --- |
| `:TSInstall <language>` | Install or retry a parser, for example `:TSInstall ruby` |
| `:TSUpdate` | Update installed parsers |
| `:checkhealth nvim-treesitter` | Diagnose parser setup and prerequisites |

Configured parsers install asynchronously on startup. Reopen a buffer if highlighting is unavailable during installation. To install all configured parsers and wait for completion from the shell:

```sh
nvim --headless "+lua require('nvim-treesitter').install(require('configs.languages').parsers):wait(300000)" +qa
```

### Troubleshooting

| Command | Purpose |
| --- | --- |
| `:checkhealth` | Run health checks |
| `:checkhealth vim.provider` | Check clipboard and other providers |
| `:messages` | Read startup, parser, and formatter errors |
| `:lua print(vim.fn.stdpath("config"))` | Locate the active config |
| `:lua print(vim.fn.stdpath("data"))` | Locate plugins and Mason tools |
| `:lua print(vim.fn.stdpath("state"))` | Locate state and logs |
| `:lua print(vim.fn.stdpath("cache"))` | Locate cached files |

### Verification and formatting

Check Lua formatting after editing the configuration:

```sh
stylua --check init.lua colors lua tests
```

Apply formatting with `stylua init.lua colors lua tests`. If Stylua is installed through Mason but is not on your shell's PATH, use `"${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason/bin/stylua"`.

After updating plugins or language tools, open representative projects and check completion, navigation, rename, diagnostics, and formatting on save. See the [dotfiles verification instructions](../README.md#verify) for automated tests.

## Shortcuts

Space is the leader.

| Keys | Action |
| --- | --- |
| `;`, `jk` | Command mode, leave insert mode |
| Ctrl-n, Space e | Toggle or focus file tree |
| Tree: `/` or `f`, then Enter | Filter file names live, then return to tree navigation |
| Tree: Escape or `F` | Clear the active filter |
| Space ff / fa / fw | Find files / all files / text |
| Space fb / fh / ma / fo / fz | Buffers / help / marks / recent files / current-buffer search |
| Tab / Shift-Tab | Next / previous file buffer |
| Space b / x | New buffer / close clean file buffer |
| Space / | Native comment toggle, including visual selections |
| Space fm | Format file or selection |
| Space ds | Diagnostic location list |
| `gd`, `gD`, Space D | Definition, declaration, type definition |
| Space ra | Rename with native input |
| Space wa / wr / wl | Add / remove / list workspace folders |
| `K`, insert Ctrl-k | Hover, signature help |
| Space ch / wK / wk | Shortcut list / all shortcuts / query shortcuts |
| Ctrl-Space / Ctrl-e / Enter | Open / close / accept completion |
| Ctrl-p/n, Tab/Shift-Tab | Select completion while popup is visible |
| Ctrl-d/f | Scroll completion documentation |

The tree filter uses Vim regular expressions and keeps folders visible for navigation. These shortcuts apply only to the tree; `/` in a file still searches its contents.

`:ShowRubyDeps` opens direct dependencies in quickfix; `:ShowRubyDeps all` includes every returned dependency. Save modified buffers before closing them with Space x.

Format on save uses Stylua for Lua, Prettier then eslint_d for JavaScript/TypeScript and JSX/TSX, Ruff fixes for Python, Prettier for CSS/HTML, and shfmt for shell. Other languages use available LSP formatting. Ruby prefers StandardRB when both Ruby servers support formatting. A formatter failure leaves the file writable and reports the error.

## Layout

| Path | Purpose |
| --- | --- |
| `init.lua` | Version check, lazy.nvim bootstrap, and startup |
| `lazy-lock.json` | Pinned plugin revisions |
| `lua/options.lua` | Editor settings |
| `lua/mappings.lua` | Keybindings |
| `lua/autocmds.lua` | Editor autocommands |
| `lua/plugins/` | Plugin configuration grouped by feature |
| `lua/configs/languages.lua` | Language servers, tools, parsers, and formatters |
| `lua/configs/buffers.lua` | Custom buffer behavior |
| `lua/configs/ruby.lua` | Ruby-specific behavior |
| `lua/themes/terry.lua`, `colors/terry.lua` | Terry palette and color scheme |
| `lua/themes/contrast.lua` | Color readability helpers; Terry lightens file icons that fall below WCAG AA on the tree background |
| `tests/` | Headless behavior tests |

## Attribution

Editor defaults, mapping choices, icon glyphs, and layout choices are adapted from [NvChad](https://github.com/NvChad/NvChad) and [NvChad UI](https://github.com/NvChad/ui), distributed under GPL-3.0. Their runtime modules are not imported. Each plugin retains its upstream license in its installed checkout.
