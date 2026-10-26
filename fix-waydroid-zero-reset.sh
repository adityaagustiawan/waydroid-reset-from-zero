#!/usr/bin/env bash
set -e

echo "============================================"
echo "  WAYDROID TOTAL RESET FROM ZERO"
echo "============================================"
echo "[!] AKAN MENGHAPUS SEMUA DATA WAYDROID"
echo "    - /var/lib/waydroid/"
echo "    - ~/.local/share/waydroid/"
echo ""
read -p "Lanjutkan? (y/N): " CONF
[[ "$CONF" =~ ^[Yy]$ ]] || { echo "Dibatalkan."; exit 1; }

echo ""
echo "[1/8] Stop semua..."
waydroid session stop 2>/dev/null || true
sudo systemctl stop waydroid-container.service 2>/dev/null || true
sudo systemctl disable waydroid-container.service 2>/dev/null || true
sleep 3

echo "[2/8] Unmount..."
sudo umount -R /var/lib/waydroid/rootfs 2>/dev/null || true
sudo umount /var/lib/waydroid/rootfs/vendor 2>/dev/null || true
sleep 2

echo "[3/8] Hapus data lama..."
sudo rm -rf /var/lib/waydroid
rm -rf ~/.local/share/waydroid
rm -rf ~/.cache/waydroid 2>/dev/null || true
rm -rf ~/.local/share/applications/*waydroid* 2>/dev/null || true

echo "[4/8] Buat direktori baru..."
sudo mkdir -p /var/lib/waydroid/{images,lxc/waydroid,overlay,overlay_rw,overlay_work,cache_http,host-permissions}
sudo chown -R root:root /var/lib/waydroid
sudo chmod 755 /var/lib/waydroid

echo "[5/8] Init Waydroid VANILLA dari nol..."
sudo waydroid init -f -s VANILLA

echo "[6/8] Fix config buat Hyprland + ARM..."
CFG="/var/lib/waydroid/waydroid.cfg"
sudo sed -i 's/^ro.hardware.egl.*/ro.hardware.egl = angle/' "$CFG"
sudo sed -i 's/^ro.hardware.vulkan.*/ro.hardware.vulkan = virtio/' "$CFG"
grep -q "debug.sf.nobootanimation" "$CFG" || sudo sed -i '/^\[properties\]/a debug.sf.nobootanimation = 1' "$CFG"
grep -q "persist.waydroid.use_subsurface" "$CFG" || echo "persist.waydroid.use_subsurface = true" | sudo tee -a "$CFG" >/dev/null
grep -q "ro.enable.native.bridge.exec" "$CFG" || cat >> "$CFG" << 'PROPS'

# ARM translation
ro.product.cpu.abilist = x86_64,x86,arm64-v8a,armeabi-v7a,armeabi
ro.product.cpu.abilist32 = x86,armeabi-v7a,armeabi
ro.product.cpu.abilist64 = x86_64,arm64-v8a
ro.enable.native.bridge.exec = 1
ro.dalvik.vm.native.bridge = libhoudini.so
ro.dalvik.vm.isa.arm = x86
ro.dalvik.vm.isa.arm64 = x86_64
PROPS

echo "[7/8] Enable & start container..."
sudo systemctl enable --now waydroid-container.service
sleep 10

echo "[8/8] Selesai!"
echo ""
echo "============================================"
echo "  RESET DARI 0 SELESAI"
echo "============================================"
echo "Langkah selanjutnya:"
echo "  1. Install ARM translation: ./waydroid-arm-translation.sh"
echo "  2. Start: waydroid session start & waydroid show-full-ui"
echo "============================================"
