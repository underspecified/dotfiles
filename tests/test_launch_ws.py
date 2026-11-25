"""Tests for macos.lnk/.local/bin/launch_ws.

The real script runs with stub `kitten` and `sleep` commands first on a PATH
that holds nothing else but the system dirs: no window opens, nothing waits, and
no real kitten, mosh or tssh can be reached. The kitten stub logs its argv.

Run: uv run --with pytest pytest tests/test_launch_ws.py -v
"""

import re
import subprocess
from collections.abc import Mapping
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "macos.lnk/.local/bin/launch_ws"
TSSH_CONF = REPO / "macos.lnk/.ssh/config.d/tssh.conf"
SYSTEM_PATH = "/usr/bin:/bin:/usr/sbin:/sbin"
SEP = "\x1f"

# One log line per call, each argument followed by the unit separator.
# `kitten @ launch` prints the new window's id, so each tab launch prints one:
# 1000 + that call's line number in the log. With KITTEN_NO_ID it fails instead.
KITTEN_STUB = """#!/bin/bash
{
  printf '%s\\x1f' "$@"
  echo
} >>"${KITTEN_LOG}"
case " $* " in
*" --type=tab "*)
  [[ -n "${KITTEN_NO_ID:-}" ]] && exit 1
  echo "$((1000 + $(wc -l <"${KITTEN_LOG}")))"
  ;;
esac
"""


def tssh_conf_hosts() -> set[str]:
    """Hosts that tssh.conf puts in tsshd mode: its `#!! UdpMode yes` blocks."""
    hosts: set[str] = set()
    block: list[str] = []
    for line in TSSH_CONF.read_text().splitlines():
        if line.startswith("Host "):
            block = line.split()[1:]
        elif line.strip() == "#!! UdpMode yes":
            hosts.update(block)
    if not hosts:
        raise ValueError(f"no Host block with UdpMode yes in {TSSH_CONF}")
    return hosts


def run_launch_ws(
    tmp: Path, extra_env: Mapping[str, str] | None = None
) -> list[list[str]]:
    """Run the real script against the stubs; return the argv of each kitten call."""
    bin_dir = tmp / "bin"
    bin_dir.mkdir()
    (bin_dir / "kitten").write_text(KITTEN_STUB)
    (bin_dir / "sleep").write_text("#!/bin/bash\n")
    for stub in bin_dir.iterdir():
        stub.chmod(0o755)
    log = tmp / "kitten.log"
    env = {
        "PATH": f"{bin_dir}:{SYSTEM_PATH}",
        "KITTEN_LOG": str(log),
        **(extra_env or {}),
    }
    subprocess.run(["/bin/bash", str(SCRIPT)], env=env, check=True, timeout=30)
    return [line.split(SEP)[:-1] for line in log.read_text().splitlines()]


@pytest.fixture(scope="module")
def calls(tmp_path_factory: pytest.TempPathFactory) -> list[list[str]]:
    """Every kitten call of one full launch_ws run, in order."""
    return run_launch_ws(tmp_path_factory.mktemp("launch_ws"))


@pytest.fixture(scope="module")
def panes(calls: list[list[str]]) -> dict[str, list[list[str]]]:
    """Per host, the command of each btop/nvitop pane launch_ws asks kitty for."""
    by_host: dict[str, list[list[str]]] = {}
    for argv in calls:
        # @ launch --match=title:<host> <command...>
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


def test_fallback_starts_the_session_the_attach_looked_for(
    panes: dict[str, list[list[str]]],
) -> None:
    # `tmux new-session -t <group> <command>` is not valid tmux: -t refuses a
    # command, so on a host with no session yet the pane ended up as a shell.
    for cmds in panes.values():
        for cmd in cmds:
            match = re.search(
                r"tmux a -t (\S+) \|\| tmux new-session (\S+) (\S+) (\S+);", cmd[-1]
            )
            assert match is not None, cmd[-1]
            name, flag, session, program = match.groups()
            assert (flag, session, program) == ("-s", name, name)


def test_dispatch_panes_turn_on_tssh_and_mosh(calls: list[list[str]]) -> None:
    # kitty's new windows don't inherit the calling shell's env, so each
    # dispatch pane is handed both gates. dispatch tries tssh before mosh.
    dispatch_panes = [argv for argv in calls if "dispatch" in argv]
    assert dispatch_panes
    for argv in dispatch_panes:
        before = argv[: argv.index("dispatch")]
        env = {before[i + 1] for i, arg in enumerate(before) if arg == "--env"}
        assert {"DISPATCH_REMOTE_MOSH=1", "DISPATCH_REMOTE_TSSH=1"} <= env
