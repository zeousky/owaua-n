#!/bin/bash
# Run inside the prepared Linux builder. Writes regular files only, never host disks.
set -euo pipefail
cd /output
mkdir -p /work/rootfs
tar -xpf rootfs.tar -C /work/rootfs
rm -f /work/rootfs/.dockerenv /work/rootfs/run/.containerenv /work/rootfs/run/systemd/container
echo owaua > /work/rootfs/etc/hostname
printf '127.0.0.1 localhost\n127.0.1.1 owaua\n' > /work/rootfs/etc/hosts
rm -f /work/rootfs/etc/resolv.conf
ln -s /run/NetworkManager/resolv.conf /work/rootfs/etc/resolv.conf
cp Qwen3-4B-Q4_K_M.gguf /work/rootfs/opt/models/
cp LICENSE-Qwen3.txt /work/rootfs/opt/models/
chown 1000:1000 /work/rootfs/opt/models/*
mkdir -p /work/efi/EFI/BOOT
cat > /work/grub.cfg <<'EOF'
search --no-floppy --label OWAUA_ROOT --set=root
set timeout=3
menuentry 'Kirmy - local AI terminal' {
    linux /vmlinuz root=LABEL=OWAUA_ROOT rootwait rw quiet console=ttyS0,115200 console=tty0
    initrd /initrd.img
}
menuentry 'Kirmy - boot diagnostics' {
    linux /vmlinuz root=LABEL=OWAUA_ROOT rootwait rw console=tty0 console=ttyS0,115200
    initrd /initrd.img
}
EOF
grub-mkstandalone -O x86_64-efi -o /work/efi/EFI/BOOT/BOOTX64.EFI \
    --modules='part_msdos part_gpt fat ext2 normal linux search search_label configfile' \
    'boot/grub/grub.cfg=/work/grub.cfg'
truncate -s 256M /work/efi.img
mkfs.vfat -n OWAUA_EFI /work/efi.img
mcopy -s -i /work/efi.img /work/efi/EFI ::/
truncate -s 12031M /work/root.img
mkfs.ext4 -F -L OWAUA_ROOT -m 1 -d /work/rootfs /work/root.img
rm -f owaua-usb-amd64.img owaua-usb-amd64.img.sha256
truncate -s 12288M owaua-usb-amd64.img
printf 'label: dos\nunit: sectors\n\nstart=2048,size=524288,type=ef,bootable\nstart=526336,type=83\n' | sfdisk owaua-usb-amd64.img
dd if=/work/efi.img of=owaua-usb-amd64.img bs=1M seek=1 conv=notrunc,sparse status=progress
dd if=/work/root.img of=owaua-usb-amd64.img bs=1M seek=257 conv=notrunc,sparse status=progress
e2fsck -fn /work/root.img
echo 'IMAGE_READY: UEFI x86-64, Secure Boot must be disabled, 12 GiB writable image.'
