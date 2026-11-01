#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd -P)
cd "$ROOT_DIR"
BACKEND=${OWAUA_PERSONA_BACKEND:-auto}
RAILWAY_BIN=${OWAUA_RAILWAY_BIN:-$(command -v railway || true)}

if [[ "$BACKEND" == "auto" ]]; then
  if [[ -n "$RAILWAY_BIN" ]]; then
    BACKEND=railway
  else
    BACKEND=daki
  fi
fi

DAKI_DEPLOY_SCRIPT=${OWAUA_DEPLOY_SCRIPT:-}
if [[ "$BACKEND" == "daki" && -z "$DAKI_DEPLOY_SCRIPT" ]]; then
  for candidate in \
    "$HOME/.config/owaua-deploy/daki_client.py" \
    "$ROOT_DIR/../owaua/scripts/deploy"
  do
    if [[ -f "$candidate" ]]; then
      DAKI_DEPLOY_SCRIPT=$candidate
      break
    fi
  done
  DAKI_DEPLOY_SCRIPT=${DAKI_DEPLOY_SCRIPT:-"$HOME/.config/owaua-deploy/daki_client.py"}
fi

if [[ "$BACKEND" == "railway" && -z "$RAILWAY_BIN" ]]; then
  echo "Railway backend requested, but the railway CLI was not found." >&2
  exit 1
fi
if [[ "$BACKEND" == "daki" && ! -f "$DAKI_DEPLOY_SCRIPT" ]]; then
  echo "Cannot find the Daki deployment client: $DAKI_DEPLOY_SCRIPT" >&2
  exit 1
fi
if [[ "$BACKEND" != "railway" && "$BACKEND" != "daki" ]]; then
  echo "Unknown OWAUA_PERSONA_BACKEND '$BACKEND'. Choose auto, railway, or daki." >&2
  exit 1
fi

PERSONA_MODELS="${*:-rudeish nerdish flirty explicit irritating femboy}"

ROOT_DIR="$ROOT_DIR" \
PERSONA_BACKEND="$BACKEND" \
RAILWAY_BIN="$RAILWAY_BIN" \
RAILWAY_PROJECT="${OWAUA_RAILWAY_PROJECT:-}" \
RAILWAY_ENVIRONMENT="${OWAUA_RAILWAY_ENVIRONMENT:-}" \
RAILWAY_SERVICE="${OWAUA_RAILWAY_SERVICE:-owaua}" \
RAILWAY_DEPLOYMENT_INSTANCE="${OWAUA_RAILWAY_DEPLOYMENT_INSTANCE:-}" \
DAKI_DEPLOY_SCRIPT="$DAKI_DEPLOY_SCRIPT" \
PERSONA_MODELS="$PERSONA_MODELS" \
python3 - <<'PY'
import hashlib
import importlib.machinery
import importlib.util
import os
import subprocess
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
backend = os.environ["PERSONA_BACKEND"]
model_files = {
    "rudeish-low": "personas/rudeish-low.txt",
    "rudeish-medium": "personas/rudeish-medium.txt",
    "rudeish-high": "personas/rudeish-high.txt",
    "nerdish": "personas/nerdish.txt",
    "flirty": "personas/flirty.txt",
    "explicit": "personas/explicit.txt",
    "irritating": "personas/irritating.txt",
    "cute": "personas/cute.txt",
    "femboy": "personas/femboy.txt",
    "normal": "personas/normal.txt",
}
rudeish_level_models = ("rudeish-low", "rudeish-medium", "rudeish-high")
requested = os.environ["PERSONA_MODELS"].replace(",", " ").replace("/", " ").split()
models = []
for model in requested:
    model = model.lower()
    if model == "and":
        continue
    if model == "rudeish":
        # Bare "rudeish" keeps the old command working and updates every level.
        for level_model in rudeish_level_models:
            if level_model not in models:
                models.append(level_model)
        continue
    if model not in model_files:
        valid = ", ".join(model_files)
        raise RuntimeError(f"Unknown persona '{model}'. Choose: {valid}")
    if model not in models:
        models.append(model)
if not models:
    models = list(model_files)

files = {model: root / model_files[model] for model in models}
missing = [str(path) for path in files.values() if not path.is_file()]
if missing:
    raise RuntimeError("Missing persona file(s): " + ", ".join(missing))

for model, local_path in files.items():
    print(f"Local persona {model} is live ({local_path.relative_to(root)})")

dry_run = os.getenv("OWAUA_DAKI_DRY_RUN", "0").strip().lower() in {"1", "true", "yes", "on"}
if dry_run:
    if backend == "railway":
        for model in models:
            print(f"Dry run: would update Railway /app/{model_files[model]}")
        print("Local files are live. Railway upload skipped (dry run).")
    else:
        for model in models:
            print(f"Dry run: would upload persona-test-bot/{model_files[model]}")
        print("Local files are live. Daki upload skipped (dry run).")
    raise SystemExit(0)

if backend == "railway":
    # SSH receives the file bytes on stdin and atomically replaces the existing
    # persona, retaining the deployed file's owner and mode.
    remote_writer = r'''import hashlib, os, stat, sys, tempfile
from pathlib import Path

target = Path(sys.argv[1])
persona_dir = Path("/app/personas").resolve()
if target.parent.resolve() != persona_dir or target.name not in {
    "rudeish-low.txt", "rudeish-medium.txt", "rudeish-high.txt", "nerdish.txt",
    "flirty.txt", "explicit.txt", "irritating.txt", "cute.txt", "femboy.txt", "normal.txt"
}:
    raise SystemExit("refusing unexpected persona path")
if target.is_symlink() or not target.is_file():
    raise SystemExit(f"expected an existing regular persona file: {target}")

before = target.stat()
payload = sys.stdin.buffer.read()
fd, temporary = tempfile.mkstemp(prefix=f".{target.name}.", dir=str(persona_dir))
try:
    with os.fdopen(fd, "wb") as stream:
        stream.write(payload)
        stream.flush()
        os.fsync(stream.fileno())
    os.chown(temporary, before.st_uid, before.st_gid)
    os.chmod(temporary, stat.S_IMODE(before.st_mode))
    os.replace(temporary, target)
    directory_fd = os.open(persona_dir, os.O_RDONLY)
    try:
        os.fsync(directory_fd)
    finally:
        os.close(directory_fd)
    print("OWAUA_PERSONA_SHA256=" + hashlib.sha256(target.read_bytes()).hexdigest())
finally:
    try:
        os.unlink(temporary)
    except FileNotFoundError:
        pass
'''

    command = [os.environ["RAILWAY_BIN"], "ssh"]
    for option, value in (
        ("--project", os.environ["RAILWAY_PROJECT"]),
        ("--environment", os.environ["RAILWAY_ENVIRONMENT"]),
        ("--service", os.environ["RAILWAY_SERVICE"]),
        ("--deployment-instance", os.environ["RAILWAY_DEPLOYMENT_INSTANCE"]),
    ):
        if value:
            command.extend((option, value))
    command.extend(("--", "python3", "-c", remote_writer))

    for model, local_path in files.items():
        remote_path = f"/app/{model_files[model]}"
        payload = local_path.read_bytes()
        expected = hashlib.sha256(payload).hexdigest()
        result = subprocess.run(
            [*command, remote_path], input=payload, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, check=False, timeout=90,
        )
        output = result.stdout.decode("utf-8", errors="replace")
        errors = result.stderr.decode("utf-8", errors="replace").strip()
        verified = [
            line.partition("=")[2]
            for line in output.splitlines()
            if line.startswith("OWAUA_PERSONA_SHA256=")
        ]
        if result.returncode != 0:
            detail = errors or output.strip() or "Railway SSH returned no details"
            raise RuntimeError(f"Railway update failed for {remote_path}: {detail}")
        if verified != [expected]:
            raise RuntimeError(
                f"Railway verification failed for {remote_path}; "
                "the remote SHA-256 did not match the local file"
            )
        print(f"Updated Railway {remote_path} (sha256={expected[:12]})")
    print(
        "Railway persona file(s) are byte-verified. The running bot reloads "
        "changed persona files on the next reply; a future deployment replaces "
        "container edits with the persona files in its source revision."
    )
    raise SystemExit(0)

deploy_path = Path(os.environ["DAKI_DEPLOY_SCRIPT"])
loader = importlib.machinery.SourceFileLoader("daki_deploy", str(deploy_path))
spec = importlib.util.spec_from_loader(loader.name, loader)
if spec is None:
    raise RuntimeError("could not load the Daki deployment client")
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)

config = module.load_config()
client = module.DakiClient(config["panel_url"], config["api_key"], config["server_id"])
if client.state() != "running":
    raise RuntimeError("Daki Bots server is not running; persona was not uploaded")

for model, local_path in files.items():
    remote_path = f"persona-test-bot/{model_files[model]}"
    payload = local_path.read_bytes()
    client.write_file(remote_path, payload)
    encoded = remote_path.replace("/", "%2F")
    readback = client.request(
        "GET", client.server_path(f"/files/contents?file=%2F{encoded}"), expect_json=False
    )
    if readback != payload:
        raise RuntimeError(f"Daki verification failed for {remote_path}")
    print(f"Updated Daki {remote_path} (sha256={hashlib.sha256(payload).hexdigest()[:12]})")
print("Local and Daki both have the updated persona(s). No restart is needed.")
PY
