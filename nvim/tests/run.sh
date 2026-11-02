#!/bin/sh
set -eu
checkout=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
cd "$checkout"
plugin_root="${XDG_DATA_HOME:-$HOME/.local/share}/tvim/lazy"
[ -d "$plugin_root" ] || { echo 'Provision TVIM plugins first: ./bin/tvim --headless "+Lazy! restore" +qa' >&2; exit 1; }
trial_root=$(mktemp -d "${TMPDIR:-/tmp}/tvim-tests.XXXXXXXX")
trial_root=$(CDPATH= cd -- "$trial_root" && pwd -P)
trap 'rm -rf "$trial_root"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$trial_root/data/tvim" "$trial_root/config/nvim" "$trial_root/cache" "$trial_root/state"
printf '%s\n' 'default profile sentinel' > "$trial_root/config/nvim/init.lua"
cp -R "$plugin_root" "$trial_root/data/tvim/lazy"
site_root="${XDG_DATA_HOME:-$HOME/.local/share}/tvim/site"
if [ -d "$site_root" ]; then cp -R "$site_root" "$trial_root/data/tvim/site"; fi
export XDG_DATA_HOME="$trial_root/data"
export XDG_CONFIG_HOME="$trial_root/config"
export XDG_CACHE_HOME="$trial_root/cache"
export XDG_STATE_HOME="$trial_root/state"
export TVIM_TEST_ROOT="$trial_root"
nvim --headless -u NONE -i NONE -l tests/preflight.lua
./bin/tvim --headless -i NONE --cmd 'lua dofile("tests/isolated.lua")' -c 'lua dofile("tests/run.lua")'
