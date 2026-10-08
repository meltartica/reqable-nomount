#!/system/bin/sh

NM_BIN="/data/adb/modules/nomount/bin/nm"
REQABLE_DIR="/data/adb/modules/reqable-magisk"

ui_print "- Checking NoMount dependencies..."

if [ ! -f "$NM_BIN" ]; then
    ui_print "! Error: NoMount binary not found at $NM_BIN"
    ui_print "! Please install the NoMount metamodule first."
    abort ""
fi

# `nm version` is NoMount's documented liveness test.
if ! "$NM_BIN" version >/dev/null 2>&1; then
    ui_print "! Error: NoMount binary execution failed."
    ui_print "! Is the kernel module compiled and loaded?"
    abort ""
fi

ui_print "- NoMount is installed and active."

if [ ! -d "$REQABLE_DIR/system/etc/security/cacerts" ]; then
    ui_print "! No Reqable certificate module found."
    ui_print "  Install Reqable's Certificate Installer module first,"
    ui_print "  then flash this module."
    abort ""
fi

# Stop reqable-magisk's own mount stage immediately.
: > "$REQABLE_DIR/disable"

chmod +x "$MODPATH/post-fs-data.sh" "$MODPATH/service.sh" "$MODPATH/uninstall.sh"

ui_print "- Disabled reqable-magisk's mount stage."
ui_print "- Done"
