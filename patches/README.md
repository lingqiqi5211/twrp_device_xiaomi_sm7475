# Temporary source patches

Each numbered file is an ordinary Git patch, applied in lexical order by
`scripts/apply-patches.sh`. The numeric prefix keeps dependent changes in a
stable order; it is not part of the compiled recovery image.

## bootable/recovery

No longer patched. The recovery changes now live as ordinary commits on the
`marble-twrp16` branch of
`https://github.com/lingqiqi5211/android_bootable_recovery`, which tracks
`TWRP-Test/android_bootable_recovery` `twrp-16.0`. Select it by copying
`manifests/marble-twrp16.xml` into `.repo/local_manifests/` before syncing.

`scripts/apply-patches.sh` refuses to build when `bootable/recovery` does not
contain that branch, so a missing local manifest fails loudly instead of
producing an image without the recovery changes.

## system-core

`0001-libusbhost-add-recovery-variant.patch` declares `recovery_available` on
`libusbhost`. Upstream commit `c1e68e7` ("mtp: Sync Android.bp with AOSP") made
`bootable/recovery/mtp/ffs` depend on it, but AOSP only declares the vendor and
host variants, so linking `libtwrpmtp-ffs` fails without this. Checked against
`system/core` commit `1f21da0fc4300c5802da8f4aad885875da950032`. Drop this patch
once either side declares the variant upstream.

## external-wpa-supplicant-8

Checked against Android `android-16.0.0_r1`, commit
`3ef7b491990ee71f3cbad5c70b274430fa8d5c13`, and applied only for
`twrp_marble_wifi`.

## Series state

After a series is applied, the script stores content hashes for its touched
files under the target repository's `.git/twrp-marble-patches/` directory. This
keeps repeated local builds idempotent without adding marker files to the source
tree. If a patch file changes, start from a clean checkout before applying the
new series.
