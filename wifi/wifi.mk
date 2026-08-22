# Copyright (C) 2026 The Android Open Source Project
# SPDX-License-Identifier: Apache-2.0

PRODUCT_PACKAGES += \
    dhcpdbg \
    marble_recovery_wpa_cli \
    marble_recovery_wpa_supplicant \
    marble_wifi_halctl

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/wifi/marble-wifi-control.sh:recovery/root/system/bin/marble-wifi-control \
    $(DEVICE_PATH)/wifi/marble-wifi-dhcp.sh:recovery/root/system/bin/marble-wifi-dhcp \
    $(DEVICE_PATH)/wifi/marble-recovery-wifi.rc:recovery/root/system/etc/init/marble-recovery-wifi.rc \
    $(DEVICE_PATH)/wifi/marble_recovery_wpa_supplicant.conf:recovery/root/vendor/etc/wifi/marble_recovery_wpa_supplicant.conf \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/etc/wifi/qca6490/WCNSS_qcom_cfg.ini:recovery/root/vendor/firmware/wlan/qca_cld/qca6490/WCNSS_qcom_cfg.ini \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/bin/hw/android.hardware.wifi@1.0-service:recovery/root/vendor/bin/hw/android.hardware.wifi@1.0-service \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/etc/vintf/manifest/android.hardware.wifi@1.0-service.xml:recovery/root/vendor/etc/vintf/manifest/android.hardware.wifi@1.0-service.xml \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/etc/wifi/qca6490/WCNSS_qcom_cfg.ini:recovery/root/vendor/etc/wifi/qca6490/WCNSS_qcom_cfg.ini \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/etc/wifi/vendor_cmd.xml:recovery/root/vendor/etc/wifi/vendor_cmd.xml \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/lib/modules/cfg80211.ko:recovery/root/vendor/lib/modules/cfg80211.ko \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/lib/modules/qca_cld3_qca6490.ko:recovery/root/vendor/lib/modules/qca_cld3_qca6490.ko \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/lib64/android.hardware.wifi@1.0.so:recovery/root/vendor/lib64/android.hardware.wifi@1.0.so \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/lib64/android.hardware.wifi@1.1.so:recovery/root/vendor/lib64/android.hardware.wifi@1.1.so \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/lib64/android.hardware.wifi@1.2.so:recovery/root/vendor/lib64/android.hardware.wifi@1.2.so \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/lib64/android.hardware.wifi@1.3.so:recovery/root/vendor/lib64/android.hardware.wifi@1.3.so \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/lib64/android.hardware.wifi@1.4.so:recovery/root/vendor/lib64/android.hardware.wifi@1.4.so \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/lib64/android.hardware.wifi@1.5.so:recovery/root/vendor/lib64/android.hardware.wifi@1.5.so \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/lib64/libcld80211.so:recovery/root/vendor/lib64/libcld80211.so \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/lib64/libwifi-hal-ctrl.so:recovery/root/vendor/lib64/libwifi-hal-ctrl.so \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/lib64/libwifi-hal-qcom.so:recovery/root/vendor/lib64/libwifi-hal-qcom.so \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/lib64/libwifi-hal.so:recovery/root/vendor/lib64/libwifi-hal.so \
    $(DEVICE_PATH)/wifi/prebuilt/vendor/lib64/libwifi-system-iface.so:recovery/root/vendor/lib64/libwifi-system-iface.so
