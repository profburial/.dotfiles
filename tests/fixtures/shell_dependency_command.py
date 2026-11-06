"""Emulate package/download boundaries inside the temporary test home."""

import json
import os
from pathlib import Path
import sys

command = Path(sys.argv[0]).name
arguments = sys.argv[1:]
tools = Path(os.environ['DOTFILES_TEST_TOOLS'])
prefix = Path(os.environ['DOTFILES_TEST_PREFIX'])
data = Path(os.environ['XDG_DATA_HOME'])


def executable(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('#!/bin/sh\nexit 0\n')
    path.chmod(0o755)


def plugin(name: str, root: Path) -> None:
    if name == 'zsh-completions':
        root.mkdir(parents=True, exist_ok=True)
        (root / '_sample').write_text('#compdef sample\n')
    else:
        root.mkdir(parents=True, exist_ok=True)
        (root / 'zsh-syntax-highlighting.zsh').write_text('# fixture\n')


if command == 'brew' and arguments == ['--prefix']:
    print(prefix)
    sys.exit(0)
if command in ('dpkg-query', 'rpm') or (command == 'pacman' and arguments[:1] == ['-Qq']):
    sys.exit(1)
if command == 'id':
    print('1000')
    sys.exit(0)
if command == 'sudo':
    os.execv(str(tools / arguments[0]), arguments)

with Path(os.environ['DOTFILES_TEST_PACKAGE_LOG']).open('a') as log:
    log.write(json.dumps([command, *arguments]) + '\n')
if os.environ.get('DOTFILES_TEST_FAIL') == command:
    sys.exit(42)

if command == 'brew':
    assert arguments[0] == 'install', arguments
    for package in arguments[1:]:
        if package in ('zsh', 'starship'):
            executable(tools / package)
        else:
            plugin(package, prefix / 'share' / package)
elif command in ('apt-get', 'dnf', 'pacman'):
    for package in ('zsh', 'curl', 'git', 'tar', 'gzip'):
        if package in arguments:
            if package in ('curl', 'git'):
                (tools / package).write_text(Path(__file__).read_text())
                (tools / package).chmod(0o755)
            else:
                executable(tools / package)
elif command == 'curl':
    # Download a local installer fixture instead of contacting a service.
    output = Path(arguments[arguments.index('--output') + 1])
    assert 'https://starship.rs/install.sh' in arguments, arguments
    output.write_text('#!/bin/sh\nprintf "#!/bin/sh\\nexit 0\\n" > "$HOME/.local/bin/starship"\nchmod +x "$HOME/.local/bin/starship"\n')
elif command == 'git':
    assert arguments[:1] == ['clone'], arguments
    destination = Path(arguments[-1])
    name = destination.name
    plugin(name, destination / 'src' if name == 'zsh-completions' else destination)
else:
    raise AssertionError((command, arguments))
