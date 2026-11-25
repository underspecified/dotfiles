"""Tests for installers/all/install_tsshd.sh.

Everything lives under pytest's tmp_path: HOME, and stub `uname` and `curl`
commands placed first on PATH. No test touches the network or a real ~/.local.

Run: uv run --with pytest pytest tests/test_install_tsshd.py -v
"""

import io
import re
import subprocess
import tarfile
from collections.abc import Callable
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "installers/all/install_tsshd.sh"
SYSTEM_PATH = "/usr/bin:/bin:/usr/sbin:/sbin"

UNAME_STUB = """#!/bin/bash
case "${1:-}" in
  -m) echo "${FAKE_ARCH:-x86_64}" ;;
  *) echo "${FAKE_OS:-Linux}" ;;
esac
"""

CURL_STUB = """#!/bin/bash
# Test stub: logs the call, then fails, or (CURL_MODE=junk) writes junk to -o.
here="$(cd "$(dirname "$0")" && pwd)"
printf '%s\\n' "$*" >>"${here}/curl.log"
[ "${CURL_MODE:-fail}" = junk ] || exit 22
while [ $# -gt 0 ]; do
  if [ "$1" = -o ]; then
    printf 'not a tarball' >"$2"
    exit 0
  fi
  shift
done
exit 2
"""

type Run = Callable[..., subprocess.CompletedProcess[str]]


def pinned_version() -> str:
    match = re.search(r'^VERSION="([^"]+)"', SCRIPT.read_text(), re.MULTILINE)
    if match is None:
        raise RuntimeError(f"no VERSION= line in {SCRIPT}")
    return match.group(1)


VERSION = pinned_version()


@pytest.fixture
def box(tmp_path: Path) -> tuple[Path, Path, Run]:
    """A fake HOME, the stub dir, and a runner for the installer."""
    stubs = tmp_path / "stubs"
    stubs.mkdir()
    for name, body in (("uname", UNAME_STUB), ("curl", CURL_STUB)):
        (stubs / name).write_text(body)
        (stubs / name).chmod(0o755)
    home = tmp_path / "home"
    home.mkdir()

    def run(**extra: str) -> subprocess.CompletedProcess[str]:
        env = {"HOME": str(home), "PATH": f"{stubs}:{SYSTEM_PATH}", **extra}
        return subprocess.run(
            ["bash", str(SCRIPT)],
            env=env,
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )

    return home, stubs, run


def fake_tsshd(home: Path, version: str) -> Path:
    binary = home / ".local/bin/tsshd"
    binary.parent.mkdir(parents=True)
    binary.write_text(f'#!/bin/bash\necho "trzsz sshd {version}"\n')
    binary.chmod(0o755)
    return binary


def test_pinned_version_downloads_nothing(box: tuple[Path, Path, Run]) -> None:
    home, stubs, run = box
    fake_tsshd(home, VERSION)
    result = run()
    assert result.returncode == 0, result.stderr
    assert "unchanged" in result.stdout
    assert not (stubs / "curl.log").exists()


def test_wrong_sha_in_cache_installs_nothing(box: tuple[Path, Path, Run]) -> None:
    home, _stubs, run = box
    name = f"tsshd_{VERSION}_linux_x86_64"
    tgz = home / f".cache/tsshd/{name}.tar.gz"
    tgz.parent.mkdir(parents=True)
    payload = b"#!/bin/bash\necho not-tsshd\n"
    with tarfile.open(tgz, "w:gz") as tar:
        info = tarfile.TarInfo(f"{name}/tsshd")
        info.size, info.mode = len(payload), 0o755
        tar.addfile(info, io.BytesIO(payload))
    result = run()
    assert result.returncode != 0
    assert "sha256 mismatch" in result.stderr
    assert not (home / ".local/bin/tsshd").exists()


def test_wrong_sha_on_download_is_not_cached(box: tuple[Path, Path, Run]) -> None:
    home, stubs, run = box
    result = run(CURL_MODE="junk")
    assert result.returncode != 0
    assert "sha256 mismatch" in result.stderr
    assert (stubs / "curl.log").exists()
    assert not list((home / ".cache/tsshd").iterdir())
    assert not (home / ".local/bin/tsshd").exists()


def test_failed_download_keeps_the_old_binary(box: tuple[Path, Path, Run]) -> None:
    home, _stubs, run = box
    old = fake_tsshd(home, "0.0.1")
    result = run()
    assert result.returncode != 0
    assert "download failed" in result.stderr
    assert "0.0.1" in old.read_text()


def test_refuses_macos(box: tuple[Path, Path, Run]) -> None:
    home, stubs, run = box
    result = run(FAKE_OS="Darwin")
    assert result.returncode != 0
    assert "Linux only" in result.stderr
    assert not (stubs / "curl.log").exists()
    assert not (home / ".local/bin/tsshd").exists()
