"""Tests for .claude/mcp/bootstrap.sh and .claude/mcp/truststore/sitecustomize.py.

The bootstrap runs under pytest's tmp_path: a made-up HOME with its own
.claude.json, and stub `claude` and `uv` commands first on PATH that only log
their arguments. No test touches the real ~/.claude.json, starts an MCP server
or opens a connection.

Run: uv run --with pytest pytest tests/test_mcp_bootstrap.py -v
"""

import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / ".claude/mcp/bootstrap.sh"
TRUSTSTORE_DIR = REPO / ".claude/mcp/truststore"
WORK_MAC_DIR = "Library/CloudStorage/OneDrive-HRI-JP"
TLS_SERVERS = ["google-workspace", "markitdown-mcp"]
MARKER = "marker-value-that-must-never-be-printed"

# Logs one line per call, the arguments joined by the unit separator.
STUB = r"""#!/bin/bash
here="$(cd "$(dirname "$0")" && pwd)"
{
  printf '%s\x1f' "$(basename "$0")" "$@"
  printf '\n'
} >>"${here}/calls.log"
"""


class Fx:
    """A made-up HOME that the bootstrap registers MCP servers in."""

    def __init__(self, tmp: Path) -> None:
        self.home = tmp / "home"
        self.stubs = tmp / "stubs"
        self.config = self.home / ".claude.json"
        self.pythonpath = self.home / ".claude/mcp/truststore"
        self.env = {
            "HOME": str(self.home),
            "PATH": f"{self.stubs}:/usr/bin:/bin",
        }
        self.pythonpath.mkdir(parents=True)
        self.stubs.mkdir()
        (self.pythonpath / "sitecustomize.py").write_text("")
        for name in ("claude", "uv"):
            (self.stubs / name).write_text(STUB)
            (self.stubs / name).chmod(0o755)
        jq = shutil.which("jq")
        if jq is None:
            pytest.skip("jq is not installed")
        else:
            (self.stubs / "jq").symlink_to(jq)
        self.register({})

    def register(self, servers: dict) -> None:
        self.config.write_text(json.dumps({"mcpServers": servers}))

    def run(self) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["bash", str(SCRIPT)],
            check=False,
            env=self.env,
            capture_output=True,
            text=True,
            timeout=60,
        )

    def adds(self) -> dict[str, list[str]]:
        """The `claude mcp add` calls so far: server name -> arguments after it."""
        log = self.stubs / "calls.log"
        if not log.exists():
            return {}
        calls = [line.split("\x1f")[:-1] for line in log.read_text().splitlines()]
        prefix = ["claude", "mcp", "add", "-s", "user", "--transport", "stdio"]
        return {c[7]: c[8:] for c in calls if c[:7] == prefix}

    def pinned(self) -> dict:
        """The entries the bootstrap registers on a host that has none."""
        self.register({})
        self.run()
        entries = {}
        for name, rest in self.adds().items():
            sep = rest.index("--")
            flags, command = rest[:sep], rest[sep + 1 :]
            env = dict(flags[i + 1].split("=", 1) for i in range(0, len(flags), 2))
            entries[name] = {
                "type": "stdio",
                "command": command[0],
                "args": command[1:],
                "env": env,
            }
        (self.stubs / "calls.log").unlink()
        return entries


@pytest.fixture
def fx(tmp_path: Path) -> Fx:
    return Fx(tmp_path)


def warnings(result: subprocess.CompletedProcess) -> list[str]:
    output = result.stdout + result.stderr
    return [line for line in output.splitlines() if line.startswith("!!")]


@pytest.mark.parametrize("name", TLS_SERVERS)
def test_missing_server_is_added_with_truststore(fx: Fx, name: str) -> None:
    result = fx.run()

    assert result.returncode == 0, result.stderr
    rest = fx.adds()[name]
    # The env flag follows the name and `--` ends it: `-e` takes many values.
    assert rest[:3] == ["-e", f"PYTHONPATH={fx.home}/.claude/mcp/truststore", "--"]
    command = rest[3:]
    assert command[0] == "uvx"
    assert re.fullmatch(
        r"truststore==\d+(\.\d+)+", command[command.index("--with") + 1]
    )


def test_registered_pin_is_left_alone(fx: Fx) -> None:
    fx.register(fx.pinned())

    result = fx.run()

    assert fx.adds() == {}
    assert warnings(result) == []


def test_host_only_env_key_is_left_alone(fx: Fx) -> None:
    servers = fx.pinned()
    servers["google-workspace"]["env"]["HOST_ONLY_KEY"] = MARKER
    fx.register(servers)

    result = fx.run()

    assert fx.adds() == {}
    assert warnings(result) == []


@pytest.mark.parametrize("name", TLS_SERVERS)
def test_missing_pinned_env_key_warns(fx: Fx, name: str) -> None:
    servers = fx.pinned()
    del servers[name]["env"]
    fx.register(servers)

    result = fx.run()

    assert fx.adds() == {}
    want = f"PYTHONPATH={fx.home}/.claude/mcp/truststore"
    assert warnings(result) == [
        f"!! {name}: env PYTHONPATH is missing or differs from the pin; want {want}"
    ]


def test_different_pinned_env_value_warns_without_printing_it(fx: Fx) -> None:
    servers = fx.pinned()
    servers["google-workspace"]["env"] = {
        "PYTHONPATH": f"/elsewhere/{MARKER}",
        "HOST_ONLY_KEY": MARKER,
    }
    fx.register(servers)

    result = fx.run()

    assert fx.adds() == {}
    want = f"PYTHONPATH={fx.home}/.claude/mcp/truststore"
    assert warnings(result) == [
        f"!! google-workspace: env PYTHONPATH is missing or differs from the pin; want {want}"
    ]
    assert MARKER not in result.stdout + result.stderr


def test_different_args_warn(fx: Fx) -> None:
    servers = fx.pinned()
    servers["google-workspace"]["args"][:0] = ["--python", "3.12"]
    fx.register(servers)

    result = fx.run()

    assert fx.adds() == {}
    assert len(warnings(result)) == 1
    assert (
        "google-workspace: registered args differ from the pin" in warnings(result)[0]
    )


def test_missing_sitecustomize_warns(fx: Fx) -> None:
    (fx.pythonpath / "sitecustomize.py").unlink()
    fx.register(fx.pinned())

    result = fx.run()

    assert len(warnings(result)) == 1
    assert "sitecustomize.py" in warnings(result)[0]


@pytest.mark.skipif(sys.platform != "darwin", reason="Apple Mail is macOS only")
def test_apple_mail_servers_get_no_env(fx: Fx) -> None:
    (fx.home / WORK_MAC_DIR).mkdir(parents=True)

    fx.run()

    adds = fx.adds()
    assert adds["apple-mail-patrickfreyer"][:2] == ["--", "uvx"]
    assert "truststore" not in " ".join(adds["apple-mail-patrickfreyer"])
    assert adds["apple-mail-imdinu"] == ["--", "apple-mail-mcp"]


def start_python(tmp_path: Path, truststore_source: str) -> subprocess.CompletedProcess:
    """Start Python with sitecustomize.py and a made-up truststore on its path."""
    fake = tmp_path / "fake"
    fake.mkdir()
    (fake / "truststore.py").write_text(truststore_source)
    env = {
        "PATH": os.environ["PATH"],
        "PYTHONPATH": f"{TRUSTSTORE_DIR}:{fake}",
        "PYTHONDONTWRITEBYTECODE": "1",
        "INJECT_LOG": str(tmp_path / "inject.log"),
    }
    return subprocess.run(
        [sys.executable, "-c", "print('started')"],
        check=False,
        env=env,
        capture_output=True,
        text=True,
        timeout=60,
    )


def test_sitecustomize_injects_truststore_once(tmp_path: Path) -> None:
    result = start_python(
        tmp_path,
        "import os\n\n"
        "def inject_into_ssl():\n"
        "    with open(os.environ['INJECT_LOG'], 'a') as log:\n"
        "        log.write('injected\\n')\n",
    )

    assert (result.returncode, result.stdout, result.stderr) == (0, "started\n", "")
    assert (tmp_path / "inject.log").read_text() == "injected\n"


def test_sitecustomize_is_silent_without_truststore(tmp_path: Path) -> None:
    result = start_python(
        tmp_path, "raise ImportError('truststore is not installed')\n"
    )

    assert (result.returncode, result.stdout, result.stderr) == (0, "started\n", "")


def test_truststore_dir_holds_only_sitecustomize() -> None:
    # Everything in this directory is importable by the servers.
    names = {p.name for p in TRUSTSTORE_DIR.iterdir()} - {"__pycache__"}

    assert names == {"sitecustomize.py"}
