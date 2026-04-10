# Plugin Patches

Local patches against plugins installed via the Claude Code marketplace. These
live outside the plugin directories so they survive marketplace updates, but
they must be re-applied manually after an update.

## Current patches

| Patch | Target | Purpose |
|---|---|---|
| `hookify-global-rules.patch` | `claude-plugins-official/plugins/hookify/core/config_loader.py` | Load `hookify.*.local.md` rules from `~/.claude/` in addition to `$CWD/.claude/`, so global rules apply regardless of where Claude Code is launched. |

## Applying a patch

```
cd ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/<plugin>
patch -p1 --dry-run < ~/.config/lnk/.claude/patches/<name>.patch   # sanity check
patch -p1 < ~/.config/lnk/.claude/patches/<name>.patch
```

## Checking whether a patch is currently applied

```
patch -p1 -R --dry-run < ~/.config/lnk/.claude/patches/<name>.patch
```

Exit 0 means the patch is applied (it could be reverted cleanly). Exit 1
means it isn't.

## After a plugin update

Re-run the "checking whether applied" command on each patch. Any that report
"not applied" need to be re-applied with the forward `patch -p1 < ...` command.
