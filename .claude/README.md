# ~/.claude

Claude Code user configuration directory. Config files are tracked by `lnk` (symlinked from `~/.config/lnk/.claude/`). Runtime state stays as real files and is not tracked.

## What's Tracked (lnk)

| Item | Description |
|------|-------------|
| `CLAUDE.md` | Global instructions loaded into every session |
| `README.md` | This file |
| `settings.json` | Permissions, hooks, plugins, env vars, status line |
| `claude-limitline.json` | Status line theme config |
| `hookify.*.local.md` | Safety rules (3 files, must stay at root — plugin constraint) |
| `rules/` | Convention files (python, bash, markdown, skill, authoring, safety) |
| `hooks/` | Shell hook scripts (commit workflow, doc nag) |
| `commands/` | Slash command definitions (12 `.md` files) |
| `agents/dont-ask.md` | Auto-approve agent definition |

## What's Not Tracked (runtime state)

- `history.jsonl`, `file-history/`, `shell-snapshots/`, `session-env/`
- `projects/`, `plans/`, `tasks/`, `teams/`, `todos/`
- `plugins/`, `cache/`, `debug/`, `telemetry/`, `statsig/`, `paste-cache/`
- `claude-limitline-fork/` — cloned repo, set up by bootstrap
- `skills/` — symlinks to `~/claude/skills/`, set up by bootstrap

## Skills Architecture

Skills live at `~/claude/skills/` (each is its own GitHub repo). Symlinks in `~/.claude/skills/` point there. The research skill has sub-skills nested under `research/skills/`.

```
~/claude/skills/
├── computation-graph/    github:underspecified/computation-graph
├── gantt-chart/          github:underspecified/gantt-chart
├── hansei/               github:underspecified/hansei
├── presentation/         github:underspecified/presentation
├── research/             github:underspecified/research
│   └── skills/           (research-download, research-summarize, etc.)
├── sync-latex/           github:underspecified/sync-latex
└── travel/               github:underspecified/travel
```

## Bootstrap

After `lnk pull` on a new machine, run `bash ~/.config/lnk/.claude/bootstrap.sh` to:
- Clone claude-limitline fork and build it
- Clone all skill repos into `~/claude/skills/`
- Create symlinks in `~/.claude/skills/`
- Clone MCP server repos into `~/claude/mcp/`

## Status Line

`claude-limitline-fork/` — Node.js status line (selenized-light theme), tracks context window with warning/critical thresholds (60%/85%). Configured via `claude-limitline.json`.

## Enabled Plugins

- `pyright-lsp`, `typescript-lsp` — Language server support
- `code-simplifier` — Code simplification agent
- `hookify` — Safety rule management
- `commit-commands` — Git commit/push/PR workflows
- `security-guidance` — Security hook enforcement
- `explanatory-output-style` — Educational insight formatting

## PostToolUse Hooks

- **Python files**: Auto-formatted with `ruff format` after Write/Edit
- **Markdown/QMD files**: Auto-linted with `rumdl` after Write/Edit

## Environment

- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` enabled globally
- Always-thinking mode enabled (`alwaysThinkingEnabled: true`)
