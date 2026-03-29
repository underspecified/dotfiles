# Bash Script Conventions

Based on [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) and project-specific rules.

## When to Use Bash

Bash is for **simple glue and wrappers** (≤100 lines). If a script exceeds 100 lines or requires non-trivial control flow (nested loops, data structures, error recovery), rewrite it in Python. Shell is fragile and hard to debug — keep it simple.

| Use bash for | Use Python for |
|-------------|----------------|
| File operations, glue scripts | Data processing, complex logic |
| Command wrappers | Anything >100 lines |
| Build/deploy automation | JSON manipulation beyond `jq` |
| Simple text transforms | Error handling with retries |

## Header Template

Always start with strict mode:

```bash
#!/usr/bin/env bash
# Usage: script_name.sh <required_arg> [optional_arg]
# Output: JSON object/array description
set -euo pipefail
```

## Script Structure

- **`main()` function** for scripts longer than ~40 lines — call it at the bottom: `main "$@"`
- **Functions:** use `myfunc() { }` syntax (not `function myfunc { }`); declare locals with `local`
- **Function headers:** comment with purpose, arguments, outputs, return values for non-trivial functions
- **Indentation:** 2 spaces, no tabs

## Invocation

Always use `bash` with home-relative paths:

```
bash ~/path/script.sh args
```

Never use relative paths.

## Quoting and Variables

- **Always quote variables:** `"${var}"` not `$var` — prevents word splitting and globbing
- **Use `${var}`** not `$var` for clarity, especially in strings
- **Modern substitution:** `$(command)` not backticks
- **Lowercase** for local variables; **UPPERCASE** for exported/environment variables

```bash
# WRONG
echo $filename
result=`date`

# RIGHT
echo "${filename}"
result="$(date)"
```

## No Inline Variable Assignments

**Never prefix Bash commands with `VAR=value`** (e.g., `VAR=val cmd $VAR`). This breaks `allowed-tools` permission matching, which matches against the command name at the start of the string.

```
# WRONG -- Bash(quarto:*) won't match
QUARTO_LATEX_AUTO_INSTALL=false quarto render file.qmd

# RIGHT -- command name comes first
export QUARTO_LATEX_AUTO_INSTALL=false && quarto render file.qmd
```

If the variable is only needed once, inline the value directly into the arguments instead:

```
# ALSO RIGHT -- no variable needed
quarto render file.qmd -M latex-auto-install:false
```

## One Command Per Bash Call

**Keep Bash tool calls simple and atomic.** The `allowed-tools` whitelist matches the command at the start of the string. Chained commands (`&&`, `;`, `|`), redirects (`2>&1`, `> file`), and subshells break permission matching and cause tool calls to be silently denied — especially in agent teams.

```
# WRONG -- whitelist can't match, gets denied
ls -la /path && echo "---" && ls -la /other
find . -name "*.json" | xargs grep "pattern" 2>/dev/null

# RIGHT -- one command per Bash call
ls -la /path
# (separate call)
ls -la /other

# RIGHT -- if you need pipes/chains, put them in a script
bash ~/path/script.sh
```

**Rules:**
- One command per Bash tool call
- No `&&`, `;`, or `|` chains in Bash tool calls
- No `2>&1`, `2>/dev/null`, `> file` redirects — use the tool's built-in output
- If you need complex logic, write a script and invoke it
- Exception: `export VAR=val && command` is acceptable (see "No Inline Variable Assignments" above)

## Pipes in Scripts

When pipes are needed inside a script file (not a Bash tool call), split across lines with the pipe at the start of the continuation line:

```bash
# In a script file -- pipes are fine, split for readability
command1 \
  | command2 \
  | command3
```

## Error Handling

- All diagnostic output to STDERR: `echo "error: ..." >&2`
- Check return values: use `if` statements or `$?`
- Use `trap cleanup EXIT` for temp file cleanup
- `set -o pipefail` catches hidden pipe errors

## JSON I/O Patterns

**JSON is the preferred output format** for all scripts. Use `jq` for parsing and transforming JSON -- never spawn ad-hoc Python one-liners for JSON processing when `jq` can do the job. Common patterns:

| Pattern | Purpose |
|---------|---------|
| `jq -Rs '.'` | String escaping |
| `jq -s '.'` | Slurp NDJSON into arrays |
| `jq -r '... \| @tsv'` | Tab-separated extraction |
| `\|\| echo '[]'` | Fallback to empty structure on error |

## No Parallel Bash Calls

**Never make parallel Bash calls in a single message.** Due to cascade failure behavior (any failure causes all sibling calls to fail with "Sibling tool call errored"), use TaskCreate for independent operations:

```
# WRONG -- cascade failure risk
Bash("command1") + Bash("command2") in same message

# RIGHT -- failures isolated
TaskCreate for each independent operation
```

## Linting

Run [ShellCheck](https://www.shellcheck.net/) on scripts before commit. Common catches: unquoted variables, unreachable code, portability issues, deprecated syntax.
