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
| `commands/` | Slash command definitions (12 `.md` files) |
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

```
~/.claude/skills/
├── computation-graph/    github:underspecified/computation-graph
├── figure/               github:underspecified/figure
├── gantt-chart/          github:underspecified/gantt-chart
├── hansei/               github:underspecified/hansei
├── meeting/              github:underspecified/meeting
├── planning/             github:underspecified/planning
│   └── skills/           (good-morning, good-night)
├── presentation/         github:underspecified/presentation
├── research/             github:underspecified/research
│   └── skills/           (research-download, research-summarize, etc.)
├── sync-latex/           github:underspecified/sync-latex
├── travel/               github:underspecified/travel
├── email-inbox/          local only (no git repo)
├── good-morning ->       planning/skills/good-morning
├── good-night ->         planning/skills/good-night
├── research-audit ->     research/skills/research-audit
├── ...                   (other research sub-skill symlinks)
└── bootstrap.sh          (lnk-tracked)
```

## MCP Servers

MCP servers are registered via `claude mcp add` (stored in `~/.claude.json`, not tracked by lnk). Bootstrap re-registers them on new machines.

| Server | Transport | Command |
|--------|-----------|---------|
| google-workspace | stdio | `uvx workspace-mcp --tools drive docs sheets --single-user` |
| markitdown-mcp | stdio | `uvx markitdown-mcp` |
| che-ical-mcp | plugin | Managed by psychquant-claude-plugins marketplace |
| Claude Gmail | built-in | `mcp__claude_ai_Gmail__*` |
| Claude Calendar | built-in | `mcp__claude_ai_Google_Calendar__*` |
| Apple Mail | built-in | `mcp__apple-mail-imdinu__*`, `mcp__apple-mail-patrickfreyer__*` |

## Bootstrap

After `lnk pull` on a new machine, run `bash ~/.claude/bootstrap.sh` to:
- Clone claude-limitline fork and build it
- Clone all skill repos into `~/.claude/skills/`
- Create sub-skill symlinks
- Register MCP servers via `claude mcp add`
- Apply local plugin patches from `patches/` (idempotent — safe to re-run)

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
- **Markdown/QMD files**: Auto-linted with `rumdl` after Write/Edit

## Environment

- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` enabled globally
- Always-thinking mode enabled (`alwaysThinkingEnabled: true`)
