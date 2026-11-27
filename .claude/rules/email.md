# Email Conventions

For signature + default account, see `signature.md` (untracked, lives only at `~/.claude/rules/`).

## Brevity

**Default to short emails.** Attention spans are limited; long messages get skimmed or buried.

- One email = one ask
- Open with the ask
- Cut everything non-load-bearing — status, history, "FYI"
- Attachments count against the attention budget
- Multiple asks for the same recipient → different channel (1-on-1, meeting), don't bundle

## Drafts, never windows

**Never send.** Every mail is saved as a draft in Exchange's Drafts mailbox, and Eric reviews and sends it from there when he chooses.

- **Never open a compose window.** No `mode: "open"`, no AppleScript `visible:true`. **Why (Eric, 11/26):** "Everytime you open a composer window, I have to stop and wait … I cannot do any other work while I am waiting." That day, two reply windows opened with empty bodies.
- **Never carry mail text on the clipboard.** One seat's text overwrote another's.
- **"Send X to Y" in plain English = "save a draft of X to Y."** Approval doesn't transfer.
- **Sends are gated anyway:** `mail_send_gate.sh` prompts on every send (`compose_email` `mode: "send"`, `manage_drafts` `action: "send"`), and hookify blocks AppleScript `send`.

## New mail

```text
bash ~/.claude/skills/email-inbox/scripts/new_draft.sh \
  --to "<addr>[,<addr>...]" [--cc "<addr>[,<addr>...]"] \
  --subject "<subject>" --body-file <path> \
  [--attach <absolute path>]... [--account <name>]
```

- **What it does:** it saves the mail to Drafts and reads it back before printing `{ok:true, subject, to, cc, attachments}`: To and Cc as passed, the subject, the body, exactly the `--attach` files, and one copy.
- **A mail that refers to a file carries it:** pass `--attach` once per file. **Why (10/15):** a draft saying "sign the attached confidentiality agreement" went out with nothing attached.
- **Only addresses reach Mail:** `Name <address>` is accepted, but the name is dropped.
- **Everything else is as for replies (below):** a wrong recipient closes the mail unsaved; relay `ok:false` as it is and delete nothing; on "Mail stopped answering", stop and tell Eric; a Bash timeout of at least 120 s; then tell Eric it's ready, with the To/CC it read back next to the recipients you meant. **Why (11/11):** a seat called a draft ready although its JSON showed it addressed To Eric, and he sent it to himself twice.
- **Not for replies:** it doesn't thread. Use `threaded_reply.sh`.
- **Never `compose_email`:** its drafts lost their To (11/26, 11/27), and its hidden copies autosaved duplicates (email-inbox#20). **Also forbidden:** `create_rich_email_draft` and `forward_email` (both denied in settings), and `open /path/to/draft.eml`.
- **If the script can't run,** tell the user and write the mail to a file in the seat's repo (recipients and subject at the top), and report its path.

## Replies

**1. Choose the recipients:**

```text
bash ~/.claude/skills/email-inbox/scripts/get_recipients.sh --subject "<keyword>" [--mailbox <name>]
```

It returns the full To/CC/BCC, so you can decide between reply and reply-all and keep escalation CCs.

**2. Save the threaded reply as a draft:**

```text
bash ~/.claude/skills/email-inbox/scripts/threaded_reply.sh \
  --subject "<keyword>" --mailbox "<Inbox|Sent Items|Archive>" \
  --body-file <path> --expect-to "<every To and Cc address, comma-separated>" \
  [--attach <absolute path>]... [--reply-all] [--account <name>]
```

- **What it does:**
  - It saves the reply to Drafts, threaded (`Re:` subject, `In-Reply-To`, `References`), with the original quoted and each `--attach` file attached.
  - It reads the draft back before printing `{ok:true, subject, to, cc, attachments}`.
- **A reply that refers to a file carries it:** pass `--attach` once per file.
- **A wrong recipient** closes the reply unsaved.
- **`ok:false`** names what is wrong and where the body copy is. A second copy of the draft also gives `ok:false`: tell Eric, and don't delete anything.
- **"Mail stopped answering":** stop and tell Eric. Never quit, kill or restart Mail yourself.
- **It never sends.** The reply window flashes for under a second without taking focus.
- **Runs take turns** across seats, and each takes up to about 110 s, so never set a Bash timeout under 120 s for it.

**3. Tell Eric it's ready:** the recipients, the subject and the attachments. He opens it from Drafts (double-click); opening it for him isn't built.

## Reading

`mcp__apple-mail-imdinu__get_email` fails with "Message not found" when the inbox shifts after the ID was listed. **Always re-list the mailbox before fetching by ID.** Cheapest refresh: `mcp__apple-mail-imdinu__list_mailboxes` (or `get_emails` on the same mailbox).
