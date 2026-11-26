"""Tests for .claude/hooks/shellcheck_lint.sh.

The hook formats the edited file in place. Each test runs it on a file under
pytest's tmp_path, with the real shfmt, shellcheck and jq.

Run: uv run --with pytest pytest tests/test_shellcheck_lint.py -v
"""

import json
import shutil
import subprocess
from pathlib import Path

import pytest

HOOK = Path(__file__).resolve().parents[1] / ".claude/hooks/shellcheck_lint.sh"
OPERATORS = ["|", "&&", "||"]

pytestmark = pytest.mark.skipif(
    any(shutil.which(tool) is None for tool in ("shfmt", "shellcheck", "jq")),
    reason="needs shfmt, shellcheck and jq (.claude/hooks/bootstrap.sh)",
)


def leading(op: str) -> str:
    """rules/bash.md, Pipes in Scripts: the operator starts the next line."""
    return f"#!/usr/bin/env bash\necho one \\\n  {op} cat\n"


def trailing(op: str) -> str:
    return f"#!/usr/bin/env bash\necho one {op}\n  cat\n"


def run_hook(script: Path) -> None:
    """Run the hook as Claude Code does: the edited path arrives on stdin."""
    payload = json.dumps({"tool_input": {"file_path": str(script)}})
    subprocess.run(
        ["bash", str(HOOK)],
        input=payload,
        text=True,
        capture_output=True,
        check=True,
        timeout=30,
    )


@pytest.mark.parametrize("op", OPERATORS)
def test_leading_operator_is_left_alone(tmp_path: Path, op: str) -> None:
    script = tmp_path / "leading.sh"
    script.write_text(leading(op))
    run_hook(script)
    assert script.read_text() == leading(op)


@pytest.mark.parametrize("op", OPERATORS)
def test_trailing_operator_moves_to_line_start(tmp_path: Path, op: str) -> None:
    script = tmp_path / "trailing.sh"
    script.write_text(trailing(op))
    run_hook(script)
    assert script.read_text() == leading(op)
