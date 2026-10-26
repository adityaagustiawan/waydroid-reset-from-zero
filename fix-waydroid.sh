#!/bin/bash
# Fix waydroid - remove NVIDIA overlay and reinitialize clean VANILLA images
set -e

echo "=== Stopping waydroid ==="
waydroid session stop 2>/dev/null || true
sleep 2

echo "=== Cleaning NVIDIA overlay ==="
rm -rf /var/lib/waydroid/overlay_rw/*
rm -rf /var/lib/waydroid/overlay_work/*
rm -rf /var/lib/waydroid/overlay/vendor/*
rm -rf /var/lib/waydroid/rootfs 2>/dev/null || true
rm -rf /var/lib/waydroid/overlay_work/system 2>/dev/null || true
rm -rf /var/lib/waydroid/overlay_work/vendor 2>/dev/null || true

echo "=== Cleaning NVIDIA guest libs ==="
rm -rf /var/lib/waydroid/nv/

echo "=== Removing NVIDIA bind mounts from LXC config ==="
if [ -f /var/lib/waydroid/lxc/waydroid/config_nodes ]; then
    sed -i '/waydroid-nvidia\|waydroid-venus\|nv\/guest\|venus\.sock/d' /var/lib/waydroid/lxc/waydroid/config_nodes
fi

echo "=== Writing clean waydroid.cfg ==="
cat > /var/lib/waydroid/waydroid.cfg << 'CFGEOF'
[waydroid]
arch = x86_64
vendor_type = MAINLINE
system_datetime = 1775215493
vendor_datetime = 1777409843
suspend_action = none
mount_overlays = True
auto_adb = False
images_path = /var/lib/waydroid/images
binder = anbox-binder
vndbinder = anbox-vndbinder
hwbinder = anbox-hwbinder
system_ota = https://ota.waydro.id/system/lineage/waydroid_x86_64/VANILLA.json
vendor_ota = https://ota.waydro.id/vendor/waydroid_x86_64/MAINLINE.json
binder_protocol = aidl3
service_manager_protocol = aidl3
drm_device = /dev/dri/renderD128

[properties]
waydroid.display_width = 1920
waydroid.display_height = 1080
ro.sf.lcd_density = 160
ro.product.cpu.abilist = x86_64,x86,arm64-v8a,armeabi-v7a,armeabi
ro.product.cpu.abilist32 = x86,armeabi-v7a,armeabi
ro.product.cpu.abilist64 = x86_64,arm64-v8a
ro.dalvik.vm.native.bridge = libhoudini.so
ro.enable.native.bridge.exec = 1
ro.dalvik.vm.isa.arm = x86
ro.dalvik.vm.isa.arm64 = x86_64
ro.hardware.egl = angle
ro.hardware.vulkan = virtio
debug.hwui.renderer = skiagl
debug.renderengine.backend = skiaglthreaded
debug.sf.nobootanimation = 1
persist.waydroid.use_subsurface = true
ro.surface_flinger.vsync_event_phase_offset_ns = 0
ro.surface_flinger.vsync_sf_event_phase_offset_ns = 0
ro.surface_flinger.max_frame_buffer_acquired_buffers = 3
persist.waydroid.refresh_rate = 60
CFGEOF

echo "=== Regenerating container config ==="
waydroid upgrade -o 2>/dev/null || true

echo "=== Restarting container ==="
systemctl restart waydroid-container.service
sleep 5

echo "=== Starting session ==="
waydroid session start 2>&1 &
sleep 20

echo "=== Launching UI ==="
waydroid show-full-ui 2>&1 &

echo ""
echo "Done! Check for Waydroid window."
echo "If it works, run: systemctl --user disable --now wd-venus.service"
