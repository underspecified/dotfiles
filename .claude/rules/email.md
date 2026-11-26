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

Use `mcp__apple-mail-patrickfreyer__compose_email` with `mode: "draft"`. **Always pass `mode`:** the tool's own default is `"send"`.

- **Recipients:** comma-separated with **no space** (`a@x.jp,b@x.jp`). **Why (11/26):** `"a@x.jp, b@x.jp"` saved a draft with no To header at all, while the tool reported both recipients.
- **Extra copies:** each call leaves a hidden copy open in Mail that can autosave duplicates into Drafts, even after you delete one. Don't chase them: tell Eric how many copies there are. Quitting Mail clears them.
- **Attachments:** attach files with `attachments` (absolute paths, comma-separated). A mail that refers to a file carries it. **Why (10/15):** a draft saying "sign the attached confidentiality agreement" went out with nothing attached.
- **Read it back before calling it ready.** Read the saved draft from Drafts and check the recipients, subject, body and attachments. Show its actual To/CC next to the recipients you meant; a mismatch means it isn't ready. **Why (11/11):** a seat called a draft ready although its JSON showed it addressed To Eric, and he sent it to himself twice.
- **Forbidden:** `create_rich_email_draft` and `forward_email` (both denied in settings), and `open /path/to/draft.eml`.
- **`compose_email` doesn't thread**, even with a `Re:` subject. Never use it for a reply.
- **If `compose_email` is unavailable,** tell the user and write the mail to a file in the seat's repo (recipients and subject at the top), and report its path.

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
  [--reply-all] [--account <name>]
```

- **What it does:** saves the reply to Drafts, threaded (`Re:` subject, `In-Reply-To`, `References`) and with the original quoted. It reads the draft back before printing `{ok:true, subject, to, cc}`.
- **A wrong recipient** closes the reply unsaved.
- **`ok:false`** names what is wrong and where the body copy is.
- **It never sends**, and Mail shows the reply for a few seconds without taking focus.
- **Runs take turns** across seats, and each takes up to about 110 s, so never set a Bash timeout under 120 s for it.
- **Attachments aren't supported yet** (`--attach` refuses: email-inbox#16). Write the file's path at the top of your report, so Eric can attach it in Drafts.

**3. Tell Eric it's ready:** the recipients, the subject and any file to attach. Then offer to open it; until opening is built, he double-clicks it in Drafts.

## Reading

`mcp__apple-mail-imdinu__get_email` fails with "Message not found" when the inbox shifts after the ID was listed. **Always re-list the mailbox before fetching by ID.** Cheapest refresh: `mcp__apple-mail-imdinu__list_mailboxes` (or `get_emails` on the same mailbox).
