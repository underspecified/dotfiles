# Email Conventions

For signature + default account, see `signature.md` (untracked, lives only at `~/.claude/rules/`).

## Brevity

**Default to short emails.** Attention spans are limited; long messages get skimmed or buried.

- One email = one ask
- Open with the ask
- Cut everything non-load-bearing — status, history, "FYI"
- Attachments count against the attention budget
- Multiple asks for the same recipient → different channel (1-on-1, meeting), don't bundle

## Send Approval

**Never send without per-message approval.** Always open a draft (visible compose window) for user review.

- `compose_email`: `mode: "open"`, never `"send"`
- AppleScript: `visible:true`, never `send newMsg` (enforced by `~/.claude/hookify.block-applescript-mail-send.local.md`)
- `threaded_reply.sh`: opens a draft by default — correct
- **"Send X to Y" in plain English = "open a draft of X to Y."** Approval doesn't transfer.

Silent send failures (AppleScript `send` → Mail.app) leave no Sent-folder confirmation. Drafts make the human the gate.

## Composing (new emails only)

Use `mcp__apple-mail-patrickfreyer__compose_email`:

- `mode: "open"` — compose window (default)
- `mode: "draft"` — silent save to Drafts
- `mode: "send"` — immediate send. Requires an explicit ask to bypass the draft step ("send X to Y without showing me a draft"); plain "Send X to Y" still means "open a draft" per Send Approval above.

Forbidden: `create_rich_email_draft`, `open /path/to/draft.eml`, AppleScript `send` against Mail.app.

If `compose_email` is unavailable, **alert the user** and offer the visible-draft AppleScript fallback (`make new outgoing message {visible:true, ...}` with no `send` action) as a user-confirmed choice. See `~/.claude/skills/email-inbox/CLAUDE.md`.

`compose_email` does NOT thread to existing email even with `Re:` subject. Use only for genuinely new outbound mail.

## Replying (mandatory two-step flow)

For replies, do not shortcut. `compose_email` skips threading; `reply_to_email` is Inbox-only with blank quote bodies (deprecated — do not use).

**1. Inspect recipients:**

```
bash ~/.claude/skills/email-inbox/scripts/get_recipients.sh --subject "<keyword>" [--mailbox <name>]
```

Returns JSON `{date, subject, from, to, cc, bcc}` per match — the only path to full To/CC/BCC. Use to decide reply-all vs sender-only and preserve escalation-chain CCs.

**2. Compose the threaded reply:**

```
bash ~/.claude/skills/email-inbox/scripts/threaded_reply.sh \
  --subject "<keyword>" \
  --mailbox "<Inbox|Sent Items|Archive>" \
  --body-file <path> \
  [--reply-all] [--account <name>]
```

Opens Mail with proper threading + quoted chain. Works on any mailbox. Returns JSON `{ok, subject, to, cc}`.

### Attachments in a reply

`threaded_reply.sh` doesn't support `--attach` yet (tracked at <https://github.com/underspecified/email-inbox/issues/1>). Until it does:

1. Open the threaded draft via `threaded_reply.sh`
2. Ask the user to drag-drop the file into the open Mail.app draft
3. Do NOT fall back to `compose_email` — breaks threading (Reply-To / In-Reply-To / References headers)

## Reading

`mcp__apple-mail-imdinu__get_email` fails with "Message not found" when the inbox shifts after the ID was listed. **Always re-list the mailbox before fetching by ID.** Cheapest refresh: `mcp__apple-mail-imdinu__list_mailboxes` (or `get_emails` on the same mailbox).
