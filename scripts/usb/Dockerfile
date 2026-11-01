FROM debian:trixie-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d
RUN apt-get update && apt-get install -y --no-install-recommends \
    linux-image-amd64 initramfs-tools systemd-sysv udev dbus sudo \
    network-manager wpasupplicant wireless-regdb firmware-linux-free \
    console-setup kbd locales ca-certificates curl nano less procps iproute2 \
    python3 python3-venv ffmpeg libgomp1 libcurl4t64 \
    grub-efi-amd64-bin grub-common dosfstools e2fsprogs mtools fdisk qemu-system-x86 ovmf \
    && rm -rf /var/lib/apt/lists/*
RUN sed -i 's/Components: main/Components: main non-free-firmware/' /etc/apt/sources.list.d/debian.sources \
    && apt-get update && apt-get install -y --no-install-recommends \
       firmware-realtek firmware-iwlwifi firmware-mediatek firmware-atheros \
    && rm -rf /var/lib/apt/lists/*
COPY app /opt/owaua
RUN python3 -m venv /opt/owaua/.venv && /opt/owaua/.venv/bin/pip install --no-cache-dir -r /opt/owaua/requirements.txt
COPY llama.tar.gz /tmp/llama.tar.gz
RUN mkdir /opt/llama && tar -xzf /tmp/llama.tar.gz -C /opt/llama --strip-components=1 && rm /tmp/llama.tar.gz
COPY appliance /tmp/appliance
RUN bash /tmp/appliance/configure-system.sh && rm -rf /tmp/appliance
CMD ["/bin/bash"]
