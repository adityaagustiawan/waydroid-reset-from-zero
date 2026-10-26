#!/usr/bin/env bash
set -e

echo "============================================"
echo "  WAYDROID ARM TRANSLATION (libhoudini)"
echo "============================================"
echo ""

if ! systemctl is-active --quiet waydroid-container.service; then
  echo "[!] waydroid-container.service tidak aktif"
  echo "    Jalankan: sudo systemctl start waydroid-container.service"
  exit 1
fi

if [ ! -d ~/waydroid_script ]; then
  echo "[*] Clone casualsnek/waydroid_script..."
  git clone https://github.com/casualsnek/waydroid_script.git ~/waydroid_script
else
  echo "[*] Update waydroid_script..."
  git -C ~/waydroid_script pull --ff-only 2>/dev/null || git -C ~/waydroid_script pull --rebase 2>/dev/null || true
fi

cd ~/waydroid_script
echo "[*] Setup environment..."
python3 -m venv venv 2>/dev/null || true
source venv/bin/activate
pip install --upgrade pip >/dev/null 2>&1
pip install -r requirements.txt 2>/dev/null || pip install requests tqdm >/dev/null 2>&1

echo ""
echo "[*] Menjalankan installer..."
echo "    PENTING: Pilih 'Install libhoudini' saat diminta"
echo "    Ikuti petunjuk di menu"
echo ""
sudo python3 main.py

echo ""
echo "============================================"
echo "  INSTALASI ARM TRANSLATION SELESAI"
echo "============================================"
echo "Restart agar bridge aktif:"
echo "  waydroid session stop 2>/dev/null || true"
echo "  sudo systemctl restart waydroid-container.service"
echo "  sleep 10"
echo "  waydroid session start &"
echo "  waydroid show-full-ui"
echo "============================================"
