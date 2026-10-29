# ~/.claude

Claude Code user configuration directory. Config files are tracked by `lnk` (symlinked from `~/.config/lnk/.claude/`). Runtime state stays as real files and is not tracked.

## What's Tracked (lnk)

| Item | Description |
|------|-------------|
| `CLAUDE.md` | Global instructions loaded into every session |
| `README.md` | This file |
| `settings.json` | Permissions, hooks, plugins, env vars, status line |
| `claude-limitline.json` | Status line theme config |
| `hookify.*.local.md` | Safety rules (3 files, must stay at root -- plugin constraint) |
| `rules/` | Convention files (python, bash, markdown, skill, authoring, safety) |
| `hooks/` | Shell hook scripts (commit workflow, doc nag) |
| `commands/` | Slash command definitions (3 `.md` files) |
| `commands-obsolete/` | Retired commands, kept for reference; not linked, so they never load |
| `agents/dont-ask.md` | Auto-approve agent definition |
| `skills/bootstrap.sh` | Skills bootstrap script |
| `mcp/bootstrap.sh` | MCP server bootstrap script |
| `patches/` | Local patches against marketplace plugins + idempotent applier |

## What's Not Tracked (runtime state)

- `history.jsonl`, `file-history/`, `shell-snapshots/`, `session-env/`
- `projects/`, `plans/`, `tasks/`, `teams/`, `todos/`
- `plugins/`, `cache/`, `debug/`, `telemetry/`, `statsig/`, `paste-cache/`
- `claude-limitline-fork/` -- cloned repo, set up by bootstrap
- `skills/*/` -- individual skill repos, cloned by bootstrap
- `mcp/*/` -- MCP server state (if any), not tracked

## Skills Architecture

Skills are private git repos on `underspecified`, cloned directly into `~/.claude/skills/`. Composite skills (research, planning) have sub-skills symlinked as top-level entries via relative paths.

```text
~/.claude/skills/
├── computation-graph/    github:underspecified/computation-graph
├── dispatch/             github:underspecified/dispatch
├── figure/               github:underspecified/figure
├── gantt-chart/          github:underspecified/gantt-chart
├── hansei/               github:underspecified/hansei
├── meeting/              github:underspecified/meeting
├── planning/             github:underspecified/planning
│   └── skills/           (good-morning, good-night)
├── presentation/         github:underspecified/presentation
│   └── skills/           (presentation-plan)
├── research/             github:underspecified/research
│   └── skills/           (research-download, research-summarize, etc.)
├── sync-latex/           github:underspecified/sync-latex
├── travel/               github:underspecified/travel
├── email-inbox/          local only (no git repo)
├── good-morning ->       planning/skills/good-morning
├── good-night ->         planning/skills/good-night
├── presentation-plan ->  presentation/skills/presentation-plan
├── research-audit ->     research/skills/research-audit
├── ...                   (other research sub-skill symlinks)
└── bootstrap.sh          (lnk-tracked)
```

## MCP Servers

MCP servers are registered via `claude mcp add` (stored in `~/.claude.json`, not tracked by lnk). Bootstrap re-registers them on new machines.

| Server | Transport | Command |
|--------|-----------|---------|
| google-workspace | stdio | `uvx --exclude-newer <date> workspace-mcp==<version> --tools drive docs sheets --single-user` |
| markitdown-mcp | stdio | `uvx --exclude-newer <date> markitdown-mcp==<version>` |
| che-ical-mcp | plugin | Managed by psychquant-claude-plugins marketplace |
| Claude Gmail | built-in | `mcp__claude_ai_Gmail__*` |
| Claude Calendar | built-in | `mcp__claude_ai_Google_Calendar__*` |
| apple-mail-patrickfreyer | stdio | `uvx --exclude-newer <date> --with "mcp<2" mcp-apple-mail==<version>` (work Macs only; sends gated by `hooks/mail_send_gate.sh`) |
| apple-mail-imdinu | stdio | `apple-mail-mcp`, via `uv tool install --exclude-newer <date> apple-mail-mcp==<version>` (work Macs only) |

### Versions are pinned

The versions and dates live in variables at the top of `mcp/bootstrap.sh` (MCP servers) and `hooks/bootstrap.sh` (ruff, rumdl and panache on Linux). Each is an exact version, and `--exclude-newer` freezes dependencies at a date, so a start never pulls a new release.

**Not pinned yet:** on the Mac, Homebrew installs a missing hook tool at whatever version it carries. The bring-up runs `brew bundle --no-upgrade`, which upgrades an installed formula only when a new install depends on a newer one. On Linux, apt's jq, shellcheck and shfmt are the distro's, and the nosudo installers for shfmt and shellcheck fetch the latest release (dotfiles#22). uv itself isn't pinned (dotfiles#21).

To bump a version:

1. Open a PR that changes the variable (and the `--exclude-newer` date if the dependencies should move too; for panache, the tag and both sha256s). Never bump on a live host first.
2. In the PR, show that a resolve at the new date gives the versions you expect: `uv pip compile --exclude-newer <date>` on the pinned requirement. For an Apple Mail server, also re-check `settings.json`'s deny list and `mail_send_gate.sh` against the new release's send-capable tools.
3. After merge, run `bash ~/.claude/mcp/bootstrap.sh` on each host. It starts no server, adds missing entries, reinstalls `apple-mail-mcp`, and warns for each existing entry whose args differ from the pin. Edit those `args` in `~/.claude.json`, leaving `env` untouched, with no Claude sessions open, since a running session can write its old copy back. Check after a new session starts that the edit stayed. On Linux, re-run `bash ~/.claude/hooks/bootstrap.sh` for the hook tools.

## Bootstrap

After `lnk pull` on a new machine, run `bash ~/.claude/bootstrap.sh` to:

- Clone claude-limitline fork and build it
- Clone all skill repos into `~/.claude/skills/`
- Create sub-skill symlinks
- Register MCP servers via `claude mcp add`
- Apply local plugin patches from `patches/` (idempotent — safe to re-run)

## Commands

- `hydrate [--max-mb N] [--max-total-gb G] <path>...` (macOS, `~/.local/bin`): downloads cloud-only OneDrive/Google Drive/iCloud files, which a Claude session can't read (EDEADLK). Skips files over 50 MB, stops at 2 GB, prints JSON.

## Status Line

`claude-limitline-fork/` -- Node.js status line (selenized-light theme), tracks context window with warning/critical thresholds (60%/85%). Configured via `claude-limitline.json`.

## Enabled Plugins

- `pyright-lsp`, `typescript-lsp`, `lua-lsp` -- Language server support
- `code-simplifier` -- Code simplification agent
- `hookify` -- Safety rule management
- `security-guidance` -- Security hook enforcement
- `explanatory-output-style` -- Educational insight formatting
- `context7` -- Library documentation lookup
- `code-review`, `feature-dev` -- Development workflows
- `claude-md-management`, `claude-code-setup` -- Configuration management
- `che-ical-mcp` -- macOS Calendar & Reminders

## PostToolUse Hooks

- **Python files**: Auto-formatted with `ruff format` after Write/Edit
- **Markdown files** (`.md`): Auto-linted with `rumdl` after Write/Edit
- **Quarto files** (`.qmd`): Auto-formatted + linted with [`panache`](https://panache.bz) after Write/Edit (`hooks/panache_format.sh`) — Quarto-aware (fenced divs, grid tables, citations); lint warnings surfaced to the session
- **Shell files** (`.sh`): Auto-formatted with `shfmt` + linted with `shellcheck` after Write/Edit (`hooks/shellcheck_lint.sh`)

## Environment

- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` enabled globally
- Always-thinking mode enabled (`alwaysThinkingEnabled: true`)
