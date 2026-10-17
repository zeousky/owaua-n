# owaua

> **Archived project:** Owaua is no longer actively maintained or operated as a hosted bot. This repository is provided as-is for people who want to study, fork, or self-host it. There is no hosted service, support commitment, or guarantee that third-party APIs and integrations still work.

Owaua is a Discord bot for chatting in servers. Ping it and it talks back.

Pick a persona: `rudeish`, `nerdish`, `flirty`, `explicit`, `irritating`, `cute`, `femboy`, or `normal`.
Casual chat stays short; ask for help and it gives fuller answers. It can search
the web, read images and documents, remember useful details, and play music.
Grok is the default chat model when configured. Full mode uses Grok 4.7 with medium reasoning. Luna handles hangout search and images. DeepSeek and Mercury stay available for text chat.

Use `!help` for all commands. A few essentials:

- `!persona <name>` — change its voice
- `!model grok|luna|deepseek|mercury|reset` — choose your model
- `!music help` — music controls
- `!memory view|pause|resume` — inspect or control saved notes
- `!memory erase mine` — erase your conversation history and notes

[Self-hosting](docs/SELF_HOSTING.md) · [Commands and behavior](docs/USAGE.md) · [Configuration](.env.example)

For development, see [setup and checks](docs/CODEX_CLOUD.md). The old operator-specific deployment notes are in [operations](docs/OPERATIONS.md) and are not a self-hosting guide.

Self-hosting requires a Discord application and one or more provider accounts and may incur charges. Providers receive prompts and any content you send them. Review their current terms and privacy policies before use. The bot stores server conversation context and memory in a local SQLite database; see [data and privacy notes](docs/SELF_HOSTING.md#data-and-privacy).

The bot includes optional music features and persona assets. Check local laws, platform rules, and the rights for any media you play or upload.

[License](LICENSE) · [Security policy](docs/SECURITY.md) · [Changelog](CHANGELOG.md)
