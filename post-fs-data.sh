#!/system/bin/sh
#
# post-fs-data.sh - stop reqable-magisk's own mount stage and re-inject its CA
# certificate through NoMount instead.
#
# WHY
# ---
# reqable-magisk/post-fs-data.sh creates a tmpfs at /data/local/tmp/sys-ca-copy
# and bind-mounts it over /apex/com.android.conscrypt/cacerts in the init, zygote
# and zygote64 namespaces. That tmpfs is a real mount, and it survives in the
# init and zygote views while the app views are cleaned of it, so two processes
# end up with different mount tables. An integrity scan that compares
# /proc/<pid>/mountinfo across processes then reports "2 distinct views" where it
# expects 1.
#
# NoMount redirects paths at the VFS layer, so the same certificate can be served
# into both the legacy cacerts dir and the conscrypt APEX cacerts dir with no
# mount at all. Nothing to hide means nothing can diverge.
#
# This runs before the mount stages, so writing `disable` stops reqable-magisk's
# own scripts on this boot. `disable` also makes NoMount's metamount.sh skip the
# module, so this script adds both CA paths itself.

MODDIR=${0%/*}
REQABLE_DIR=/data/adb/modules/reqable-magisk
NM_BIN=/data/adb/modules/nomount/bin/nm

[ -x "$NM_BIN" ] || exit 0

# Keep reqable-magisk from running its own post-fs-data.sh / service.sh.
if [ -d "$REQABLE_DIR" ]; then
    : > "$REQABLE_DIR/disable"
fi

# If the reqable script already ran this boot, undo the tmpfs and the APEX bind
# in every namespace that has them, so no process sees a view the others lack.
umount_reqable() {
    for pid in 1 $(pidof zygote64) $(pidof zygote); do
        [ -n "$pid" ] || continue
        nsenter --mount=/proc/$pid/ns/mnt -- umount -l /data/local/tmp/sys-ca-copy 2>/dev/null
        nsenter --mount=/proc/$pid/ns/mnt -- umount -l /apex/com.android.conscrypt/cacerts 2>/dev/null
    done
    umount -l /data/local/tmp/sys-ca-copy 2>/dev/null
}

inject_certs() {
    [ -d "$REQABLE_DIR/system/etc/security/cacerts" ] || return 0
    for f in "$REQABLE_DIR"/system/etc/security/cacerts/*; do
        [ -f "$f" ] || continue
        name=${f##*/}
        "$NM_BIN" rule add "/system/etc/security/cacerts/$name" "$f"
        "$NM_BIN" rule add "/apex/com.android.conscrypt/cacerts/$name" "$f"
    done
}

umount_reqable
inject_certs
