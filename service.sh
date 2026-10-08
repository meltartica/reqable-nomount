#!/system/bin/sh
#
# service.sh - re-assert the CA redirects once the system has settled.
#
# post-fs-data.sh normally wins the race, but KernelSU builds its module list
# before a freshly written `disable` lands, so on the first boot after install
# (or after reqable-magisk updates) the reqable mount stage can still run. This
# late pass cleans up any leftover and makes sure both CA paths are redirected.

MODDIR=${0%/*}
REQABLE_DIR=/data/adb/modules/reqable-magisk
NM_BIN=/data/adb/modules/nomount/bin/nm

[ -f "$MODDIR/disable" ] && exit 0
[ -x "$NM_BIN" ] || exit 0
[ -d "$REQABLE_DIR" ] || exit 0

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 1; done

for pid in 1 $(pidof zygote64) $(pidof zygote); do
    [ -n "$pid" ] || continue
    nsenter --mount=/proc/$pid/ns/mnt -- umount -l /data/local/tmp/sys-ca-copy 2>/dev/null
done
umount -l /data/local/tmp/sys-ca-copy 2>/dev/null

for f in "$REQABLE_DIR"/system/etc/security/cacerts/*; do
    [ -f "$f" ] || continue
    name=${f##*/}
    "$NM_BIN" rule add "/system/etc/security/cacerts/$name" "$f"
    "$NM_BIN" rule add "/apex/com.android.conscrypt/cacerts/$name" "$f"
done
