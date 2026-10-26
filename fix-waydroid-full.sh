#!/bin/bash
# Full Waydroid fix: GPU config + move to /home + free root space
set -e

echo "============================================"
echo "  Waydroid Full Fix Script"
echo "============================================"
echo ""

# Step 1: Stop waydroid
echo "=== Step 1: Stopping Waydroid ==="
waydroid session stop 2>/dev/null || true
sleep 2
systemctl stop waydroid-container.service 2>/dev/null || true
sleep 3
echo "Stopped."
echo ""

# Step 2: Fix GPU config (angle + virtio + nobootanimation)
echo "=== Step 2: Fixing GPU config ==="
sed -i 's/^ro.hardware.egl.*/ro.hardware.egl = angle/' /var/lib/waydroid/waydroid.cfg
sed -i 's/^ro.hardware.vulkan.*/ro.hardware.vulkan = virtio/' /var/lib/waydroid/waydroid.cfg
# Add debug.sf.nobootanimation if missing
if ! grep -q "debug.sf.nobootanimation" /var/lib/waydroid/waydroid.cfg; then
    sed -i '/^\[properties\]/a debug.sf.nobootanimation = 1' /var/lib/waydroid/waydroid.cfg
fi
echo "GPU config updated: EGL=angle, Vulkan=virtio, nobootanimation=1"
echo ""

# Step 3: Clean NVIDIA overlay artifacts
echo "=== Step 3: Cleaning NVIDIA overlay ==="
umount /var/lib/waydroid/rootfs/vendor 2>/dev/null || true
umount /var/lib/waydroid/rootfs 2>/dev/null || true
rm -rf /var/lib/waydroid/overlay_rw/*
rm -rf /var/lib/waydroid/overlay_work/*
rm -rf /var/lib/waydroid/overlay/vendor/*
rm -rf /var/lib/waydroid/rootfs
rm -rf /var/lib/waydroid/nv/ 2>/dev/null || true
echo "Overlay cleaned."
echo ""

# Step 4: Remove NVIDIA bind mounts from LXC config
echo "=== Step 4: Cleaning LXC config ==="
if [ -f /var/lib/waydroid/lxc/waydroid/config_nodes ]; then
    sed -i '/waydroid-nvidia\|waydroid-venus\|nv\/guest\|venus\.sock\|nvidia/d' /var/lib/waydroid/lxc/waydroid/config_nodes
fi
echo "LXC config cleaned."
echo ""

# Step 5: Move waydroid to /home
echo "=== Step 5: Moving Waydroid data to /home ==="
TARGET="/home/kar98k/waydroid-data"

if [ -d "$TARGET" ]; then
    echo "Target $TARGET already exists, checking..."
else
    mkdir -p "$TARGET"
    # Move images
    mv /var/lib/waydroid/images "$TARGET/images" 2>/dev/null || true
    # Move data (user data is already at ~/.local/share/waydroid)
    echo "Data moved to $TARGET"
fi

# Create symlink if not already done
if [ ! -L /var/lib/waydroid/images ]; then
    ln -sf "$TARGET/images" /var/lib/waydroid/images
    echo "Symlink created: /var/lib/waydroid/images -> $TARGET/images"
fi

echo "Root space freed. Current root usage:"
df -h / | tail -1
echo ""

# Step 6: Regenerate container config
echo "=== Step 6: Regenerating container config ==="
waydroid upgrade -o 2>&1 || true
echo ""

# Step 7: Restart
echo "=== Step 7: Restarting Waydroid ==="
systemctl start waydroid-container.service
sleep 5

echo "Starting session..."
waydroid session start 2>&1 &
sleep 30

echo ""
echo "=== Launching UI ==="
waydroid show-full-ui 2>&1 &

echo ""
echo "============================================"
echo "  Done! Check for Waydroid window."
echo "============================================"
echo ""
echo "If Rust Mobile still crashes, try:"
echo "  waydroid prop set persist.waydroid.gpu.mode guest"
echo "  waydroid prop set ro.hardware.vulkan virtio"
echo ""
echo "To install Rust Mobile:"
echo "  Open Play Store in Waydroid and search 'Rust Mobile'"
