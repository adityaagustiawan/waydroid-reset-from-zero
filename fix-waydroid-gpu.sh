#!/bin/bash
# Fix Waydroid GPU config and restart
set -e

echo "=== Stopping Waydroid ==="
waydroid session stop 2>/dev/null || true
sleep 2
systemctl stop waydroid-container.service 2>/dev/null || true
sleep 3

echo "=== Cleaning NVIDIA overlay ==="
umount /var/lib/waydroid/rootfs/vendor 2>/dev/null || true
umount /var/lib/waydroid/rootfs 2>/dev/null || true
rm -rf /var/lib/waydroid/overlay_rw/*
rm -rf /var/lib/waydroid/overlay_work/*
rm -rf /var/lib/waydroid/overlay/vendor/*
rm -rf /var/lib/waydroid/rootfs
rm -rf /var/lib/waydroid/nv/ 2>/dev/null || true

echo "=== Cleaning LXC NVIDIA artifacts ==="
sed -i '/waydroid-nvidia\|waydroid-venus\|nv\/guest\|venus\.sock\|nvidia/d' /var/lib/waydroid/lxc/waydroid/config_nodes 2>/dev/null || true

echo "=== Fixing GPU config ==="
sed -i 's/^ro.hardware.egl.*/ro.hardware.egl = angle/' /var/lib/waydroid/waydroid.cfg
sed -i 's/^ro.hardware.vulkan.*/ro.hardware.vulkan = virtio/' /var/lib/waydroid/waydroid.cfg
if ! grep -q "debug.sf.nobootanimation" /var/lib/waydroid/waydroid.cfg; then
    sed -i '/^\[properties\]/a debug.sf.nobootanimation = 1' /var/lib/waydroid/waydroid.cfg
fi

echo "=== Restarting ==="
systemctl start waydroid-container.service
sleep 5
waydroid session start 2>&1 &
sleep 30
waydroid show-full-ui 2>&1 &

echo ""
echo "Done! Check for Waydroid window."
echo "If Rust Mobile still crashes, run:"
echo "  waydroid prop set persist.waydroid.gpu.mode guest"
