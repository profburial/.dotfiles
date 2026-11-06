"""Exercise installation and shell behavior without changing the real home."""

import os
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
BASH = shutil.which("bash")
ZSH = shutil.which("zsh")


class DotfilesTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="dotfiles-tests-")
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.home = self.base / "home with spaces"
        self.home.mkdir()
        self.repo = self.base / "checkout with spaces"
        self.repo.mkdir()
        for name in ("install.sh", ".zshrc", "starship.toml", "nvim", "ghostty", "herdr", "k9s", "aerospace"):
            source = ROOT / name
            if source.is_dir():
                shutil.copytree(source, self.repo / name, symlinks=True)
            else:
                shutil.copy2(source, self.repo / name)
        self.environment = {
            "HOME": str(self.home),
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
            "TERM": "xterm-256color",
            "LC_ALL": "C",
        }
        self.config = self.home / ".config"
        self.tools = self.base / "tools"
        self.tools.mkdir()
        self.data = self.base / "local data"
        self.package_log = self.base / "package requests"
        self.environment.update(
            XDG_DATA_HOME=str(self.data), DOTFILES_TEST_TOOLS=str(self.tools),
            DOTFILES_TEST_PREFIX=str(self.base / "packages"),
            DOTFILES_TEST_PACKAGE_LOG=str(self.package_log),
        )
        for name in ("dirname", "mkdir", "mv", "ln", "readlink", "date", "mktemp", "rm", "sh", "chmod", "tar", "gzip"):
            (self.tools / name).symlink_to(shutil.which(name))
        fixture = (ROOT / "tests/fixtures/shell_dependency_command.py").read_text()
        for name in ("brew", "curl", "git", "id", "sudo", "dpkg-query", "rpm"):
            command = self.tools / name
            command.write_text("#!" + sys.executable + "\n" + fixture)
            command.chmod(0o755)
        for name in ("zsh", "starship"):
            command = self.tools / name
            command.write_text("#!/bin/sh\nexit 0\n")
            command.chmod(0o755)
        completions = self.data / "zsh-completions/src"
        completions.mkdir(parents=True)
        (completions / "_sample").write_text("#compdef sample\n")
        highlighting = self.data / "zsh-syntax-highlighting"
        highlighting.mkdir()
        (highlighting / "zsh-syntax-highlighting.zsh").write_text("# fixture\n")

    def install(self, platform: str = "Linux", success: bool = True) -> subprocess.CompletedProcess:
        tools = self.tools
        uname = tools / "uname"
        uname.write_text("#!/bin/sh\nprintf '%s\\n' '" + platform + "'\n")
        uname.chmod(0o755)
        environment = dict(self.environment, PATH=str(tools))
        result = subprocess.run(
            [BASH, str(self.repo / "install.sh")],
            cwd=self.base,
            env=environment,
            text=True,
            capture_output=True,
            timeout=30,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def assert_link(self, destination: Path, source: Path) -> None:
        self.assertTrue(destination.is_symlink(), str(destination))
        self.assertEqual(destination.resolve(), source.resolve())

    def test_installed_shell_dependencies_are_kept(self) -> None:
        for platform in ("Linux", "Darwin"):
            self.install(platform)
            self.install(platform)
        self.assertFalse(self.package_log.exists())

    def test_macos_installs_missing_shell_dependencies(self) -> None:
        (self.tools / "starship").unlink()
        shutil.rmtree(self.data)
        self.install("Darwin")
        requests = [json.loads(line) for line in self.package_log.read_text().splitlines()]
        self.assertEqual(requests, [["brew", "install", "starship", "zsh-completions", "zsh-syntax-highlighting"]])
        self.assert_link(self.config / "starship.toml", self.repo / "starship.toml")
        self.install("Darwin")
        self.assertEqual(len(self.package_log.read_text().splitlines()), 1)

    def test_linux_installs_missing_shell_dependencies(self) -> None:
        for manager in ("apt-get", "dnf", "pacman"):
            with self.subTest(manager=manager):
                # Each manager starts with the same missing shell and plugins.
                shutil.rmtree(self.data)
                for name in ("zsh", "starship", "curl", "git", "tar", "gzip"):
                    (self.tools / name).unlink(missing_ok=True)
                (self.home / ".local/bin/starship").unlink(missing_ok=True)
                self.package_log.unlink(missing_ok=True)
                (self.tools / manager).symlink_to(self.tools / "brew")
                self.install()
                requests = [json.loads(line) for line in self.package_log.read_text().splitlines()]
                package_requests = [r for r in requests if r[0] == manager]
                expected = {
                    "apt-get": [["apt-get", "update"], ["apt-get", "install", "-y", "zsh", "curl", "git", "tar", "gzip", "ca-certificates"]],
                    "dnf": [["dnf", "install", "-y", "zsh", "curl", "git", "tar", "gzip", "ca-certificates"]],
                    "pacman": [["pacman", "-S", "--needed", "--noconfirm", "zsh", "curl", "git", "tar", "gzip", "ca-certificates"]],
                }
                self.assertEqual(package_requests, expected[manager])
                self.assertTrue(os.access(self.home / ".local/bin/starship", os.X_OK))
                self.assertTrue((self.data / "zsh-completions/src/_sample").is_file())
                self.assertTrue((self.data / "zsh-syntax-highlighting/zsh-syntax-highlighting.zsh").is_file())
                self.install()
                self.assertEqual(len(self.package_log.read_text().splitlines()), len(requests))
                (self.tools / manager).unlink()

    def test_dependency_failure_preserves_configs(self) -> None:
        (self.home / ".zshrc").write_text("original shell")
        for command in ("brew", "apt-get", "curl", "git"):
            with self.subTest(command=command):
                (self.tools / "starship").unlink(missing_ok=True)
                (self.home / ".local/bin/starship").unlink(missing_ok=True)
                self.environment["DOTFILES_TEST_FAIL"] = command
                if command == "apt-get":
                    (self.tools / "zsh").unlink()
                    (self.tools / "apt-get").symlink_to(self.tools / "brew")
                if command == "git":
                    shutil.rmtree(self.data)
                self.install("Darwin" if command == "brew" else "Linux", success=False)
                self.assertEqual((self.home / ".zshrc").read_text(), "original shell")
                self.assertFalse(self.config.exists())

    def test_missing_package_manager_preserves_configs(self) -> None:
        (self.tools / "zsh").unlink()
        result = self.install(success=False)
        self.assertIn("No supported package manager", result.stderr)
        self.assertFalse(self.config.exists())

    def test_fresh_install_links_configs(self) -> None:
        self.install()
        for name in ("nvim", "ghostty"):
            self.assert_link(self.config / name, self.repo / name)
        for name in ("config.yaml", "aliases.yaml", "skins"):
            self.assert_link(self.config / "k9s" / name, self.repo / "k9s" / name)
        self.assert_link(self.config / "herdr/config.toml", self.repo / "herdr/config.toml")
        self.assert_link(self.home / ".zshrc", self.repo / ".zshrc")
        self.assert_link(self.config / "starship.toml", self.repo / "starship.toml")
        self.assertFalse((self.home / ".antigenrc").exists())
        self.assertFalse((self.home / "antigen.zsh").exists())
        self.assertFalse((self.config / "aerospace").exists())
        self.assertFalse((self.config / "k9s/clusters").exists())
        self.assert_link(self.config / "ghostty/config.ghostty", self.repo / "ghostty/config")

    def test_old_antigen_links_are_backed_up(self) -> None:
        names = ("antigen.zsh", ".antigenrc")
        for name in names:
            (self.home / name).symlink_to(self.repo.resolve() / name)
        self.install()
        self.install()
        for name in names:
            self.assertFalse((self.home / name).is_symlink())
            backups = list(self.home.glob(name + ".backup.*"))
            self.assertEqual(len(backups), 1)
            self.assertEqual(os.readlink(backups[0]), str(self.repo.resolve() / name))
        (self.home / ".antigenrc").write_text("unrelated settings")
        (self.home / "antigen.zsh").symlink_to(self.base / "unrelated-antigen")
        self.install()
        self.assertEqual((self.home / ".antigenrc").read_text(), "unrelated settings")
        self.assertEqual(os.readlink(self.home / "antigen.zsh"), str(self.base / "unrelated-antigen"))

    @unittest.skipUnless(ZSH, "Zsh is required for shell startup checks")
    def test_shell_loads_prompt_and_highlighting(self) -> None:
        tools = self.home / "bin"
        tools.mkdir()
        starship = tools / "starship"
        starship.write_text("#!/bin/sh\nprintf '%s\\n' \"PROMPT='fixture prompt ' \"\n")
        starship.chmod(0o755)
        prefix = self.base / "packages"
        completions = self.data / "zsh-completions/src"
        (completions / "_fixture").write_text("#compdef fixture\n_arguments '--sample[Sample option]'\n")
        highlighting = self.data / "zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
        highlighting.write_text('export HIGHLIGHT_EDITOR="$EDITOR"\n')
        (self.home / ".zshrc.local").write_text("export EDITOR=custom-editor\n")
        script = '''
OSTYPE=linux-gnu
source "$DOTFILES_TEST_RC"
[[ "$PROMPT" == 'fixture prompt ' ]] || exit 30
[[ "$HIGHLIGHT_EDITOR" == custom-editor ]] || exit 31
[[ "$STARSHIP_CONFIG" == "$XDG_CONFIG_HOME/starship.toml" ]] || exit 32
[[ "${_comps[fixture]}" == _fixture ]] || exit 33
'''
        result = subprocess.run(
            [ZSH, "-df", "-c", script],
            env=dict(self.environment, DOTFILES_TEST_RC=str(self.repo / ".zshrc"),
                     HOMEBREW_PREFIX=str(prefix), XDG_CONFIG_HOME=str(self.home / "custom config")),
            text=True, capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stderr, "")

    def test_conflicts_are_backed_up(self) -> None:
        (self.config / "nvim").mkdir(parents=True)
        (self.config / "nvim/init.lua").write_text("original editor")
        (self.home / ".zshrc").write_text("original shell")
        (self.config / "ghostty").symlink_to("missing-original")
        self.install()
        editor_backups = list(self.config.glob("nvim.backup.*"))
        shell_backups = list(self.home.glob(".zshrc.backup.*"))
        link_backups = list(self.config.glob("ghostty.backup.*"))
        self.assertEqual([p.joinpath("init.lua").read_text() for p in editor_backups], ["original editor"])
        self.assertEqual([p.read_text() for p in shell_backups], ["original shell"])
        self.assertEqual([os.readlink(p) for p in link_backups], ["missing-original"])
        # A second conflict must preserve the previous backup too.
        (self.home / ".zshrc").unlink()
        (self.home / ".zshrc").write_text("another shell")
        self.install()
        self.assertEqual(sorted(p.read_text() for p in self.home.glob(".zshrc.backup.*")),
                         ["another shell", "original shell"])

    def test_rerun_keeps_links_and_editor_state(self) -> None:
        markers = [self.home / ".local" / kind / "nvim/sentinel" for kind in ("share", "state")]
        for marker in markers:
            marker.parent.mkdir(parents=True)
            marker.write_text("keep me")
        self.install()
        before = {str(p): os.readlink(p) for p in self.home.rglob("*") if p.is_symlink()}
        self.install()
        after = {str(p): os.readlink(p) for p in self.home.rglob("*") if p.is_symlink()}
        self.assertEqual(after, before)
        self.assertEqual(list(self.home.rglob("*.backup.*")), [])
        self.assertEqual([p.read_text() for p in markers], ["keep me", "keep me"])

    def test_platform_links_match_os_and_xdg_root(self) -> None:
        self.config = self.home / "custom config"
        self.environment["XDG_CONFIG_HOME"] = str(self.config)
        self.install("Darwin")
        self.assert_link(self.config / "aerospace", self.repo / "aerospace")
        self.assert_link(self.config / "nvim", self.repo / "nvim")
        self.assert_link(self.config / "starship.toml", self.repo / "starship.toml")
        self.assert_link(self.config / "k9s/config.yaml", self.repo / "k9s/config.yaml")
        self.assertFalse((self.home / ".config").exists())

    def test_old_k9s_directory_link_is_migrated(self) -> None:
        self.config.mkdir()
        (self.config / "k9s").symlink_to(self.repo / "k9s", target_is_directory=True)
        self.install()
        self.assertTrue((self.config / "k9s").is_dir())
        self.assertFalse((self.config / "k9s").is_symlink())
        backups = list(self.config.glob("k9s.backup.*"))
        self.assertEqual([p.resolve() for p in backups], [(self.repo / "k9s").resolve()])
        self.assert_link(self.config / "k9s/config.yaml", self.repo / "k9s/config.yaml")
        self.assertFalse((self.repo / "k9s/config.yaml").is_symlink())

    def test_invalid_input_fails_before_installation(self) -> None:
        self.install("UnsupportedOS", success=False)
        self.assertEqual(list(self.home.iterdir()), [])
        self.environment["XDG_CONFIG_HOME"] = "relative-config"
        self.install(success=False)
        self.assertEqual(list(self.home.iterdir()), [])
        del self.environment["XDG_CONFIG_HOME"]
        (self.repo / "starship.toml").unlink()
        self.install(success=False)
        self.assertEqual(list(self.home.iterdir()), [])
        shutil.copy2(ROOT / "starship.toml", self.repo / "starship.toml")
        (self.repo / "herdr/config.toml").unlink()
        self.install(success=False)
        self.assertEqual(list(self.home.iterdir()), [])

    @unittest.skipUnless(ZSH, "Zsh is required for shell startup checks")
    def test_minimal_shell_starts(self) -> None:
        script = '''
OSTYPE=linux-gnu
source "$DOTFILES_TEST_RC"
[[ "$path[(Ie)$HOME/.bun/bin]" -gt 0 ]] || exit 10
[[ "$path[(Ie)$HOME/.opencode/bin]" -gt 0 ]] || exit 11
[[ "$K9S_CONFIG_DIR" == "$HOME/.config/k9s" ]] || exit 12
[[ -n "$EDITOR" && "$VISUAL" == "$EDITOR" ]] || exit 13
[[ -z "$HF_HOME$CUDA_VISIBLE_DEVICES$LD_LIBRARY_PATH" ]] || exit 14
[[ -z "$GPG_TTY" ]] || exit 15
aws_profile 'profile with spaces'
[[ "$AWS_PROFILE" == 'profile with spaces' ]] || exit 16
[[ ! -o correct && ! -o correct_all ]] || exit 17
[[ "$PROMPT" == '%n@%m %~ %# ' ]] || exit 18
[[ "$HISTFILE" == "$HOME/.zsh_history" && -o share_history ]] || exit 19
print -r -- started
'''
        result = subprocess.run(
            [ZSH, "-df", "-c", script],
            env=dict(self.environment, DOTFILES_TEST_RC=str(self.repo / ".zshrc")),
            text=True, capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(result.stdout, "started\n")

    @unittest.skipUnless(ZSH, "Zsh is required for shell startup checks")
    def test_shell_commands_use_platform_providers(self) -> None:
        tools = self.home / "bin"
        tools.mkdir()
        output = self.base / "command output"
        for name, body in {
            "pbcopy": 'cat > "$DOTFILES_TEST_OUTPUT"',
            "sudo": 'printf "%s\\n" "$*" > "$DOTFILES_TEST_OUTPUT"',
        }.items():
            command = tools / name
            command.write_text("#!/bin/sh\n" + body + "\n")
            command.chmod(0o755)
        key = self.base / "public key.pub"
        key.write_text("ssh-ed25519 fixture\n")
        script = '''
OSTYPE=linux-gnu
source "$DOTFILES_TEST_RC"
ssh_copy "$DOTFILES_TEST_KEY" || exit 20
[[ "$(cat "$DOTFILES_TEST_OUTPUT")" == 'ssh-ed25519 fixture' ]] || exit 21
OSTYPE=linux-gnu
port_forward || exit 22
[[ "$(cat "$DOTFILES_TEST_OUTPUT")" == 'sysctl -w net.ipv4.ip_forward=1' ]] || exit 23
OSTYPE=darwin
port_forward || exit 24
[[ "$(cat "$DOTFILES_TEST_OUTPUT")" == 'sysctl -w net.inet.ip.forwarding=1' ]] || exit 25
'''
        result = subprocess.run(
            [ZSH, "-df", "-c", script],
            env=dict(self.environment, DOTFILES_TEST_RC=str(self.repo / ".zshrc"),
                     DOTFILES_TEST_OUTPUT=str(output), DOTFILES_TEST_KEY=str(key)),
            text=True, capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stderr, "")

    @unittest.skipUnless(ZSH, "Zsh is required for shell startup checks")
    def test_local_overrides_load_last(self) -> None:
        (self.home / ".zshrc.local").write_text("export EDITOR=custom-editor\n")
        result = subprocess.run(
            [ZSH, "-df", "-c", 'OSTYPE=linux-gnu; source "$DOTFILES_TEST_RC"; print -r -- "$EDITOR"'],
            env=dict(self.environment, DOTFILES_TEST_RC=str(self.repo / ".zshrc")),
            text=True, capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(result.stdout, "custom-editor\n")


if __name__ == "__main__":
    unittest.main(verbosity=2)
