# Bash Script Conventions

## Header Template

Always start with strict mode:

```bash
#!/usr/bin/env bash
# Usage: script_name.sh <required_arg> [optional_arg]
# Output: JSON object/array description
set -euo pipefail
```

## Invocation

Always use `bash` with home-relative paths:

```
bash ~/path/script.sh args
```

Never use relative paths.

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
