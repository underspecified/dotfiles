"""Tests for macos.lnk/.local/bin/migrate_seat.

Everything lives under pytest's tmp_path: HOME, the "cloud" folder, the local
folder, and stub `dispatch` and `lsof` commands placed first on PATH. No test
touches a real seat, ~/.claude, the dispatch bus or a real dotfiles tree.

Run: uv run --with pytest pytest tests/test_migrate_seat.py -v
"""

import os
import re
import stat
import subprocess
import sys
from pathlib import Path

import pytest

pytestmark = pytest.mark.skipif(sys.platform != "darwin", reason="macOS only")

SCRIPT = Path(__file__).resolve().parents[1] / "macos.lnk/.local/bin/migrate_seat"
SYSTEM_PATH = "/usr/bin:/bin:/usr/sbin:/sbin"
TOOLS_REMOTE = "https://example.invalid/acme/tools.git"

MANIFEST = """\
# infra for the made-up seat "acme"
CLAUDE.md
.claude
nikki
links
pin

sub/CLAUDE.md
sub/nikki
tools
widgets
"""

DISPATCH_STUB = r"""#!/bin/bash
# Test stub: canned answers from the files next to it; logs every call.
here="$(cd "$(dirname "$0")" && pwd)"
printf '%s\n' "$*" >>"${here}/dispatch.log"
dir=""
if [ "${1:-}" = "-C" ]; then
  dir="$2"
  shift 2
fi
case "${1:-}" in
  list) cat "${here}/list.txt" ;;
  new)
    if grep -Fxq "${dir}" "${here}/unread.txt" 2>/dev/null; then
      printf '[someone] hello\nbody\n'
    else
      echo "(empty)"
    fi
    ;;
  destroy) echo "destroyed ${dir}" ;;
  *)
    echo "stub: unexpected verb ${1:-}" >&2
    exit 2
    ;;
esac
"""

# Real lsof often exits 1 while still printing results, so the stub always does.
LSOF_STUB = r"""#!/bin/bash
here="$(cd "$(dirname "$0")" && pwd)"
cat "${here}/lsof.txt" 2>/dev/null
exit 1
"""

RSYNC_FAILS = "#!/bin/bash\necho 'rsync: stub partial transfer' >&2\nexit 23\n"


def encode(path: Path | str) -> str:
    """Claude Code's project key for a physical path."""
    return re.sub(r"[^A-Za-z0-9-]", "-", str(path))


def snapshot(root: Path, skip: tuple[str, ...] = (), mtimes: bool = True) -> dict:
    """Every entry under root: type, size, link text and (optionally) mtime."""
    out = {}
    for dirpath, dirnames, filenames in os.walk(root):
        if dirpath == str(root):
            dirnames[:] = [d for d in dirnames if d not in skip]
        for name in dirnames + filenames:
            path = os.path.join(dirpath, name)
            st = os.lstat(path)
            link = os.readlink(path) if stat.S_ISLNK(st.st_mode) else None
            size = st.st_size if stat.S_ISREG(st.st_mode) else None
            entry = (stat.S_IFMT(st.st_mode), size, link)
            out[os.path.relpath(path, root)] = (
                (*entry, st.st_mtime_ns) if mtimes else entry
            )
    return out


class Fx:
    """A made-up cloud seat ("acme") and the places migrate_seat may write."""

    def __init__(self, tmp: Path, history: str) -> None:
        self.tmp = tmp
        self.home = tmp / "home"
        self.stubs = tmp / "stubs"
        self.old = tmp / "cloud" / "My Drive" / "acme"
        self.new = tmp / "local" / "acme"
        self.manifest = tmp / "acme.infra"
        self.projects = self.home / ".claude" / "projects"
        self.cache = self.home / ".cache" / "dispatch"
        self.env = {
            "HOME": str(self.home),
            "PATH": f"{self.stubs}:{SYSTEM_PATH}",
            "GIT_CONFIG_GLOBAL": str(self.home / ".gitconfig"),
            "GIT_CONFIG_NOSYSTEM": "1",
            "TMPDIR": str(tmp / "t"),
        }
        for d in (self.home, self.stubs, self.projects, self.cache, tmp / "t"):
            d.mkdir(parents=True)
        (self.home / ".gitconfig").write_text(
            "[user]\n\tname = Test\n\temail = test@example.invalid\n"
            "[init]\n\tdefaultBranch = main\n[commit]\n\tgpgsign = false\n"
        )
        self._stub("dispatch", DISPATCH_STUB)
        self._stub("lsof", LSOF_STUB)
        self._build_cloud(history)
        self.manifest.write_text(MANIFEST)
        self.new.parent.mkdir()
        self.new.symlink_to(self.old)
        self.set_seats(
            self.old,
            self.old / "widgets",
            self.old / "gadgets",
            tmp / "elsewhere" / "other",
        )
        self._build_claude_state()

    def _stub(self, name: str, text: str) -> None:
        path = self.stubs / name
        path.write_text(text)
        path.chmod(0o755)

    def git(self, cwd: Path, *args: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["git", "-C", str(cwd), *args],
            check=False,
            env=self.env,
            capture_output=True,
            text=True,
            timeout=60,
        )

    def _build_cloud(self, history: str) -> None:
        old = self.old
        (self.tmp / "x").write_text("outside target\n")
        for rel, text in {
            "CLAUDE.md": "# acme\n",
            ".claude/settings.json": "{}\n",
            ".gitignore": ".DS_Store\n",
            "nikki/2026-01-01.md": "day one\n",
            "loose.txt": "a loose document\n",
            "docs/report.txt": "a report\n",
            "sub/CLAUDE.md": "# sub\n",
            "sub/nikki/day.md": "sub day\n",
            "sub/big/blob.bin": "x" * 4096,
            "tools/tool.sh": "#!/bin/sh\n",
            "widgets/CLAUDE.md": "# widgets, a nested seat\n",
            "gadgets/CLAUDE.md": "# gadgets, a sibling seat that is not listed\n",
        }.items():
            path = old / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
        (old / "links").mkdir()
        (old / "nikki" / "latest").symlink_to("2026-01-01.md")
        (old / "links" / "deep").symlink_to("../../../../x")
        (old / "links" / "abs_doc").symlink_to(old / "docs" / "report.txt")
        (old / "links" / "abs_infra").symlink_to(old / "CLAUDE.md")
        (old / "pin").symlink_to("../../../x")

        tools = old / "tools"
        self.git(tools, "init", "-q")
        self.git(tools, "add", "-A")
        self.git(tools, "commit", "-q", "-m", "tools")
        self.git(tools, "remote", "add", "origin", TOOLS_REMOTE)

        # The seat's own repo. nikki/ stays untracked on purpose.
        self.git(old, "init", "-q")
        tracked = [
            ".gitignore",
            "CLAUDE.md",
            ".claude",
            "links",
            "pin",
            "sub/CLAUDE.md",
        ]
        tracked += ["sub/nikki", "widgets"]
        self.git(old, "add", *tracked)
        self.git(old, "commit", "-q", "-m", "infra")
        if history == "mixed":
            self.git(old, "add", "docs/report.txt")
            self.git(old, "commit", "-q", "-m", "a document slipped in")
            self.git(old, "rm", "-q", "--cached", "docs/report.txt")
            self.git(old, "commit", "-q", "-m", "untrack the document")
        self.old_head = self.git(old, "rev-parse", "HEAD").stdout.strip()
        assert self.old_head, "fixture repo has no commit"

    def _build_claude_state(self) -> None:
        other = self.tmp / "elsewhere" / "other"
        for path, name in (
            (self.old, "a.jsonl"),
            (self.old / "widgets", "b.jsonl"),
            (self.old / "gadgets", "c.jsonl"),
            (other, "d.jsonl"),
        ):
            d = self.projects / encode(path)
            d.mkdir()
            (d / name).write_text(f"transcript {name}\n")
        (self.cache / f"{encode(self.old)}.waiter").write_text("on\n")
        (self.cache / f"{encode(self.old)}.monitor").write_text("30s\n")
        (self.cache / f"{encode(self.old / 'widgets')}.waiter-off").write_text("off\n")
        (self.cache / f"{encode(self.old / 'gadgets')}.waiter").write_text("on\n")

    def set_seats(self, *cwds: Path) -> None:
        rows = [
            "STATE         WID     LABEL                     HOST          CWD",
            "------------  ------  ------------------------  ------------  ---",
        ]
        rows += [
            f"{'detached':<12}  {'-':<6}  {Path(c).name:<24}  {'local':<12}  {c}"
            for c in cwds
        ]
        (self.stubs / "list.txt").write_text("\n".join(rows) + "\n")

    def set_unread(self, *seats: Path) -> None:
        (self.stubs / "unread.txt").write_text("".join(f"{s}\n" for s in seats))

    def set_lsof(self, *procs: tuple[int, str, Path]) -> None:
        text = "".join(f"p{pid}\nc{cmd}\nfcwd\nn{cwd}\n" for pid, cmd, cwd in procs)
        (self.stubs / "lsof.txt").write_text(text)

    def calls(self) -> list[str]:
        log = self.stubs / "dispatch.log"
        return log.read_text().splitlines() if log.exists() else []

    def destroyed(self) -> set[str]:
        return {c for c in self.calls() if c.endswith(" destroy")}

    def run(
        self, *args: object, env: dict | None = None
    ) -> subprocess.CompletedProcess:
        argv = [str(a) for a in args]
        for a in argv:
            if a.startswith("/"):
                assert Path(a).is_relative_to(self.tmp), f"outside the temp dir: {a}"
        return subprocess.run(
            [sys.executable, str(SCRIPT), *argv],
            check=False,
            cwd=self.tmp,
            env={**self.env, **(env or {})},
            capture_output=True,
            text=True,
            timeout=120,
        )

    def migrate(self, *extra: object, env: dict | None = None):
        return self.run(
            "acme",
            "--old", self.old,
            "--new", self.new,
            "--infra", self.manifest,
            "--lsof-wait", "0",
            *extra,
            env=env,
        )  # fmt: skip

    def applied(self, *extra: object):
        r = self.migrate("--apply", *extra)
        assert r.returncode == 0, r.stderr + r.stdout
        return r

    def rollback(self, *extra: object):
        return self.run("--rollback", "acme", "--lsof-wait", "0", *extra)

    def whole_tree(self) -> dict:
        return snapshot(self.tmp, skip=("stubs", "t"))


@pytest.fixture
def make_fx(tmp_path: Path):
    def make(history: str = "mixed") -> Fx:
        return Fx(tmp_path.resolve(), history)

    return make


@pytest.fixture
def fx(make_fx) -> Fx:
    return make_fx()


# ── 1. CLI, manifest, dry run ────────────────────────────────────────────────


def test_dry_run_changes_nothing(fx):
    before = fx.whole_tree()
    r = fx.migrate()
    assert r.returncode == 0, r.stderr
    assert fx.whole_tree() == before
    assert fx.destroyed() == set()


def test_dry_run_prints_each_action_kind(fx):
    out = fx.migrate().stdout
    for kind in ("copy", "link", "rewrite", "rename", "git", "dispatch"):
        assert re.search(rf"^{kind}\s", out, re.MULTILINE), (
            f"no '{kind}' line in:\n{out}"
        )


@pytest.mark.parametrize(
    ("line", "why"),
    [
        ("/etc/hosts", "absolute"),
        ("../x", ".."),
        ("nope.md", "not found"),
        ("nikki/2026-01-01.md", "inside another entry"),
    ],
)
def test_manifest_rejects_bad_entries(fx, line, why):
    fx.manifest.write_text(MANIFEST + line + "\n")
    before = fx.whole_tree()
    r = fx.migrate("--apply")
    assert r.returncode != 0
    assert why in r.stderr
    assert fx.whole_tree() == before
    assert fx.destroyed() == set()


def test_refuses_an_unlisted_git_repo_inside_infra(fx):
    inner = fx.old / ".claude" / "inner"
    inner.mkdir()
    fx.git(inner, "init", "-q")
    r = fx.migrate("--apply")
    assert r.returncode != 0
    assert ".claude/inner" in r.stderr
    assert fx.destroyed() == set()


# ── 2. Preflight ─────────────────────────────────────────────────────────────


def test_refuses_when_caller_is_a_seat_under_old(fx):
    r = fx.migrate("--apply", env={"DISPATCH_SEAT": str(fx.old / "widgets")})
    assert r.returncode != 0
    assert "seat running this script" in r.stderr
    assert fx.destroyed() == set()


def test_refuses_on_unread_mail_before_any_destroy(fx):
    fx.set_unread(fx.old / "widgets")
    r = fx.migrate("--apply")
    assert r.returncode != 0
    assert "unread mail" in r.stderr
    assert fx.destroyed() == set()


def test_destroys_only_seats_whose_folder_stays_real(fx):
    fx.applied()
    assert fx.destroyed() == {
        f"-C {fx.old} destroy",
        f"-C {fx.old / 'widgets'} destroy",
    }


def test_refuses_when_a_process_cwd_is_under_old(fx):
    fx.set_lsof((4242, "fakeproc", fx.old / "nikki"))
    r = fx.migrate("--apply")
    assert r.returncode != 0
    assert "4242 fakeproc" in r.stderr
    assert fx.new.is_symlink()


def test_refuses_when_new_is_a_link_to_somewhere_else(fx):
    elsewhere = fx.tmp / "elsewhere"
    elsewhere.mkdir()
    fx.new.unlink()
    fx.new.symlink_to(elsewhere)
    r = fx.migrate("--apply")
    assert r.returncode != 0
    assert "does not point at --old" in r.stderr
    assert fx.destroyed() == set()


# ── 3. Stage ─────────────────────────────────────────────────────────────────


def test_infra_copied_and_documents_linked(fx):
    fx.applied()
    new, old = fx.new, fx.old
    assert not new.is_symlink()
    assert (new / "CLAUDE.md").read_text() == "# acme\n"
    assert (new / ".claude" / "settings.json").read_text() == "{}\n"
    assert (new / "nikki" / "2026-01-01.md").read_text() == "day one\n"
    for rel in ("loose.txt", "docs", "gadgets", "sub/big"):
        assert os.readlink(new / rel) == str(old / rel), rel
    assert (new / "sub").is_dir() and not (new / "sub").is_symlink()
    assert not (new / "sub" / "CLAUDE.md").is_symlink()
    assert (new / "sub" / "nikki" / "day.md").read_text() == "sub day\n"
    assert (new / "sub" / "big" / "blob.bin").stat().st_size == 4096


def test_copy_error_stops_before_swap(fx):
    fx._stub("rsync", RSYNC_FAILS)
    before = snapshot(fx.old)
    r = fx.migrate("--apply")
    assert r.returncode != 0
    assert "left:" in r.stderr and "6 Swap" in r.stderr
    assert snapshot(fx.old) == before
    assert fx.new.is_symlink()


def test_materialize_policy_reaches_children():
    code = (
        "import importlib.machinery, importlib.util, subprocess, sys\n"
        "sys.dont_write_bytecode = True\n"
        "loader = importlib.machinery.SourceFileLoader('migrate_seat', sys.argv[1])\n"
        "spec = importlib.util.spec_from_loader('migrate_seat', loader)\n"
        "mod = importlib.util.module_from_spec(spec)\n"
        "loader.exec_module(mod)\n"
        "mod.materialize_on()\n"
        "child = \"import ctypes; print(ctypes.CDLL('libc.dylib').getiopolicy_np(3, 0))\"\n"
        "subprocess.run([sys.executable, '-c', child], check=True)\n"
    )
    r = subprocess.run(
        [sys.executable, "-c", code, str(SCRIPT)],
        check=False,
        capture_output=True,
        text=True,
        timeout=60,
    )
    assert r.stdout.strip() == "2", r.stderr


# ── 4. Links ─────────────────────────────────────────────────────────────────


def test_links_reach_same_targets(fx):
    fx.applied()
    new, old = fx.new, fx.old
    # Inside the root: left alone, and now reaches the copy.
    assert os.readlink(new / "nikki" / "latest") == "2026-01-01.md"
    # Climbs above the root: rewritten to where it pointed from the cloud folder.
    assert os.readlink(new / "links" / "deep") == str(fx.tmp / "x")
    assert os.readlink(new / "pin") == str(fx.tmp / "x")
    # Absolute into a document folder: still right, so untouched.
    assert os.readlink(new / "links" / "abs_doc") == str(old / "docs" / "report.txt")
    # Absolute into copied infra: would dangle after the rename, so repointed.
    assert os.readlink(new / "links" / "abs_infra") == str(new / "CLAUDE.md")
    for rel in (
        "nikki/latest",
        "links/deep",
        "pin",
        "links/abs_doc",
        "links/abs_infra",
    ):
        assert (new / rel).exists(), f"{rel} dangles"


def test_rewrite_logs_swaps_prefix(fx):
    logs = fx.tmp / "logs" / "2026-01-01"
    logs.mkdir(parents=True)
    (logs / "acme.md").symlink_to(fx.old / "nikki" / "2026-01-01.md")
    (logs / "other.md").symlink_to(fx.tmp / "x")
    fx.applied("--rewrite-logs", fx.tmp / "logs")
    assert os.readlink(logs / "acme.md") == str(fx.new / "nikki" / "2026-01-01.md")
    assert os.readlink(logs / "other.md") == str(fx.tmp / "x")
    assert (logs / "acme.md").read_text() == "day one\n"


# ── 5. Git ───────────────────────────────────────────────────────────────────


def test_history_fresh_when_log_has_non_infra_path(fx):
    fx.applied()
    assert fx.git(fx.new, "rev-list", "--count", "HEAD").stdout.strip() == "1"
    assert fx.git(fx.new, "cat-file", "-e", fx.old_head).returncode != 0


def test_history_kept_when_all_paths_are_infra(make_fx):
    fx = make_fx(history="infra")
    fx.applied()
    is_ancestor = fx.git(fx.new, "merge-base", "--is-ancestor", fx.old_head, "HEAD")
    assert is_ancestor.returncode == 0
    tracked = fx.git(fx.new, "ls-files").stdout.splitlines()
    assert "nikki/2026-01-01.md" in tracked


def test_gitignore_covers_links(fx):
    fx.applied()
    status = fx.git(fx.new, "status", "--porcelain", "--ignored").stdout.splitlines()
    assert {s[3:] for s in status if s.startswith("!! ")} == {
        "docs",
        "gadgets",
        "loose.txt",
        "sub/big",
        "tools/",
    }
    assert [s for s in status if not s.startswith("!! ")] == []


def test_nested_repo_copied_ignored_and_keeps_its_remote(fx):
    fx.applied()
    tools = fx.new / "tools"
    assert fx.git(tools, "rev-list", "--count", "HEAD").stdout.strip() == "1"
    assert fx.git(tools, "remote", "get-url", "origin").stdout.strip() == TOOLS_REMOTE
    assert fx.git(fx.new, "ls-files", "tools").stdout == ""


def test_remote_added_and_pushed(fx):
    bare = fx.tmp / "remote.git"
    fx.git(fx.tmp, "init", "-q", "--bare", str(bare))
    fx.applied("--remote", bare)
    head = fx.git(fx.new, "rev-parse", "HEAD").stdout.strip()
    assert fx.git(bare, "rev-parse", "main").stdout.strip() == head
    assert fx.git(fx.new, "remote", "get-url", "origin").stdout.strip() == str(bare)


def test_unknown_ignored_path_stops_before_push(fx):
    bare = fx.tmp / "remote.git"
    fx.git(fx.tmp, "init", "-q", "--bare", str(bare))
    (fx.old / "nikki" / "private.txt").write_text("only here\n")
    (fx.old / ".gitignore").write_text(".DS_Store\nprivate.txt\n")
    r = fx.migrate("--apply", "--remote", bare)
    assert r.returncode != 0
    assert "nikki/private.txt" in r.stderr
    assert fx.git(bare, "for-each-ref").stdout == ""
    assert fx.new.is_symlink()


# ── 6. Claude state ──────────────────────────────────────────────────────────


def test_project_dirs_copied_to_new_key(fx):
    before = {p.name for p in fx.projects.iterdir()}
    fx.applied()
    root, widgets = encode(fx.new), encode(fx.new / "widgets")
    assert {p.name for p in fx.projects.iterdir()} == before | {root, widgets}
    assert (fx.projects / root / "a.jsonl").read_text() == "transcript a.jsonl\n"
    assert (fx.projects / widgets / "b.jsonl").read_text() == "transcript b.jsonl\n"


def test_only_waiter_files_copied(fx):
    before = {p.name for p in fx.cache.iterdir()}
    fx.applied()
    added = {p.name for p in fx.cache.iterdir()} - before
    assert added == {
        f"{encode(fx.new)}.waiter",
        f"{encode(fx.new / 'widgets')}.waiter-off",
    }


def test_unlisted_sibling_seat_is_left_alone(fx):
    """The first real run is the cloud root: its other seats must keep running."""
    fx.set_lsof(
        (4243, "sibling", fx.old / "gadgets"), (4244, "reader", fx.old / "docs")
    )
    fx.set_unread(fx.old / "gadgets")
    fx.applied()
    assert not any(str(fx.old / "gadgets") in c for c in fx.calls())
    assert not (fx.projects / encode(fx.new / "gadgets")).exists()
    assert not (fx.cache / f"{encode(fx.new / 'gadgets')}.waiter").exists()


def test_refuses_when_destination_key_exists(fx):
    (fx.projects / encode(fx.new)).mkdir()
    r = fx.migrate("--apply")
    assert r.returncode != 0
    assert encode(fx.new) in r.stderr
    assert fx.destroyed() == set()


def test_rerun_skips_a_copy_this_tool_made(fx):
    blocked = fx.projects / encode(fx.old / "widgets")
    blocked.chmod(0o000)
    try:
        assert fx.migrate("--apply").returncode != 0
    finally:
        blocked.chmod(0o755)
    assert (fx.projects / encode(fx.new) / "a.jsonl").exists()
    fx.applied()
    assert (fx.projects / encode(fx.new / "widgets") / "b.jsonl").exists()


def test_rerun_refuses_when_source_changed_after_the_copy(fx):
    blocked = fx.projects / encode(fx.old / "widgets")
    blocked.chmod(0o000)
    try:
        assert fx.migrate("--apply").returncode != 0
    finally:
        blocked.chmod(0o755)
    later = fx.projects / encode(fx.old) / "later.jsonl"
    later.write_text("a session that ran after the failed run\n")
    future = later.stat().st_mtime + 3600
    os.utime(later, (future, future))
    r = fx.migrate("--apply")
    assert r.returncode != 0
    assert "changed since" in r.stderr
    assert fx.new.is_symlink()


# ── 7. Swap and report ───────────────────────────────────────────────────────


def test_swap_replaces_symlink_and_keeps_cloudlink(fx):
    fx.applied()
    cloudlink = fx.new.with_name("acme.cloudlink")
    assert fx.new.is_dir() and not fx.new.is_symlink()
    assert os.readlink(cloudlink) == str(fx.old)
    assert not (fx.new.parent / ".staging" / "acme").exists()


def test_swap_when_new_does_not_exist_yet(fx):
    fx.new.unlink()
    fx.applied()
    assert fx.new.is_dir() and not fx.new.is_symlink()
    assert not fx.new.with_name("acme.cloudlink").exists()


def test_migrated_items_are_renames(fx):
    names = (
        MANIFEST.split("\n\n")[0].splitlines()[1:] + MANIFEST.split("\n\n")[1].split()
    )
    names += [".git", ".gitignore"]
    inodes = {n: os.lstat(fx.old / n).st_ino for n in names}
    fx.applied()
    found = set()
    for dirpath, dirnames, filenames in os.walk(fx.old):
        for name in dirnames + filenames:
            if name.endswith(".migrated"):
                found.add(os.path.relpath(os.path.join(dirpath, name), fx.old))
        dirnames[:] = [d for d in dirnames if not d.endswith(".migrated")]
    assert found == {f"{n}.migrated" for n in names}
    for n, ino in inodes.items():
        assert os.lstat(fx.old / f"{n}.migrated").st_ino == ino, n


def test_pointer_written(fx):
    fx.applied()
    lines = (fx.old / "CLAUDE.md").read_text().splitlines()
    assert len(lines) == 2
    assert str(fx.new) in lines[1]


def test_prints_wake_and_check_commands_without_running_them(fx):
    out = fx.applied().stdout
    assert f"dispatch -C {fx.new} wake" in out
    assert f"dispatch -C {fx.new / 'widgets'} wake" in out
    assert f"dispatch -C {fx.new / 'widgets'} waiter status" in out
    assert "gadgets wake" not in out
    assert not any(c.endswith(" wake") for c in fx.calls())


# ── 8. Re-run and rollback ───────────────────────────────────────────────────


def test_rerun_links_new_folder(fx):
    fx.applied()
    (fx.old / "fresh").mkdir()
    (fx.old / "sub" / "extra.txt").write_text("new document\n")
    calls = len(fx.calls())
    fx.applied()
    assert os.readlink(fx.new / "fresh") == str(fx.old / "fresh")
    assert os.readlink(fx.new / "sub" / "extra.txt") == str(
        fx.old / "sub" / "extra.txt"
    )
    assert not (fx.new / "CLAUDE.md.migrated").exists()
    assert not (fx.new / "CLAUDE.md").is_symlink()
    assert fx.git(fx.new, "status", "--porcelain").stdout == ""
    assert fx.git(fx.new, "check-ignore", "fresh", "sub/extra.txt").returncode == 0
    assert fx.calls()[calls:] == []


def test_rerun_after_failed_stage_succeeds(fx):
    fx._stub("rsync", RSYNC_FAILS)
    assert fx.migrate("--apply").returncode != 0
    (fx.stubs / "rsync").unlink()
    fx.applied()
    assert (fx.new / "CLAUDE.md").read_text() == "# acme\n"


def test_refuses_a_real_new_dir_it_did_not_make(fx):
    fx.new.unlink()
    fx.new.mkdir()
    r = fx.migrate("--apply")
    assert r.returncode != 0
    assert "not a symlink" in r.stderr
    assert fx.destroyed() == set()


def test_rollback_dry_run_changes_nothing(fx):
    fx.applied()
    before = fx.whole_tree()
    r = fx.rollback()
    assert r.returncode == 0, r.stderr
    assert fx.whole_tree() == before


def test_rollback_restores_old_state(fx):
    before = snapshot(fx.old, mtimes=False)
    fx.applied()
    fx.set_seats()
    r = fx.rollback("--apply")
    assert r.returncode == 0, r.stderr
    assert snapshot(fx.old, mtimes=False) == before
    assert os.readlink(fx.new) == str(fx.old)
    kept = fx.new.with_name("acme.rolledback")
    assert (kept / "CLAUDE.md").read_text() == "# acme\n"
    assert not fx.new.with_name("acme.cloudlink").exists()


def test_rollback_refuses_with_live_seat_under_new(fx):
    fx.applied()
    fx.set_seats(fx.new / "widgets")
    r = fx.rollback("--apply")
    assert r.returncode != 0
    assert "live seat" in r.stderr
    assert fx.new.is_dir() and not fx.new.is_symlink()


def test_rollback_after_a_swap_that_failed_half_way(fx):
    before = snapshot(fx.old, mtimes=False)
    fx.old.chmod(0o555)  # renames inside --old now fail, after --new was swapped
    try:
        r = fx.migrate("--apply")
    finally:
        fx.old.chmod(0o755)
    assert r.returncode != 0
    assert "rollback" in r.stderr
    assert fx.migrate("--apply").returncode != 0  # refuses to carry on half-swapped
    fx.set_seats()
    r = fx.rollback("--apply")
    assert r.returncode == 0, r.stderr
    assert snapshot(fx.old, mtimes=False) == before
    assert os.readlink(fx.new) == str(fx.old)


def test_reapply_after_rollback_refuses_the_stale_claude_copy(fx):
    fx.applied()
    fx.set_seats()
    assert fx.rollback("--apply").returncode == 0
    r = fx.migrate("--apply")
    assert r.returncode != 0
    assert encode(fx.new) in r.stderr
    assert fx.new.is_symlink()
