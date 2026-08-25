#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tree_root="$(cd "${script_dir}/.." && pwd)"
twrp_source="${1:-${TWRP_SOURCE:-$(pwd)}}"
twrp_product="${2:-${TWRP_PRODUCT:-twrp_taro}}"
recovery_repo="${twrp_source}/bootable/recovery"


case "${twrp_product}" in
    twrp_taro|twrp_taro_wifi)
        ;;
    *)
        echo "Unsupported TWRP product: ${twrp_product}" >&2
        exit 1
        ;;
esac

if ! git -C "${recovery_repo}" rev-parse --git-dir >/dev/null 2>&1; then
    echo "TWRP recovery repository not found at: ${recovery_repo}" >&2
    exit 1
fi

# No patch series left to apply; just fail early when bootable/recovery is still
# plain upstream, which would otherwise build an image missing every recovery
# change. Checked by content, not ancestry: repo clones this project at depth 1,
# so the branch tip has no parents for an ancestry test to walk.
recovery_markers=(
    "twrpminui/events.cpp:open_ff_haptics"
    "gui/action.cpp:RunWpaCli"
    "gui/scrolllist.cpp:mBottomPaddingApplied"
)
for marker in "${recovery_markers[@]}"; do
    marker_file="${marker%%:*}"
    marker_symbol="${marker#*:}"
    if ! grep -q "${marker_symbol}" "${recovery_repo}/${marker_file}" 2>/dev/null; then
        echo "bootable/recovery is missing this tree's recovery changes" >&2
        echo "  (${marker_file} has no ${marker_symbol})" >&2
        echo "Copy manifests/taro-twrp16.xml into .repo/local_manifests/," >&2
        echo "then sync bootable/recovery. See the README." >&2
        exit 1
    fi
done

# The Wi-Fi product's supplicant binaries are defined only in TWRP's
# external/wpa_supplicant_8 fork. With the AOSP project checked out instead,
# ALLOW_MISSING_DEPENDENCIES would drop them and build a Wi-Fi-less image
# without complaining.
if [[ "${twrp_product}" == "twrp_taro_wifi" ]]; then
    wpa_bp="${twrp_source}/external/wpa_supplicant_8/wpa_supplicant/Android.bp"
    if ! grep -q 'name: "wpa_cli_recovery"' "${wpa_bp}" 2>/dev/null; then
        echo "external/wpa_supplicant_8 is not TWRP's fork" >&2
        echo "  (${wpa_bp} defines no wpa_cli_recovery)" >&2
        echo "repo sync refuses to switch it in place; see the README for the" >&2
        echo "paths to delete before syncing that project again." >&2
        exit 1
    fi
fi
