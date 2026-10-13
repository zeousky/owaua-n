# Self-hosting

This project is archived and supplied as-is. Running a copy requires your own
Discord application, hosting, and provider accounts. No hosted Owaua service,
credentials, support, or future updates are included. Provider model names,
availability, prices, Discord APIs, and media integrations can change after
this archive was created.

## Requirements

- Python 3.11 or newer (3.12 recommended)
- A Discord application and bot token
- An API key for the AI provider you configure
- FFmpeg and Deno for music features; those features can be left unused

## Install

1. Create a Discord application and bot. Enable the Message Content Intent in
   the Discord Developer Portal, invite it to a test server with only the
   permissions it needs, and copy its token.
2. Clone this repository and set up the Python environment:

   ```sh
   bash scripts/setup-codex.sh
   cp .env.example .env
   ```

3. Edit `.env`. Set `DISCORD_TOKEN`, the provider key for the model you use,
   and `BOT_OWNER_IDS` to your own comma-separated Discord user IDs. Owner IDs
   are blank by default, so owner-only commands stay disabled until configured.
   Keep `.env` private. Do not reuse credentials from another bot.
4. Start the bot:

   ```sh
   .venv/bin/python src/owaua/bot.py
   ```

For unattended hosting, use a process manager or container you control. Review
the Dockerfile and scripts before running them; do not use the old Daki
deployment scripts unless you are the original operator and understand their
private dependencies.

## Configuration and limits

`.env.example` documents supported environment variables. IDs for owner access,
full-mode access, full-mode locations, and unrestricted music access are now
operator configuration; the public defaults contain no server or user IDs.
Review the full-mode provider choices and usage limits before enabling access.
Do not expose owner-only commands or unrestricted features to untrusted users.

Some features require optional provider credentials or companion software.
Missing optional services may make a feature unavailable. Check the source and
provider documentation for the current configuration; archived defaults may
refer to models or services that have changed.

## Data and privacy

The bot keeps local SQLite data under `data/`, including server conversation
context, user notes, quota/accounting records, and settings. The data persists
across restarts. Commands can erase bot-held memory, but they cannot remove
Discord messages, provider-side records, logs, backups, or copies made outside
this process. Decide who can access the host and its backups, secure the data
directory, and establish your own retention and deletion process.

Prompts, attachments, and derived text can be sent to configured AI providers.
Do not send sensitive or confidential material unless you have assessed that
provider's handling and have permission to process the material. Cloudflare
audit logging is optional and may send audit records to an endpoint you
configure. Music resolution contacts the media platforms and downloads metadata
or streams as needed.

## License and bundled media

The repository includes an MIT license. Before redistributing a fork, review
the provenance and reuse rights for bundled images, banners, persona text,
fonts, and other third-party material. The archive does not currently provide
a complete asset-by-asset attribution register for `banners/` and `pfps/`; do
not assume that every binary asset is covered by the software license. Verify
permission or replace those files before redistributing them.
