# Copyright (C) 2026 The Android Open Source Project
# SPDX-License-Identifier: Apache-2.0

# Keep the proven recovery product unchanged. This product only adds the
# experimental marble HIDL Wi-Fi runtime and uses a separate build output.
$(call inherit-product, device/xiaomi/marble/twrp_marble.mk)

PRODUCT_NAME := twrp_marble_wifi
PRODUCT_MODEL := Redmi Note 12 Turbo / POCO F5 (Wi-Fi experimental)
