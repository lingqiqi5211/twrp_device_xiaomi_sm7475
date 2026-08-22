#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

twrp_source="${1:-${TWRP_SOURCE:-$(pwd)}}"
wpa_repo="${twrp_source}/external/wpa_supplicant_8"
wpa_remote="https://android.googlesource.com/platform/external/wpa_supplicant_8"
wpa_tag="android-16.0.0_r1"
wpa_revision="3ef7b491990ee71f3cbad5c70b274430fa8d5c13"

if ! git -C "${wpa_repo}" rev-parse --git-dir >/dev/null 2>&1; then
    if [[ -e "${wpa_repo}" ]]; then
        echo "Existing path is not a Git repository: ${wpa_repo}" >&2
        exit 1
    fi
    mkdir -p "$(dirname "${wpa_repo}")"
    git clone --depth=1 --branch "${wpa_tag}" "${wpa_remote}" "${wpa_repo}"
fi

actual_revision="$(git -C "${wpa_repo}" rev-parse HEAD)"
if [[ "${actual_revision}" != "${wpa_revision}" ]]; then
    echo "Unexpected wpa_supplicant_8 revision: ${actual_revision}" >&2
    echo "Expected ${wpa_tag}: ${wpa_revision}" >&2
    exit 1
fi

echo "Using wpa_supplicant_8 ${wpa_tag}: ${actual_revision}"
