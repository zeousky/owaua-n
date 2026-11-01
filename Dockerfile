FROM python:3.12-slim

LABEL org.opencontainers.image.title="Kirmy Discord bot"
LABEL org.opencontainers.image.description="Persona-driven Discord hangout bot"
LABEL org.opencontainers.image.source="https://github.com/zeousky/owaua"
LABEL org.opencontainers.image.licenses="MIT"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app/src/owaua

WORKDIR /app

RUN apt-get update \
    && apt-get install --no-install-recommends -y ffmpeg ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=denoland/deno:bin-2.9.7 /deno /usr/local/bin/deno
RUN printf '%s\n' \
    '#!/usr/bin/env python3' \
    'import os, sys' \
    'drop = {"-blocksize", "-fec", "-packet_loss"}' \
    'cleaned = []' \
    'args = sys.argv[1:]' \
    'i = 0' \
    'while i < len(args):' \
    '    if args[i] in drop:' \
    '        i += 2' \
    '        continue' \
    '    cleaned.append(args[i])' \
    '    i += 1' \
    'os.execv("/usr/bin/ffmpeg", ["/usr/bin/ffmpeg", *cleaned])' \
    > /usr/local/bin/ffmpeg \
    && chmod 755 /usr/local/bin/ffmpeg

COPY requirements.txt .
RUN python -m pip install --no-cache-dir -r requirements.txt

COPY src/owaua ./src/owaua
COPY personas ./personas
COPY pfps ./pfps
COPY banners ./banners
COPY scripts/check-runtime.py ./scripts/check-runtime.py

RUN useradd --create-home --shell /usr/sbin/nologin kirmy \
    && mkdir -p /app/data \
    && chown -R kirmy:kirmy /app

ENTRYPOINT ["sh", "-c", "mkdir -p /app/data && chown kirmy:kirmy /app/data && exec su -s /bin/sh kirmy -c 'exec python src/owaua/bot.py'"]
