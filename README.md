# Reqable NoMount

Inject the [Reqable](https://reqable.com) CA certificate using
[NoMount](https://github.com/maxsteeel/nomount), eliminating traditional mounts.

Reqable's own Magisk module installs its CA certificate in two ways: a file under
`system/etc/security/cacerts/`, and, on Android 14+, a `tmpfs` mounted at
`/data/local/tmp/sys-ca-copy` and bind-mounted over
`/apex/com.android.conscrypt/cacerts`. The bind is done in the init, zygote and
zygote64 namespaces because Magisk does not inject into `/apex`.

That `tmpfs` is a real mount. It shows up in `/proc/<pid>/mountinfo`, and it does
not show up in every process: an app-namespace cleanup that removes the tmpfs
leaves the init and zygote views holding it, so two processes end up with
different mount tables. An integrity scan that compares mount tables across
processes reports `2 distinct views` where it expects `1`.

This module keeps the certificate and throws the mount away. It disables the
Reqable module's own stage and re-injects the same certificate through NoMount's
VFS layer, into both the legacy cacerts directory and the conscrypt APEX
directory, so the CA is trusted with no mount at all. Nothing to hide means
nothing can diverge.

## Usage

- Install Reqable's **Certificate Installer** module (Reqable writes
  `/data/adb/modules/reqable-magisk/`).
- Make sure you have [NoMount](https://github.com/maxsteeel/nomount) integrated
  into your kernel and its metamodule installed.
- Flash this module and reboot.

Nothing else to configure. The Reqable module stays **installed** — it holds the
certificate — but its mount stage is switched off, and re-switched-off on every
boot so a Reqable update is handled automatically. Its description is rewritten
to `⚠️ Keep disabled. Injected natively via NoMount.` so the module list explains
why it is off; the original `module.prop` is kept beside it as `err` and restored
on uninstall.

## How it works

`post-fs-data.sh` runs before the mount stages and writes `disable` into
`reqable-magisk`, which stops its scripts for this boot. Because a disabled
module is skipped by NoMount's `metamount.sh` too, the same script adds the
redirects itself:

```
nm rule add /system/etc/security/cacerts/<cert>         <reqable cert>
nm rule add /apex/com.android.conscrypt/cacerts/<cert>  <reqable cert>
```

`service.sh` re-asserts them once the system has settled, and cleans up a
leftover `tmpfs` from the first boot after install. `uninstall.sh` restores the
original `module.prop`, removes the redirects, and hands `reqable-magisk` its
mount stage back.

## Credits

- [NoMount](https://github.com/maxsteeel/nomount) by
  [maxsteeel](https://github.com/maxsteeel) — the VFS provider that makes the
  whole thing possible.
- [morphe-nomount](https://github.com/meltartica/morphe-nomount) — the
  disable-then-reinject pattern this module follows.
- [Reqable](https://reqable.com) — ships the certificate this injects.

## Licence

GPL-3.0. See `LICENSE`.
