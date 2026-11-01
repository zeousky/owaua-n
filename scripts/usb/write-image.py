"""Write an authorized USB image, then verify every byte read from the device."""
import argparse
import hashlib
import json
import os
import re
import time
from pathlib import Path

CHUNK = 1024 * 1024


def image_digest(path):
    digest = hashlib.sha256()
    with open(path, 'rb') as handle:
        for block in iter(lambda: handle.read(CHUNK), b''):
            digest.update(block)
    return digest.hexdigest()


def save_progress(path, phase, completed, total, started):
    state = {'phase': phase, 'bytes': completed, 'total': total,
             'percent': round(completed * 100 / total, 1),
             'elapsed_seconds': round(time.monotonic() - started, 1)}
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(state) + '\n')
    temporary.replace(path)
    print(f'{phase}: {completed / total:.1%} ({completed}/{total} bytes)', flush=True)


def write_and_verify(image, target, expected, progress):
    total = image.stat().st_size
    started = time.monotonic()
    completed = 0
    save_progress(progress, 'writing', 0, total, started)
    descriptor = os.open(target, os.O_WRONLY)
    try:
        with image.open('rb') as source:
            while block := source.read(CHUNK):
                remaining = memoryview(block)
                while remaining:
                    count = os.write(descriptor, remaining)
                    if count <= 0:
                        raise OSError('USB write returned no bytes')
                    remaining = remaining[count:]
                completed += len(block)
                if completed % (32 * CHUNK) == 0 or completed == total:
                    save_progress(progress, 'writing', completed, total, started)
        os.fsync(descriptor)
    finally:
        os.close(descriptor)
    digest = hashlib.sha256()
    completed = 0
    started = time.monotonic()
    save_progress(progress, 'verifying', 0, total, started)
    with open(target, 'rb', buffering=0) as device:
        while completed < total:
            block = device.read(min(CHUNK, total - completed))
            if not block:
                raise OSError('USB disconnected or returned a short read')
            digest.update(block)
            completed += len(block)
            if completed % (32 * CHUNK) == 0 or completed == total:
                save_progress(progress, 'verifying', completed, total, started)
    if digest.hexdigest() != expected:
        raise OSError('USB verification FAILED: checksum does not match the image')
    save_progress(progress, 'verified', total, total, started)
    print('USB bytes verified; SHA-256: ' + expected, flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('image', type=Path)
    parser.add_argument('target')
    parser.add_argument('expected')
    parser.add_argument('progress', type=Path)
    args = parser.parse_args()
    if not re.fullmatch(r'/dev/rdisk[0-9]+', args.target):
        parser.error('Only an explicitly selected macOS whole raw disk is accepted')
    try:
        if image_digest(args.image) != args.expected:
            raise OSError('Source image checksum changed; refusing to write')
        write_and_verify(args.image, args.target, args.expected, args.progress)
    except OSError as exc:
        args.progress.write_text(json.dumps({'phase': 'failed', 'error': str(exc)}) + '\n')
        raise SystemExit(str(exc)) from exc


if __name__ == '__main__':
    main()
