#!/bin/bash
set -e

# Reset vendor datetime so init doesn't skip download
sed -i 's/^vendor_datetime.*/vendor_datetime = 0/' /var/lib/waydroid/waydroid.cfg

# Reinit - images are cached, should be fast
/usr/bin/waydroid init -f -s VANILLA 2>&1

# Regenerate container config
waydroid upgrade -o 2>&1 || true

echo ""
echo "=== Config ==="
head -10 /var/lib/waydroid/waydroid.cfg
echo ""
echo "=== Images ==="
ls -la /var/lib/waydroid/images/

echo ""
echo "Now run: waydroid session start"
echo "Then: waydroid show-full-ui"
