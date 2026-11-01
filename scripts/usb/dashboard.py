"""Console-only USB appliance dashboard; never displays credentials or logs."""
import curses
import json
import os
import subprocess
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path('/opt/owaua')


def run(*args):
    return subprocess.run(args, check=False)


def status(unit):
    return subprocess.run(['systemctl', 'is-active', unit], capture_output=True,
                          text=True, check=False).stdout.strip()


def screen(stdscr):
    curses.curs_set(0)
    stdscr.timeout(2000)
    while True:
        stdscr.erase()
        mem = dict(line.split(':', 1) for line in Path('/proc/meminfo').read_text().splitlines())
        available = int(mem['MemAvailable'].split()[0]) / 1048576
        total = int(mem['MemTotal'].split()[0]) / 1048576
        try:
            with urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=1) as r:
                ready = json.load(r).get('status', 'unknown')
        except (OSError, ValueError, urllib.error.URLError):
            ready = 'loading / unavailable'
        bot = status('owaua-bot')
        login = 'No confirmed login in this bot run'
        path = ROOT / 'data/readiness.json'
        if bot == 'active' and path.exists():
            try:
                login = 'Login recorded: ' + json.loads(path.read_text())['logged_in_as']
            except (OSError, ValueError, KeyError):
                pass
        rows = ['KIRMY USB | Debian terminal appliance', '',
                'AI: Qwen3 4B Q4_K_M | CPU: 6 threads | context: 8192',
                'Cloud API keys: absent | inference: local only',
                f'Model: {status("owaua-model")} | health: {ready}',
                f'Discord process: {bot} | {login}',
                'A recorded login does not confirm current Discord connectivity.',
                f'RAM available: {available:.1f} / {total:.1f} GiB',
                f'Load: {os.getloadavg()[0]:.2f} | USB storage and memory persist', '',
                '[C] Terminal chat    [E] Configure Discord token / owner IDs',
                '[B] Start bot        [S] Stop bot',
                '[N] Network setup    [T] Shell',
                '[L] Bot logs         [M] Model logs',
                '[P] Power off        [R] Reboot', '',
                'Use Ethernet or Network setup for Discord. Local chat works offline.',
                'Shut down here before unplugging. No internal disk installation.']
        height, width = stdscr.getmaxyx()
        for i, row in enumerate(rows[:height-1]):
            stdscr.addnstr(i, 0, row, max(0, width-1))
        stdscr.refresh()
        key = stdscr.getch()
        if key < 0:
            continue
        key = chr(key).lower() if key < 256 else ''
        if key not in 'cebsntl mpr'.replace(' ', ''):
            continue
        curses.def_prog_mode()
        curses.endwin()
        if key == 'c':
            run('/opt/owaua/.venv/bin/python', str(ROOT/'scripts/usb-chat.py'))
        elif key == 'e':
            print('Set DISCORD_TOKEN and BOT_OWNER_IDS. Keep local-only mode enabled.')
            print('The token is private; do not share this screen.')
            run('nano', str(ROOT/'.env'))
        elif key == 'b':
            if any(line.startswith('DISCORD_TOKEN=') and line.split('=', 1)[1].strip()
                   for line in (ROOT/'.env').read_text().splitlines()):
                run('sudo', 'systemctl', 'enable', '--now', 'owaua-bot')
            else:
                input('Configure the Discord token first. Press Enter.')
        elif key == 's':
            run('sudo', 'systemctl', 'disable', '--now', 'owaua-bot')
        elif key == 'n':
            run('sudo', 'nmtui')
        elif key == 't':
            print('Type exit to return to the dashboard.')
            run('/bin/bash')
        elif key in ('l', 'm'):
            run('journalctl', '-u', 'owaua-bot' if key == 'l' else 'owaua-model', '-n', '80')
        elif key in ('p', 'r') and input(
            'Type YES to '+('power off' if key == 'p' else 'reboot')+': '
        ) == 'YES':
            run('sudo', 'systemctl', 'poweroff' if key == 'p' else 'reboot')
        curses.reset_prog_mode()
        stdscr.timeout(2000)


if __name__ == '__main__':
    curses.wrapper(screen)
