#!/bin/bash
# Build an appliance image locally. Never writes to a physical disk.
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p build/usb/context/app build/usb/context/appliance
python3 - <<'PY'
import pathlib
import shutil
import subprocess

out = pathlib.Path('build/usb/context/app')
shutil.rmtree(out)
out.mkdir()
for name in subprocess.check_output(['git', 'ls-files', '-z']).decode().split('\0'):
    source = pathlib.Path(name)
    if not name or not source.is_file():
        continue
    if not (name.startswith(('src/', 'personas/', 'pfps/', 'banners/'))
            or name in ('requirements.txt', 'LICENSE', 'VERSION')):
        continue
    target = out / name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
for name in ('configure-system.sh', 'dashboard.py', 'chat.py'):
    shutil.copy2('scripts/usb/' + name, 'build/usb/context/appliance/' + name)
shutil.copy2('scripts/usb/Dockerfile', 'build/usb/context/Dockerfile')
PY
if [[ ! -f build/usb/Qwen3-4B-Q4_K_M.gguf ]]; then
  curl -fL --retry 3 -o build/usb/Qwen3-4B-Q4_K_M.gguf \
    https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf
fi
if [[ ! -f build/usb/llama.tar.gz ]]; then
  curl -fL --retry 3 -o build/usb/llama.tar.gz \
    https://github.com/ggml-org/llama.cpp/releases/download/b11696/llama-b11696-bin-ubuntu-x64.tar.gz
fi
python3 - <<'PY'
import hashlib
for path, expected in (
    ('build/usb/Qwen3-4B-Q4_K_M.gguf', '7485fe6f11af29433bc51cab58009521f205840f5b4ae3a32fa7f92e8534fdf5'),
    ('build/usb/llama.tar.gz', '6a04629ca5265eb4c5c7d6edec8d6fa429e7e7da2de1cd5d5e357a492fc8f802'),
):
    digest = hashlib.sha256()
    with open(path, 'rb') as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(block)
    if digest.hexdigest() != expected:
        raise SystemExit('Checksum failed: ' + path)
    print('Checksum verified:', path)
PY
cp build/usb/llama.tar.gz build/usb/context/
curl -fL --retry 3 -o build/usb/LICENSE-Qwen3.txt \
  https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/main/LICENSE
docker build --platform linux/amd64 -t owaua-usb:2026-10-16 build/usb/context
container=$(docker create --platform linux/amd64 owaua-usb:2026-10-16)
trap 'docker rm "$container" >/dev/null 2>&1 || true' EXIT
docker export "$container" > build/usb/rootfs.tar
docker run --rm --platform linux/amd64 \
  -v "$PWD/build/usb:/output" -v "$PWD/scripts/usb:/builder:ro" \
  owaua-usb:2026-10-16 bash /builder/make-image.sh
python3 - <<'PY'
import hashlib
from pathlib import Path
p = Path('build/usb/owaua-usb-amd64.img')
h = hashlib.sha256()
with p.open('rb') as handle:
    for block in iter(lambda: handle.read(4 * 1024 * 1024), b''):
        h.update(block)
p.with_suffix('.img.sha256').write_text(h.hexdigest() + '  ' + p.name + '\n')
print('Image checksum recorded:', h.hexdigest())
PY
