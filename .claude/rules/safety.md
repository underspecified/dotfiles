# Safety Conventions (Extended)

These extend the hook-enforced rules in CLAUDE.md.

## Git

- No `--no-verify` on commits
- Prefer `git stash` over destructive operations (`git clean`, `git reset --hard`, `git checkout .`)

## Duplicate Detection Cascade (Research)

When adding papers, check for duplicates in this order:
1. **Filename match** -- exact match on `YEAR_Author_VENUE` pattern
2. **MD5 hash** -- cached at `~/.cache/pdf_hashes.json`
3. **Fuzzy title matching** -- 0.8 word-overlap threshold via `unidecode` + normalization

## File Size Thresholds (Research PDFs)

| Size | Classification | Action |
|------|---------------|--------|
| <10KB | Corrupt | Flag for re-download |
| 10KB--10MB | Normal | Process normally |
| 10MB--32MB | Large | Process with caution |
| >32MB | Too large | Move to `misc/` |
