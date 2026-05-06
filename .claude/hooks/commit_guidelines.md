# Git Commit Guidelines

## IMPORTANT: Commit Workflow

- `git commit` is allowed but the PreToolUse hook emits a non-blocking nag listing project docs — review them first and stage any updates alongside the commit
- No wrapper or user-approval step is required

## When to Update Docs

Update CLAUDE.md, README.md, or other project docs when there are:

- Changes to project structure (new directories, moved files)
- New scripts or changes to the build process
- Changes to dependencies (new packages, version requirements)
- Critical bugfixes that affect how the project works
- Changes to how project scripts, tools, skills, commands, or agents function
- Changes that impact existing documentation
- Other changes that Claude needs to know to perform well

## When Docs Updates Are NOT Needed

- Changes to prose in papers or slides
- Commits to code under active development
- Minor or non-structural changes
- Internal refactoring that doesn't change interfaces

## Commit Request Workflow

1. **Read docs**: Review CLAUDE.md, README.md, and any docs referenced in them
2. **Evaluate**: Use the criteria above to judge if docs need updating
3. **Update**: Make necessary doc changes (if any)
4. **Summarize**: ALWAYS tell the user:
   - Which docs you checked
   - What you updated (if any)
   - Why no updates were needed (if none)
5. **Stage**: Include doc changes in your staged files
6. **Commit**: Run `git commit -m "message"` directly
