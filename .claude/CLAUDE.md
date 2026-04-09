# CLAUDE.md

See `README.md` for directory structure, plugins, skills, and status line reference.
See `rules/` for development conventions (python, bash, skill, authoring, safety).

## Commit Workflow

A hook-based commit workflow is enforced via `hooks/nag_docs.sh`:

- Running `git commit` directly is **denied** by the PreToolUse hook
- Review project docs first, then use `~/.claude/hooks/ask_git_commit.sh -m "message"` to commit
- That script triggers an "ask" flow for final user approval
- See `hooks/commit_guidelines.md` for full criteria on when docs need updating

## Safety Rules (Hook-Enforced)

- `rm` is blocked outside temp directories (`/tmp/`, scratchpad, project temp) -- use `trash`
- `git push --force` is blocked -- use `--force-with-lease`
- `git clean`, `git reset --hard`, `git checkout .` trigger warnings -- consider `git stash` first

## Tool Preferences

- Read over cat/head/tail/sed
- Glob over find/ls
- Grep over grep/rg
- Edit over sed/awk
- Write over echo/cat heredoc
- Never parallel Bash calls in one message (cascade failure) -- use TaskCreate

## Script Invocation

- Always use `~/` home-relative paths, never relative, never explicit interpreter
- Python: `uv run ~/path/script.py args`
- Bash: `bash ~/path/script.sh args`
