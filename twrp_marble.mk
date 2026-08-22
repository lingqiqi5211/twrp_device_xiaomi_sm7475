# Copyright (C) 2026 The Android Open Source Project
# SPDX-License-Identifier: Apache-2.0

DEVICE_PATH := device/xiaomi/marble

$(call inherit-product, $(DEVICE_PATH)/device.mk)

PRODUCT_RELEASE_NAME := marble
PRODUCT_DEVICE := marble
PRODUCT_NAME := twrp_marble
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := Redmi Note 12 Turbo / POCO F5
PRODUCT_MANUFACTURER := Xiaomi

TW_STATUS_ICONS_ALIGN := center
