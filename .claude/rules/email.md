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

- `mode: "open"` — compose window. **Always pass `mode`:** the tool's own default is `"send"`.
- `mode: "draft"` — silent save to Drafts
- `mode: "send"` — immediate send. Requires an explicit ask to bypass the draft step ("send X to Y without showing me a draft"); plain "Send X to Y" still means "open a draft" per Send Approval above. `mail_send_gate.sh` makes every send (this, or `manage_drafts` `action: "send"`) prompt for confirmation.

Forbidden: `create_rich_email_draft`, `forward_email` (always sends; no draft mode — both denied in settings), `open /path/to/draft.eml`, AppleScript `send` against Mail.app.

If `compose_email` is unavailable, **alert the user** and offer the visible-draft AppleScript fallback (`make new outgoing message {visible:true, ...}` with no `send` action) as a user-confirmed choice. See `~/.claude/skills/email-inbox/CLAUDE.md`.

`compose_email` does NOT thread to existing email even with `Re:` subject. Use only for genuinely new outbound mail.

## Replying (mandatory two-step flow)

For replies, do not shortcut. `compose_email` skips threading; `reply_to_email` is Inbox-only with blank quote bodies (deprecated — do not use).

**1. Inspect recipients:**

```text
bash ~/.claude/skills/email-inbox/scripts/get_recipients.sh --subject "<keyword>" [--mailbox <name>]
```

Returns JSON `{date, subject, from, to, cc, bcc}` per match — the only path to full To/CC/BCC. Use to decide reply-all vs sender-only and preserve escalation-chain CCs.

**2. Compose the threaded reply:**

```text
bash ~/.claude/skills/email-inbox/scripts/threaded_reply.sh \
  --subject "<keyword>" \
  --mailbox "<Inbox|Sent Items|Archive>" \
  --body-file <path> \
  [--reply-all] [--account <name>]
```

Opens Mail with proper threading + quoted chain. Works on any mailbox. Returns JSON `{ok, subject, to, cc}`.

- **Runs from all seats take turns.** Each waits up to 60 s, and a run can take about 110 s in total, so never set a Bash timeout under 120 s for it. "No window opened" means it timed out waiting: retry it.
- **On `ok:false`, point Eric to the body copy the error names** (`~/Library/Caches/email-inbox/drafts/…`), not only the clipboard. Say plainly that the reply window may be open with an **empty body**, so he doesn't send it.
- **Check the recipients before calling a draft ready.** Show the draft's actual To/CC (the JSON `to`/`cc`) next to the recipient you meant. A mismatch, or `ok:false`, means the draft is not ready: say so, never "ready". **Why (11/11):** a reply to Eric's own Sent mail opened To Eric; the JSON showed it, the seat called the draft ready, and he sent it to himself twice.

## Attachments

**A draft that needs a file either carries it, or opens with the exact file revealed and named.**

- **New mail:** attach it with `compose_email`'s `attachments` (absolute paths, comma-separated).
- **Reply:** `threaded_reply.sh` can't attach yet (<https://github.com/underspecified/email-inbox/issues/1>). When the draft opens, run `open -R <path>` so Finder shows the file, and say in the same message: "drag `<filename>` into the open draft". Don't fall back to `compose_email`: it breaks threading (In-Reply-To / References).

**Why (10/15):** a draft saying "sign the attached confidentiality agreement" went out with nothing attached; the drag-in instruction was only in chat.

## Reading

`mcp__apple-mail-imdinu__get_email` fails with "Message not found" when the inbox shifts after the ID was listed. **Always re-list the mailbox before fetching by ID.** Cheapest refresh: `mcp__apple-mail-imdinu__list_mailboxes` (or `get_emails` on the same mailbox).
