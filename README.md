# Waydroid Reset From Zero (ARM Game Fix)

Reset Waydroid bersih dari 0 biar bisa jalanin ARM/ARM64 game di Waydroid.

## Files
- `fix-waydroid-zero-reset.sh` - Wipe total /var/lib/waydroid + ~/.local/share/waydroid, init VANILLA, fix config
- `waydroid-arm-translation.sh` - Install libhoudini via https://github.com/casualsnek/waydroid_script
- `fix-waydroid-gpu.sh` - Fix GPU config
- `fix-waydroid-full.sh`, `fix-waydroid3.sh`, `fix-waydroid2.sh`, `fix-waydroid.sh` - Script lama (backup)

## Urutan
```bash
cd ~/Projects/waydroid-reset-from-zero
sudo ./fix-waydroid-zero-reset.sh
./waydroid-arm-translation.sh
waydroid session stop 2>/dev/null; sudo systemctl restart waydroid-container.service; sleep 10; waydroid session start &
waydroid show-full-ui
```

## Notes
- Butuh `gh` login (udah ada)
- Install libhoudini pas waydroid_script jalan
