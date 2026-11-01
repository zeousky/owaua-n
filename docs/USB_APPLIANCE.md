# Kirmy USB terminal appliance

This image is for an x86-64 UEFI computer with 16 GB RAM. It runs Debian 13
without a desktop. It boots entirely from USB and does not install onto the
computer's internal disk. Disable Secure Boot for this unsigned bootloader.

The bundled Qwen3 4B Q4_K_M model occupies 2,497,280,256 bytes. llama.cpp runs
it on six CPU threads, with one inference slot and an 8192-token context.
CPU inference works without NVIDIA drivers. The GTX 1660 Super is not used
for inference in this version. Model performance on the target computer
must be measured there; RAM headroom is not a speed guarantee.

The dashboard starts on the first terminal. Press C for offline terminal
chat, N for Ethernet/Wi-Fi setup, E to edit the private Discord token and
owner IDs, or B to start and enable the Discord bot. S stops and disables it.
Discord needs internet and a bot token; terminal chat needs neither. Enable
the Discord Message Content Intent for the bot in the Developer Portal.
The model starts automatically; Discord starts automatically on later boots
only after you enable it. Bot memory persists on the USB filesystem.
Terminal chat uses a separate memory database from Discord.

No private environment file or production memory is copied. The supplied
environment enables local-only inference and disables local AI tools.
There are no paid provider keys in the image. Existing bot features that
require cloud services or image understanding are not provided by this
text-only model. Music/network services still need internet as usual.

Use P to shut down before unplugging. The console auto-logs in as `owaua`,
which has sudo access for local appliance administration. Storage is not
encrypted: anyone with the USB can read a token you save. No SSH server is
installed. Keep the USB physically private.

## Build and validation

`scripts/usb/` contains the image Dockerfile, Linux configuration, terminal
dashboard, standalone Kirmy chat transport, and image assembly script.
Build files, model weights and the 12 GiB image belong under ignored
`build/usb/`. The image has a FAT UEFI boot partition and a writable ext4
root partition. Extra capacity on a larger USB is left unallocated.

Run `bash scripts/usb/build.sh` from the repository root with Docker running.
After authorizing erasure, `bash scripts/usb/flash-macos.sh /dev/diskN`
validates the external USB target and its identity, prompts for confirmation,
erases its old partition layout, writes the image, verifies every written byte
by SHA-256, and ejects the drive. The writer records progress in
`build/usb/flash-progress.json` and fails on write errors or mismatched readback. Recheck the disk number
immediately before flashing; it can change when devices are reconnected.

The Docker build context must contain `app/` (allowlisted Kirmy source,
requirements, personas and assets only), `appliance/` (configuration and
dashboard scripts), and `llama.tar.gz`. Do not copy `.env`, databases, model
caches or the entire working checkout into the Docker context.

The current model is published at
<https://huggingface.co/Qwen/Qwen3-4B-GGUF> and its SHA-256 is
`7485fe6f11af29433bc51cab58009521f205840f5b4ae3a32fa7f92e8534fdf5`.
The runtime comes from llama.cpp release `b11696`, Ubuntu x64 CPU archive.
Preserve both upstream licenses with the distribution.

Before flashing, validate the image and get explicit authorization for the
specific physical disk and erasure. A successful VM boot is separate from
verification on the Ryzen PC; a started bot process is separate from a
fresh Discord login. No Discord session is started during image building.
