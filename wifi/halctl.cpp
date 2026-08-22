/*
 * Copyright (C) 2026 The Android Open Source Project
 * SPDX-License-Identifier: Apache-2.0
 */

#include <android/hardware/wifi/1.0/IWifi.h>
#include <android/hardware/wifi/1.0/IWifiChip.h>
#include <android/hardware/wifi/1.0/IWifiStaIface.h>
#include <hidl/HidlSupport.h>
#include <unistd.h>

#include <iostream>
#include <string>

using android::hardware::hidl_string;
using android::hardware::hidl_vec;
using android::hardware::wifi::V1_0::ChipId;
using android::hardware::wifi::V1_0::ChipModeId;
using android::hardware::wifi::V1_0::IfaceType;
using android::hardware::wifi::V1_0::IWifi;
using android::hardware::wifi::V1_0::IWifiChip;
using android::hardware::wifi::V1_0::IWifiStaIface;
using android::hardware::wifi::V1_0::WifiStatus;
using android::hardware::wifi::V1_0::WifiStatusCode;
using android::sp;

namespace {

bool CheckStatus(const WifiStatus& status, const char* operation) {
    if (status.code == WifiStatusCode::SUCCESS) {
        return true;
    }

    std::cerr << operation << " failed: code=" << static_cast<int>(status.code)
              << " description=" << status.description.c_str() << '\n';
    return false;
}

bool IsRetryableStartStatus(WifiStatusCode code) {
    return code == WifiStatusCode::ERROR_NOT_AVAILABLE ||
           code == WifiStatusCode::ERROR_NOT_STARTED ||
           code == WifiStatusCode::ERROR_BUSY ||
           code == WifiStatusCode::ERROR_UNKNOWN;
}

bool FindStaMode(const hidl_vec<IWifiChip::ChipMode>& modes, ChipModeId* mode_id) {
    for (const auto& mode : modes) {
        for (const auto& combination : mode.availableCombinations) {
            for (const auto& limit : combination.limits) {
                for (const auto& type : limit.types) {
                    if (type == IfaceType::STA) {
                        *mode_id = mode.id;
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

}  // namespace

int main(int argc, char** argv) {
    if (argc != 2 || std::string(argv[1]) != "start") {
        std::cerr << "usage: marble_wifi_halctl start\n";
        return 2;
    }

    sp<IWifi> wifi = IWifi::getService("default");
    if (wifi == nullptr) {
        std::cerr << "Wi-Fi HIDL service is unavailable\n";
        return 1;
    }

    WifiStatus status{};
    bool callback_called = false;
    for (int attempt = 0; attempt < 150; ++attempt) {
        callback_called = false;
        auto result = wifi->start([&](const WifiStatus& callback_status) {
            callback_called = true;
            status = callback_status;
        });
        if (!result.isOk()) {
            std::cerr << "IWifi::start transaction failed: "
                      << result.description().c_str() << '\n';
            return 1;
        }
        if (!callback_called) {
            std::cerr << "IWifi::start did not invoke its callback\n";
            return 1;
        }
        if (status.code == WifiStatusCode::SUCCESS) {
            break;
        }
        if (!IsRetryableStartStatus(status.code)) {
            return CheckStatus(status, "IWifi::start") ? 0 : 1;
        }
        usleep(100 * 1000);
    }
    if (!CheckStatus(status, "IWifi::start")) {
        return 1;
    }

    callback_called = false;
    hidl_vec<ChipId> chip_ids;
    auto chip_ids_result = wifi->getChipIds(
            [&](const WifiStatus& callback_status, const hidl_vec<ChipId>& ids) {
                callback_called = true;
                status = callback_status;
                chip_ids = ids;
            });
    if (!chip_ids_result.isOk() || !callback_called ||
        !CheckStatus(status, "IWifi::getChipIds") || chip_ids.size() == 0) {
        std::cerr << "No Wi-Fi chip is available\n";
        return 1;
    }

    callback_called = false;
    sp<IWifiChip> chip;
    auto chip_result = wifi->getChip(
            chip_ids[0], [&](const WifiStatus& callback_status,
                             const sp<IWifiChip>& callback_chip) {
                callback_called = true;
                status = callback_status;
                chip = callback_chip;
            });
    if (!chip_result.isOk() || !callback_called ||
        !CheckStatus(status, "IWifi::getChip") || chip == nullptr) {
        return 1;
    }

    callback_called = false;
    hidl_vec<IWifiChip::ChipMode> modes;
    auto modes_result = chip->getAvailableModes(
            [&](const WifiStatus& callback_status,
                const hidl_vec<IWifiChip::ChipMode>& callback_modes) {
                callback_called = true;
                status = callback_status;
                modes = callback_modes;
            });
    ChipModeId mode_id{};
    if (!modes_result.isOk() || !callback_called ||
        !CheckStatus(status, "IWifiChip::getAvailableModes") ||
        !FindStaMode(modes, &mode_id)) {
        std::cerr << "The Wi-Fi chip has no STA mode\n";
        return 1;
    }

    callback_called = false;
    auto configure_result = chip->configureChip(
            mode_id, [&](const WifiStatus& callback_status) {
                callback_called = true;
                status = callback_status;
            });
    if (!configure_result.isOk() || !callback_called) {
        std::cerr << "IWifiChip::configureChip transaction failed: "
                  << configure_result.description().c_str() << '\n';
        return 1;
    }
    if (!CheckStatus(status, "IWifiChip::configureChip")) {
        return 1;
    }

    callback_called = false;
    sp<IWifiStaIface> sta_iface;
    auto create_result = chip->createStaIface(
            [&](const WifiStatus& callback_status,
                const sp<IWifiStaIface>& callback_iface) {
                callback_called = true;
                status = callback_status;
                sta_iface = callback_iface;
            });
    if (!create_result.isOk() || !callback_called ||
        !CheckStatus(status, "IWifiChip::createStaIface") || sta_iface == nullptr) {
        return 1;
    }

    callback_called = false;
    hidl_string iface_name;
    auto name_result = sta_iface->getName(
            [&](const WifiStatus& callback_status, const hidl_string& callback_name) {
                callback_called = true;
                status = callback_status;
                iface_name = callback_name;
            });
    if (!name_result.isOk() || !callback_called ||
        !CheckStatus(status, "IWifiStaIface::getName") || iface_name.empty()) {
        return 1;
    }

    std::cout << iface_name.c_str() << '\n';
    return 0;
}
