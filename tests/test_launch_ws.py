"""Tests for macos.lnk/.local/bin/launch_ws.

The real script runs with stub `kitten` and `sleep` commands first on a PATH
that holds nothing else but the system dirs: no window opens, nothing waits, and
no real kitten, mosh or tssh can be reached. The kitten stub logs its argv.

Run: uv run --with pytest pytest tests/test_launch_ws.py -v
"""

import re
import subprocess
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "macos.lnk/.local/bin/launch_ws"
TSSH_CONF = REPO / "macos.lnk/.ssh/config.d/tssh.conf"
SYSTEM_PATH = "/usr/bin:/bin:/usr/sbin:/sbin"
SEP = "\x1f"

# One log line per call, each argument followed by the unit separator.
KITTEN_STUB = """#!/bin/bash
{
  printf '%s\\x1f' "$@"
  echo
} >>"${KITTEN_LOG}"
"""


def tssh_conf_hosts() -> set[str]:
    """Hosts that tssh.conf puts in tsshd-over-TCP mode."""
    match = re.search(r"^Host (.+)$", TSSH_CONF.read_text(), re.MULTILINE)
    if match is None:
        raise ValueError(f"no Host line in {TSSH_CONF}")
    return set(match.group(1).split())


@pytest.fixture(scope="module")
def panes(tmp_path_factory: pytest.TempPathFactory) -> dict[str, list[list[str]]]:
    """Per host, the command of each btop/nvitop pane launch_ws asks kitty for."""
    tmp = tmp_path_factory.mktemp("launch_ws")
    bin_dir = tmp / "bin"
    bin_dir.mkdir()
    (bin_dir / "kitten").write_text(KITTEN_STUB)
    (bin_dir / "sleep").write_text("#!/bin/bash\n")
    for stub in bin_dir.iterdir():
        stub.chmod(0o755)
    log = tmp / "kitten.log"
    env = {"PATH": f"{bin_dir}:{SYSTEM_PATH}", "KITTEN_LOG": str(log)}
    subprocess.run(["/bin/bash", str(SCRIPT)], env=env, check=True, timeout=30)

    by_host: dict[str, list[list[str]]] = {}
    for line in log.read_text().splitlines():
        # @ launch --match=title:<host> <command...>
        argv = line.split(SEP)[:-1]
        if "sh" not in argv:  # the tab itself, a dispatch pane, layout, close
            continue
        host = argv[2].removeprefix("--match=title:")
        by_host.setdefault(host, []).append(argv[3:])
    return by_host


def test_hosts_in_tssh_conf_get_tssh_with_pty_and_separator(
    panes: dict[str, list[list[str]]],
) -> None:
    # -t: a tssh command run gets no pty without it, and tmux needs one.
    # --: otherwise tssh reads sh's -c as its own cipher option.
    hosts = tssh_conf_hosts() & panes.keys()
    assert hosts
    for host in hosts:
        for cmd in panes[host]:
            assert cmd[:6] == ["tssh", "-t", host, "--", "sh", "-c"]


def test_tssh_only_for_hosts_in_tssh_conf(panes: dict[str, list[list[str]]]) -> None:
    # Outside tssh.conf tssh acts like ssh: the remote shell re-parses the
    # command and `sh -c '...'` loses its quoting.
    tssh_hosts = {h for h, cmds in panes.items() if any(c[0] == "tssh" for c in cmds)}
    assert tssh_hosts <= tssh_conf_hosts()
