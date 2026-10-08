# Changelog

## v1.0.1

Show status on the Reqable module, like morphe-nomount does.

- Rewrites `reqable-magisk`'s `module.prop` description to
  `⚠️ Keep disabled. Injected natively via NoMount.` so the module list explains
  why it is switched off. The original `module.prop` is kept beside it as `err`.
- `uninstall.sh` restores that original `module.prop` and re-enables the module,
  so the description does not stay rewritten after removal.

## v1.0.0

First release.

Inject the Reqable CA certificate through
[NoMount](https://github.com/maxsteeel/nomount) instead of the tmpfs plus bind
mount that Reqable's own module uses, so nothing appears in `/proc/mounts`.

### Why

`reqable-magisk/post-fs-data.sh` mounts a `tmpfs` at `/data/local/tmp/sys-ca-copy`
and bind-mounts it over `/apex/com.android.conscrypt/cacerts` in the init, zygote
and zygote64 namespaces. The tmpfs is then visible in some mount views and
removed from others, which is a cross-process mount-table inconsistency: an
integrity scan that compares `/proc/<pid>/mountinfo` across processes reports
`2 distinct views` where it expects `1`.

### Fix

- Disables `reqable-magisk`'s own stage (writes `disable`) so its tmpfs and bind
  never happen, and re-asserts that on every boot.
- Re-injects the same certificate into both `/system/etc/security/cacerts/` and
  `/apex/com.android.conscrypt/cacerts/` with `nm rule add`, so the CA stays
  trusted with no mount at all.
- On the first boot after install, cleans up the leftover `tmpfs` and APEX bind
  in the init and zygote namespaces.
- `uninstall.sh` removes the redirects and re-enables `reqable-magisk`, so the
  module can be removed cleanly.
