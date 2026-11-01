"""Offline terminal transport for Kirmy's existing persona and memory code."""
import asyncio
import os
import sys
import time
import uuid
from pathlib import Path

ROOT = Path('/opt/owaua')
os.environ['OWAUA_ENV_FILE'] = str(ROOT / '.env')
os.environ['OWAUA_LOCAL_ONLY'] = '1'
os.environ['OWAUA_LOCAL_ENABLE_TOOLS'] = '0'
sys.path.insert(0, str(ROOT / 'src/owaua'))

import httpx
from ask import ask
from memory import MemoryStore


async def main():
    memory = MemoryStore(ROOT / 'data/terminal.sqlite3')
    print('Kirmy local chat. /quit exits. Text only; no internet required.')
    async with httpx.AsyncClient() as http:
        while True:
            try:
                prompt = input('\nYou: ').strip()
            except (EOFError, KeyboardInterrupt):
                break
            if prompt == '/quit':
                break
            if not prompt:
                continue
            try:
                reply = await ask(http, memory, event_id=str(uuid.uuid4()),
                    scope_id='terminal', user_id='terminal', server_id='terminal',
                    prompt=prompt, image_urls=[], persona='normal',
                    created_at=time.time(), use_history=True)
                print('\nKirmy:', reply or '(no reply)')
            except Exception as exc:  # noqa: BLE001 - keep the interactive console alive
                print(f'Local chat error: {exc}')


if __name__ == '__main__':
    asyncio.run(main())
