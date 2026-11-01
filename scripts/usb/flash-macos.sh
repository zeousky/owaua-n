#!/bin/bash
# Destructive: requires a named external USB disk and explicit typed confirmation.
set -euo pipefail
cd "$(dirname "$0")/../.."
disk=${1:?Usage: bash scripts/usb/flash-macos.sh /dev/diskN}
image="$PWD/build/usb/owaua-usb-amd64.img"
[[ -f "$image" && "$disk" =~ ^/dev/disk[0-9]+$ ]] || exit 1
check_target() {
python3 - "$disk" "$image" "$1" <<'PY'
import json, os, pathlib, plistlib, subprocess, sys
info = plistlib.loads(subprocess.check_output(['diskutil', 'info', '-plist', sys.argv[1]]))
if (info.get('Internal', True) or not info.get('WholeDisk')
        or info.get('VirtualOrPhysical') != 'Physical'
        or info.get('BusProtocol') != 'USB'
        or not info.get('WritableMedia')
        or info.get('TotalSize', 0) < os.path.getsize(sys.argv[2])):
    raise SystemExit('Refusing: target must be a sufficiently large writable external USB disk')
identity = {key: info.get(key) for key in (
    'DeviceNode', 'MediaName', 'DeviceTreePath', 'TotalSize', 'BusProtocol')}
record = pathlib.Path('build/usb/flash-target.json')
if sys.argv[3] == 'record':
    record.write_text(json.dumps(identity))
elif json.loads(record.read_text()) != identity:
    raise SystemExit('USB identity changed; refusing to erase or write')
print('Target:', info.get('MediaName'), sys.argv[1], info.get('TotalSize'), 'bytes')
PY
}
check_target record
(cd build/usb && shasum -a 256 -c owaua-usb-amd64.img.sha256)
echo "This permanently erases EVERY partition and file on $disk."
read -r -p "Type ERASE $disk to proceed: " confirmation
[[ "$confirmation" == "ERASE $disk" ]] || exit 1
sudo -v
check_target compare
echo 'Erasing the existing USB partition layout...'
diskutil eraseDisk FAT32 OWAUA_TMP MBRFormat "$disk"
diskutil unmountDisk "$disk"
check_target compare
raw="/dev/r${disk#/dev/}"
expected=$(awk 'NR==1 {print $1}' build/usb/owaua-usb-amd64.img.sha256)
sudo python3 scripts/usb/write-image.py "$image" "$raw" "$expected" build/usb/flash-progress.json
diskutil eject "$disk"
