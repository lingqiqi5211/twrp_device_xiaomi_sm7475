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

## Build

```bash
source build/envsetup.sh
lunch twrp_marble-bp2a-eng
m recoveryimage
```

Alternatively, set `TWRP_SOURCE` to an existing TWRP 16 source directory and
run `scripts/build.sh`. GitHub Actions uses the same manifest and lunch target
and uploads `recovery.img`, its SHA-256 file and the complete build log.

The output is `out/target/product/marble/recovery.img`. It is a ramdisk-only
A/B recovery image; do not use `fastboot boot` with it. Flash the active or
inactive recovery slot only after confirming the device codename and making a
backup.

## Compatibility notes

- Keeps marble's real Android 13 vendor/shipping level while building against
  the Android 16/API 36 recovery source.
- Includes both legacy QTI HIDL keymaster/gatekeeper and the QTI AIDL KeyMint
  service required by newer Android userdata.
- Uses marble's current QTI AIDL V2 vibrator service instead of the obsolete
  `ndk_platform` vibrator ABI removed from the TWRP 16 build tree.
- Deliberately disables TWRP 16's WLAN UI/runtime with `TW_NO_NETWORK`. marble
  uses an older HIDL-heavy vendor stack and does not provide the newer recovery
  Wi-Fi service/module set. HIDL security and Wi-Fi-keystore ABI libraries used
  by the crypto stack remain available; Wi-Fi itself is not started.
- Uses fscrypt policy v2, wrapped-key metadata encryption, EROFS logical
  partitions and Android Q through W GSI AVB keys.
- Selects the MIUI 14 or HyperOS kernel-module set at recovery startup.

Hardware files and recovery services are based on
`AviderMin/ofrp_device_xiaomi_marble` and
`YuKongA/device_xiaomi_marble_TWRP`. TWRP 16 build conventions are based on
`Kyuofox/twrp_device_xiaomi_sm8850` / `YuKongA/twrp_device_xiaomi_sm8850`.
