# Development setup

This repository can be edited in a local checkout or a cloud development
environment. No Discord token, provider API key, database, or running bot is
needed for offline development.

## Setup

Use Python 3.11 or newer (3.12 recommended):

```sh
bash scripts/setup-codex.sh
```

The script creates `.venv` and installs pinned development dependencies. On
Linux, it may install FFmpeg when needed. It does not load `.env`, start the
bot, or deploy anything.

## Checks

```sh
bash scripts/test.sh
.venv/bin/ruff check .
```

The tests mock provider requests and use temporary databases. Linux audio
checks require FFmpeg. Optional tests for the separate Sefbot host are skipped
when that checkout or its runtime is unavailable. The repository has had
platform-specific CI failures; check the current workflow results instead of
assuming every platform passes.

Keep `.env*` credentials, `data/`, databases, backups, environments, downloaded
models, and caches out of Git. `.env.example` is a configuration template, not
a credential store. Do not use the production Discord token for development.
