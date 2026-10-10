# Plugin Patches

Local patches against marketplace plugins. Claude Code runs each plugin from its installed copy (`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>`, listed in `installed_plugins.json`), and a plugin update installs a fresh, unpatched copy.

`bootstrap.sh` patches every installed copy, plus the marketplace checkout, and is idempotent. `settings.json` runs it at every SessionStart with `--quiet`, which prints only failures, so an update is re-patched at the next session start. Run it by hand to see the status: `bash ~/.claude/patches/bootstrap.sh`.

| Patch | Plugin | Purpose |
|---|---|---|
| `hookify-global-rules.patch` | `hookify@claude-plugins-official` (`core/config_loader.py`) | Load `hookify.*.local.md` from `~/.claude/` as well as `$CWD/.claude/`, so the global rules fire in every project. |
| `hookify-model-messages.patch` | `hookify@claude-plugins-official` (`core/rule_engine.py`) | Show a rule's message to the model: as the deny reason on a block (upstream returns a bare "Blocked by hook"), and as `additionalContext` on a warn (upstream shows warns to the human only). |

If a patch stops applying (upstream changed the file), the SessionStart line names the plugin copy. Refresh the patch against the new copy.
