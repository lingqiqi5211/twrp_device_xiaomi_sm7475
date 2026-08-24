# TWRP 16 for Xiaomi marble

Device tree for Redmi Note 12 Turbo / POCO F5 (`marble`), targeting the
TWRP Android 16 branch and Android 16+ userdata.

## Source baseline

```bash
repo init -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp.git \
    -b twrp-16.0 --depth=1
repo sync -c --no-tags --no-clone-bundle -j"$(nproc)"
git clone <this-repository> device/xiaomi/marble
```

`bootable/recovery` is built from the marble source branch rather than the
upstream branch plus a patch series, so select it with the bundled local
manifest and sync it again. The same file restores
`frameworks/libs/native_bridge_support`, which TWRP strips but `crash_dump`
needs, so sync both:

```bash
mkdir -p .repo/local_manifests
cp device/xiaomi/marble/manifests/marble-twrp16.xml .repo/local_manifests/
repo sync -c --no-tags --no-clone-bundle \
    bootable/recovery frameworks/libs/native_bridge_support
```

The branch is `marble-twrp16` of
`https://github.com/lingqiqi5211/android_bootable_recovery`, which tracks
`TWRP-Test/android_bootable_recovery` `twrp-16.0`. `scripts/apply-patches.sh`
refuses to build when that checkout is missing the marble recovery changes, so
a forgotten local manifest fails loudly instead of producing an image without
them.

## Build

The stable product keeps networking out of the recovery ramdisk:

```bash
bash device/xiaomi/marble/scripts/apply-patches.sh "$PWD" twrp_marble
source build/envsetup.sh
lunch twrp_marble-bp2a-eng
m recoveryimage
```

The experimental Wi-Fi product has a separate output directory:

```bash
TWRP_SOURCE="$PWD" \
TWRP_PRODUCT=twrp_marble_wifi \
bash device/xiaomi/marble/scripts/build.sh
```

For the stable product, `scripts/build.sh` defaults to `twrp_marble`.

Nothing here patches the Android source any more. The recovery changes live as
commits on the `marble-twrp16` branch; `libtwrpmtp-ffs` links AOSP's own
`libusbhost`, whose recovery variant TWRP declared upstream in `system/core`
`ea939a2`; and the two recovery Wi-Fi binaries come from TWRP's own
`external/wpa_supplicant_8` fork, which its manifest already selects in place of
the AOSP project. `scripts/apply-patches.sh` now only checks that
`bootable/recovery` really is the marble branch, so a forgotten local manifest
fails loudly instead of producing an image without those changes.

Keep every project synced, not just `bootable/recovery`: the `vendor/twrp` fork
and the `wpa_supplicant_8` and `libusbhost` patches this tree used to carry were
all fixes TWRP had already landed upstream.

A checkout synced before TWRP's manifest replaced `external/wpa_supplicant_8`
still holds the AOSP project, and `repo sync` refuses to switch it in place
("unsupported checkout state"). Delete `external/wpa_supplicant_8`,
`.repo/projects/external/wpa_supplicant_8.git` and
`.repo/project-objects/platform/external/wpa_supplicant_8.git`, then sync that
project again.

All files under `scripts/` and recovery runtime shell scripts must be committed
with Git mode `100755`; CI rejects a checkout that loses their executable bit.

Soong analyses this tree with the Go collector switched off, so soong_build's
heap only grows: it peaks near 20 GiB and an 18 GiB machine is OOM-killed
during analysis with swap untouched. `scripts/build.sh` therefore sets
`SOONG_GOMEMLIMIT` to 70% of MemTotal unless the caller already chose a value,
which makes the runtime collect as it approaches that ceiling. Measured on this
tree: 20.2 GiB peak and 200 s of analysis unlimited, against 13.2 GiB and 206 s
at a 12 GiB ceiling. Building with a bare `m recoveryimage` skips that default,
so export `SOONG_GOMEMLIMIT` yourself on a machine with less than about 24 GiB.

The manual GitHub Actions workflow targets a self-hosted Linux x64 runner with
at least 120 GiB of free disk and 16 GiB of RAM. Standard GitHub-hosted runners
do not have enough disk for this TWRP 16 source tree. The workflow uploads
`recovery.img`, its SHA-256 file and the complete build log.

The stable output is `out/target/product/marble/recovery.img`; the Wi-Fi output
is `out-marble-wifi/target/product/marble/recovery.img`. Both are ramdisk-only
A/B recovery images; do not use `fastboot boot` with them. Flash the active or
inactive recovery slot only after confirming the device codename and making a
backup.

## Compatibility notes

- Keeps marble's real Android 13 vendor/shipping level while building against
  the Android 16/API 36 recovery source.
- Includes both legacy QTI HIDL keymaster/gatekeeper and the QTI AIDL KeyMint
  service required by newer Android userdata.
- Uses marble's current QTI AIDL V2 vibrator service instead of the obsolete
  `ndk_platform` vibrator ABI removed from the TWRP 16 build tree.
- The stable `twrp_marble` product deliberately disables TWRP 16's WLAN
  UI/runtime by leaving `TW_INCLUDE_WIFI` unset.
- The experimental `twrp_marble_wifi` product uses marble's stock HIDL Wi-Fi
  HAL and kernel modules with recovery-only, control-socket `wpa_supplicant`
  binaries built from Android 16 source. WPA2 and WPA2/WPA3 transition mode
  have been tested; transition mode currently prefers WPA2 compatibility.
  Pure WPA3-SAE remains unverified. Credentials are never written back to the
  supplicant configuration, and stopping Wi-Fi retains the HAL/modules for
  faster reuse while clearing IP, gateway and DNS state.
- Uses fscrypt policy v2, wrapped-key metadata encryption, EROFS logical
  partitions and Android Q through W GSI AVB keys.
- Selects the MIUI 14 or HyperOS kernel-module set at recovery startup.

Hardware files and recovery services are based on
`AviderMin/ofrp_device_xiaomi_marble` and
`YuKongA/device_xiaomi_marble_TWRP`. TWRP 16 build conventions are based on
`Kyuofox/twrp_device_xiaomi_sm8850` / `YuKongA/twrp_device_xiaomi_sm8850`.
