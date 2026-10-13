"""Disposable, credential-free metadata worker for approved media hosts. No downloads."""

import json
import os
import re
import shutil
import sys
import tempfile
from urllib.parse import urlparse

SOLVER_CACHE_BYTES = 4 * 1024 * 1024


def _solver_cache(cache_dir: str) -> None:
    os.environ["DENO_DIR"] = os.path.join(cache_dir, "deno")
    os.environ["XDG_CACHE_HOME"] = os.path.join(cache_dir, "cache")
    os.environ["TMPDIR"] = os.path.join(cache_dir, "tmp")
    for path in (os.environ["DENO_DIR"], os.environ["XDG_CACHE_HOME"], os.environ["TMPDIR"]):
        os.makedirs(path, exist_ok=True)


def main() -> None:
    if not sys.platform.startswith("linux"):
        raise RuntimeError("Hardened music lookup requires Linux resource limits")
    unrestricted = len(sys.argv) == 3 and sys.argv[2] == "--unrestricted"
    if len(sys.argv) not in {2, 3} or (len(sys.argv) == 3 and not unrestricted):
        raise ValueError("Invalid invocation")
    if not unrestricted:
        try:
            import resource
            resource.setrlimit(resource.RLIMIT_CPU, (20, 20))
            resource.setrlimit(resource.RLIMIT_AS, (1024**3, 1024**3))
            resource.setrlimit(resource.RLIMIT_FSIZE, (SOLVER_CACHE_BYTES, SOLVER_CACHE_BYTES))
        except ImportError:
            raise RuntimeError("Media processing requires a Unix host")
    import deno
    deno_bin = deno.find_deno_bin()
    cache_dir = tempfile.mkdtemp(prefix="owaua-music-")
    try:
        _solver_cache(cache_dir)
        _resolve(unrestricted, deno_bin)
    finally:
        shutil.rmtree(cache_dir, ignore_errors=True)


def _resolve(unrestricted: bool, deno_bin: str) -> None:
    import yt_dlp
    lookup = sys.argv[1]
    parsed = urlparse(lookup)
    twitter_status = re.fullmatch(r"/(?:[A-Za-z0-9_]{1,15}|i)/status/[0-9]{1,30}", parsed.path)
    allowed_lookup = (
        parsed.scheme == "https"
        and (
            (parsed.hostname == "www.youtube.com" and parsed.path == "/watch" and bool(parsed.query))
            or (parsed.hostname == "x.com" and twitter_status is not None and not parsed.query)
        )
    )
    if not lookup or (not unrestricted and (len(lookup) > 600 or not allowed_lookup)):
        raise ValueError("Invalid lookup")
    options = {
        "format": "bestaudio/best",
        "noplaylist": not unrestricted, "playlistend": 1,
        "quiet": True, "no_warnings": True, "cachedir": False,
        "retries": 0, "fragment_retries": 0, "socket_timeout": 8,
        "js_runtimes": {"deno": {"path": deno_bin}},
    }
    if unrestricted:
        options["default_search"] = "ytsearch1"
        options["js_runtimes"] = {
            "deno": {"path": deno_bin}, "node": {}, "quickjs": {}, "bun": {},
        }
    else:
        options["allowed_extractors"] = ["youtube", "twitter"]
    cookies = os.environ.get("YOUTUBE_COOKIES_FILE", "")
    if cookies:
        options["cookiefile"] = cookies
    with yt_dlp.YoutubeDL(options) as downloader:
        try:
            info = downloader.extract_info(lookup, download=False)
        except Exception as exc:
            if "not a bot" in str(exc).casefold():
                print("YOUTUBE_BOT_CHECK", file=sys.stderr)
            raise
        if "entries" in info:
            info = next((entry for entry in info["entries"] if entry), None)
        if not info:
            raise ValueError("No track")
        result = {
            key: info.get(key)
            for key in ("duration", "is_live", "live_status", "http_headers")
        }
        for key in ("title", "url", "webpage_url", "acodec"):
            result[key] = str(info.get(key) or "")[:8192]
        print(json.dumps(result))


if __name__ == "__main__":
    main()
