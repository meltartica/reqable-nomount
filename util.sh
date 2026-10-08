#!/system/bin/sh
#
# util.sh - shared helpers.
#
# The status shown in the module list is the target module's own description
# line, so it is rewritten in place and the original module.prop is kept beside
# it as `err`. This mirrors morphe-nomount's set_morphe_desc.

# Rewrite a module's description to show status in the module list.
set_reqable_desc() {
    _sd_path="$1"
    _sd_msg="$2"
    [ -f "$_sd_path/module.prop" ] || return 0
    if [ ! -f "$_sd_path/err" ]; then
        cp -f "$_sd_path/module.prop" "$_sd_path/err"
    fi
    sed -i "s|^des.*|description=⚠️ ${_sd_msg}|g" "$_sd_path/module.prop"
}

# Restore the module.prop saved by set_reqable_desc.
restore_reqable_desc() {
    _rd_path="$1"
    [ -f "$_rd_path/err" ] || return 0
    mv -f "$_rd_path/err" "$_rd_path/module.prop"
}
