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

- **Never open a compose window.** No `mode: "open"`, no AppleScript `visible:true`, no `threaded_reply.sh`. **Why (Eric, 11/26):** "Everytime you open a composer window, I have to stop and wait … I cannot do any other work while I am waiting." That day, two reply windows opened with empty bodies.
- **Never carry mail text on the clipboard.** One seat's text overwrote another's.
- **"Send X to Y" in plain English = "save a draft of X to Y."** Approval doesn't transfer.
- **Sends are gated anyway:** `mail_send_gate.sh` prompts on every send (`compose_email` `mode: "send"`, `manage_drafts` `action: "send"`), and hookify blocks AppleScript `send`.

## New mail

Use `mcp__apple-mail-patrickfreyer__compose_email` with `mode: "draft"`. **Always pass `mode`:** the tool's own default is `"send"`.

- **Attachments:** attach files with `attachments` (absolute paths, comma-separated). A mail that refers to a file carries it. **Why (10/15):** a draft saying "sign the attached confidentiality agreement" went out with nothing attached.
- **Read it back before calling it ready.** Read the saved draft from Drafts and check the recipients, subject, body and attachments. Show its actual To/CC next to the recipients you meant; a mismatch means it isn't ready. **Why (11/11):** a seat called a draft ready although its JSON showed it addressed To Eric, and he sent it to himself twice.
- **Forbidden:** `create_rich_email_draft` and `forward_email` (both denied in settings), and `open /path/to/draft.eml`.
- **`compose_email` doesn't thread**, even with a `Re:` subject. Never use it for a reply.
- **If `compose_email` is unavailable,** tell the user and write the mail to a file, as for replies below.

## Replies (interim, until email-inbox#16)

No tool yet saves a threaded reply draft without a window; <https://github.com/underspecified/email-inbox/issues/16> builds one. Until it lands:

1. Choose the recipients with `bash ~/.claude/skills/email-inbox/scripts/get_recipients.sh --subject "<keyword>" [--mailbox <name>]`. It returns the full To/CC/BCC, so you can decide between reply and reply-all and keep escalation CCs.
2. Write the reply to a file in the seat's repo. Put the thread's subject, the intended To/CC and any attachment paths at the top, and report the path.

## Reading

`mcp__apple-mail-imdinu__get_email` fails with "Message not found" when the inbox shifts after the ID was listed. **Always re-list the mailbox before fetching by ID.** Cheapest refresh: `mcp__apple-mail-imdinu__list_mailboxes` (or `get_emails` on the same mailbox).
