#!/system/bin/sh
#
# uninstall.sh - drop the CA redirects, restore reqable-magisk's own
# description, and hand its mount stage back, so removing this module leaves
# reqable-magisk working on its own.

MODDIR=${MODDIR:-${0%/*}}
REQABLE_DIR=/data/adb/modules/reqable-magisk
NM_BIN=/data/adb/modules/nomount/bin/nm

if [ -d "$REQABLE_DIR" ]; then
    . "$MODDIR/util.sh"
    restore_reqable_desc "$REQABLE_DIR"
    rm -f "$REQABLE_DIR/disable"
fi

[ -x "$NM_BIN" ] || exit 0

for f in "$REQABLE_DIR"/system/etc/security/cacerts/*; do
    [ -f "$f" ] || continue
    name=${f##*/}
    "$NM_BIN" rule del "/system/etc/security/cacerts/$name" 2>/dev/null
    "$NM_BIN" rule del "/apex/com.android.conscrypt/cacerts/$name" 2>/dev/null
done
