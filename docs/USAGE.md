# using owaua

This command reference describes the archived Owaua bot. Commands that call AI providers can incur charges for the operator. `!human on` changes the reply style. DMs are disabled by default.

Personas are `rudeish` (`low`, `medium`, `high`, medium by default), `nerdish`, `flirty`, `irritating`, `cute`, and `normal`. Luna is the usual model. `!model deepseek` and `!model mercury` select optional text models when configured; searches, images, and full mode may use Luna, and the reply identifies provider routing.

It can help with code, explain things, look things up, read images, and read PDF, text, Markdown, CSV, and JSON files. Casual replies stay short. A real question can run longer. Code tools are only for approved full-mode users.

## commands

`!help` prints these. There is a 25 second cooldown.

- `!persona rudeish low|medium|high`, or `nerdish|flirty|irritating|cute|normal`
- `!persona random` picks a hidden persona and does not say which
- `!human on|off`
- `!model luna|deepseek|mercury|reset` (optional models need their provider keys)
- `!context status|on|off|clear` (Manage Server, or the owner)
- `!language <full name>|reset` (Manage Server)
- `!music help`
- `!memory erase` clears this server (Manage Server)
- `!memory erase mine` clears your history and notes
- `!memory view|stats|status|pause|resume|forget`
- `!memory correct <id> <text>`
- `!memory forget <id>`
- `!reset all` (Manage Server)
- `!switch bot` runs sefbot in this server, or switches back (Manage Server)
- `!owner's note`

Provider calls may cost money to the operator. Use reasonable request sizes and review provider prices and limits.

Switching persona keeps the chat. Notes are yours, per server, and DMs are separate. They stay after a restart. Erasing them here does not delete the Discord messages.

Channel context is on by default. Turning it off forgets the stored lines for that channel. The bot retains only a bounded recent history, typically for about a week.

Two files per message, 8 MB each. PDFs stop at 20 pages. Scanned or locked PDFs are skipped. The file text is not saved into memory.

Each person gets 30 model calls per 10 minutes (`API_REQUESTS_PER_USER`, `API_WINDOW_SECONDS`). Chat is also capped at eight messages a minute and three replies at once.

[License](../LICENSE) · [Self-hosting and privacy](SELF_HOSTING.md)
