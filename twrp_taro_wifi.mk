# Copyright (C) 2026 The Android Open Source Project
# SPDX-License-Identifier: Apache-2.0

# Keep the proven recovery product unchanged. This product only adds the
# experimental HIDL Wi-Fi runtime and uses a separate build output.
$(call inherit-product, device/xiaomi/taro/twrp_taro.mk)

PRODUCT_NAME := twrp_taro_wifi
PRODUCT_MODEL := taro (Wi-Fi experimental)
