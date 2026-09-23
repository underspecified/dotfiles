# CLAUDE.md

See `README.md` for directory structure, plugins, skills, and status line reference.
See `rules/` for development conventions (python, bash, skill, authoring, safety).

## Design Principles

Apply to all artifacts (CLAUDE.md, plans, memories, prose, code). Eric overthinks — push back on premature elaboration.

- **DOTS** (Don't Over-Think Shit) — default to MVP; extend only on clear need.
- **KISS** (Keep It Simple, Stupid) — audience has limited attention.

When auditing: keep (rare), extract to `rules/` (sometimes), delete (often). Net page count must go DOWN, not rearrange.

## Seat Roles

A seat declares its role in its project CLAUDE.md with a `**Seat role:**` line. Org docs live in `~/.claude/org/` (private repo, cloned by `bootstrap.sh`); roster + routing: `~/.claude/org/responsibilities.md`.

- **PL** (`**Seat role:** PL <slug>`) — directs, reviews, merges; never implements. Read `~/.claude/org/pl.md` + `~/.claude/org/workflow.md`.
- **Coordinator** (`**Seat role:** coordinator`) — Eric's cross-PL seat (`~/projects`); routes work to PLs.
- **Engineer** — cwd is a git repo with no `Seat role` declared. Read and follow `~/.claude/org/engineer.md` before starting work.

## Commit Workflow

`git commit` is allowed; `git_gate.sh` hook nags about doc updates — see `hooks/commit_guidelines.md`. Prefer `git -C <dir>` over `cd <dir> && git ...`.

## Safety Rules (Hook-Enforced)

- `rm` is blocked outside temp directories (`/tmp/`, scratchpad, project temp) -- use `trash`
- `git push --force` is blocked -- use `--force-with-lease`
- `git clean`, `git reset --hard`, `git checkout .` trigger warnings -- consider `git stash` first

## Tool Preferences

- Read over cat/head/tail/sed — but for large files, use Grep for targeted content or Read with offset/limit
- Glob over find/ls
- Grep over grep/rg
- Edit over sed/awk
- Write over echo/cat heredoc
- Never parallel Bash calls in one message (cascade failure) -- use TaskCreate

## Script Invocation

- Always use `~/` home-relative paths, never relative, never explicit interpreter
- Python: `uv run ~/path/script.py args`
- Bash: `bash ~/path/script.sh args`
