"""Exercise installation and shell behavior without changing the real home."""

import os
from pathlib import Path
import shutil
import subprocess
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
        for name in ("install.sh", ".zshrc", ".antigenrc", "antigen.zsh", "nvim", "ghostty", "k9s", "aerospace"):
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

    def install(self, platform: str = "Linux", success: bool = True) -> subprocess.CompletedProcess:
        tools = self.base / "tools"
        tools.mkdir(exist_ok=True)
        uname = tools / "uname"
        uname.write_text("#!/bin/sh\nprintf '%s\\n' '" + platform + "'\n")
        uname.chmod(0o755)
        environment = dict(self.environment, PATH=str(tools) + ":" + self.environment["PATH"])
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

    def test_fresh_install_links_configs(self) -> None:
        self.install()
        for name in ("nvim", "ghostty"):
            self.assert_link(self.config / name, self.repo / name)
        for name in ("config.yaml", "aliases.yaml", "skins"):
            self.assert_link(self.config / "k9s" / name, self.repo / "k9s" / name)
        for name in (".zshrc", ".antigenrc", "antigen.zsh"):
            self.assert_link(self.home / name, self.repo / name)
        self.assertFalse((self.config / "aerospace").exists())
        self.assertFalse((self.config / "k9s/clusters").exists())
        self.assert_link(self.config / "ghostty/config.ghostty", self.repo / "ghostty/config")

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
        self.assert_link(self.config / "k9s/config.yaml", self.repo / "k9s/config.yaml")
        self.assertFalse((self.home / ".config").exists())

    def test_old_k9s_directory_link_is_migrated(self) -> None:
        self.config.mkdir()
        (self.config / "k9s").symlink_to(self.repo / "k9s", target_is_directory=True)
        self.install()
        self.assertTrue((self.config / "k9s").is_dir())
        self.assertFalse((self.config / "k9s").is_symlink())
        backups = list(self.config.glob("k9s.backup.*"))
        self.assertEqual([p.resolve() for p in backups], [self.repo / "k9s"])
        self.assert_link(self.config / "k9s/config.yaml", self.repo / "k9s/config.yaml")
        self.assertFalse((self.repo / "k9s/config.yaml").is_symlink())

    def test_invalid_input_fails_before_installation(self) -> None:
        self.install("UnsupportedOS", success=False)
        self.assertEqual(list(self.home.iterdir()), [])
        self.environment["XDG_CONFIG_HOME"] = "relative-config"
        self.install(success=False)
        self.assertEqual(list(self.home.iterdir()), [])
        del self.environment["XDG_CONFIG_HOME"]
        (self.repo / "antigen.zsh").unlink()
        self.install(success=False)
        self.assertEqual(list(self.home.iterdir()), [])

    @unittest.skipUnless(ZSH, "Zsh is required for shell startup checks")
    def test_minimal_shell_starts(self) -> None:
        script = '''
source "$DOTFILES_TEST_RC"
[[ "$path[(Ie)$HOME/.bun/bin]" -gt 0 ]] || exit 10
[[ "$path[(Ie)$HOME/.opencode/bin]" -gt 0 ]] || exit 11
[[ "$K9S_CONFIG_DIR" == "$HOME/.config/k9s" ]] || exit 12
[[ -n "$EDITOR" && "$VISUAL" == "$EDITOR" ]] || exit 13
[[ -z "$HF_HOME$CUDA_VISIBLE_DEVICES$LD_LIBRARY_PATH" ]] || exit 14
[[ -z "$GPG_TTY" ]] || exit 15
aws_profile 'profile with spaces'
[[ "$AWS_PROFILE" == 'profile with spaces' ]] || exit 16
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
            [ZSH, "-df", "-c", 'source "$DOTFILES_TEST_RC"; print -r -- "$EDITOR"'],
            env=dict(self.environment, DOTFILES_TEST_RC=str(self.repo / ".zshrc")),
            text=True, capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(result.stdout, "custom-editor\n")


if __name__ == "__main__":
    unittest.main(verbosity=2)
