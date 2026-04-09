# Python Script Conventions

## Stand-Alone Scripts (PEP 723)

For single-file scripts, use inlined `uv run` with PEP 723 metadata:

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["requests"]
# ///
"""Usage: uv run script_name.py <args>
Output: JSON with result fields
"""
```

Invocation — always home-relative paths:

```
uv run ~/path/script.py args
```

Never use relative paths. Never invoke with an explicit interpreter (`python3 script.py`).

## Projects with Modules

For projects with multiple modules, shared code, or complex structure, use `pyproject.toml` instead of inlined metadata. Let `uv` manage the virtualenv and dependencies via the project manifest.

- `src/` layout for installable packages; flat layout for internal tools
- `__init__.py`: re-exports only, no logic
- `__main__.py` for runnable packages (`python -m pkg`)
- Graduate script → package when: shared code across scripts, or >300 lines with distinct concerns

## Dependency Management

- `uv add --script` to manage inline deps — don't hand-edit the TOML block
- `exclude-newer` in `[tool.uv]` for reproducibility
- `[dependency-groups]` in `pyproject.toml` for dev/test/lint splits (PEP 735)

## Type Hints

- Modern syntax: `int | str | None`, `list[str]`, `dict[str, int]` — never `Optional`, `Union`, `List`, `Dict`
- Generics: `def first[T](items: list[T]) -> T` — not `TypeVar` (PEP 695, 3.12+)
- Type aliases: `type Vector = list[float]` — not `TypeAlias` (PEP 695, 3.12+)
- Parameters: abstract types (`Sequence`, `Mapping`); returns: concrete (`list`, `dict`)
- Never `from __future__ import annotations` — native since 3.14 (PEP 649)
- Annotate shared module signatures; optional in short scripts

## JSON Output

- Scripts output structured JSON to stdout
- Use `json.dumps(result, indent=2)` for formatted output
- Return meaningful fields, not raw strings

## Validation

- Use `pydantic.BaseModel` for external data (API responses, config files, user input) — not `TypedDict` or manual checks
- Parse JSON directly: `Model.model_validate_json(raw)` — not `Model(**json.loads(raw))`
- Serialize: `model.model_dump(mode="json")` for JSON-safe dicts
- Never use deprecated v1 API (`parse_raw`, `parse_obj`, `.dict()`, `.json()`)
- `Field(description=...)` for self-documenting schemas
- Coerce with care: prefer `strict=True` on models that shouldn't silently convert types
- For scripts: pydantic is optional — plain dicts are fine for simple JSON output

## Output Streams

- `stdout` → data (JSON); `stderr` → diagnostics
- Use `logging` to stderr, not `print`, for diagnostics
- Logging: `%s` placeholders, not f-strings (`logger.info("Got %d items", n)`)

## Error Handling

- Catch specific exceptions — never bare `except:` or `except Exception`
- Reraise with context: `raise NewError("msg") from original`
- Minimize code inside `try` blocks
- Never `assert` for runtime validation (optimized away with `-O`)
- Never `return`/`break`/`continue` inside `finally` (PEP 765)

## Subprocess

- List form always: `subprocess.run(["cmd", arg], check=True, timeout=30)`
- Never `shell=True` with variable input
- Always set `timeout=`

## Dataclasses

- Default `@dataclass(slots=True)` — faster, less memory
- Value objects: add `frozen=True`

## Testing

- Framework: `pytest`
- Test when: non-trivial logic, repeated execution, data correctness matters
- Skip when: pure glue scripts, one-shot migrations, test would re-implement the function
- File location: `tests/` directory mirroring source layout
- Use `tmp_path` fixture for filesystem tests, `capsys` for stdout capture
- `pytest.raises(ExcType, match="pattern")` for exception testing
- Parametrize for input variants; one logical assertion per test

## Auto-Formatting

Python files are auto-formatted with `ruff format` and auto-linted with `ruff check` via PostToolUse hooks after Write/Edit. Never use ad-hoc `python -c "import ast; ..."` one-liners to check syntax — use `ruff check` instead. Remove all debug `print`/`breakpoint` before commit. Code must pass both `pyright` and `ruff check` with zero errors and zero warnings before commit.
