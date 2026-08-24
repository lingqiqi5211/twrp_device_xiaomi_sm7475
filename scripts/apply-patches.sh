#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tree_root="$(cd "${script_dir}/.." && pwd)"
twrp_source="${1:-${TWRP_SOURCE:-$(pwd)}}"
twrp_product="${2:-${TWRP_PRODUCT:-twrp_marble}}"
recovery_repo="${twrp_source}/bootable/recovery"


case "${twrp_product}" in
    twrp_marble|twrp_marble_wifi)
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

# bootable/recovery now comes from the marble source branch, so there is no
# recovery patch series left to apply. Fail early when the checkout is still
# plain upstream, otherwise the build would silently drop every recovery
# change instead of reporting a setup problem.
#
# Checked by content rather than by commit ancestry: repo clones this project
# at depth 1, so the branch tip has no parents and an ancestry test can never
# succeed.
recovery_markers=(
    "twrpminui/events.cpp:open_ff_haptics"
    "gui/action.cpp:RunWpaCli"
    "gui/scrolllist.cpp:mBottomPaddingApplied"
)
for marker in "${recovery_markers[@]}"; do
    marker_file="${marker%%:*}"
    marker_symbol="${marker#*:}"
    if ! grep -q "${marker_symbol}" "${recovery_repo}/${marker_file}" 2>/dev/null; then
        echo "bootable/recovery is missing the marble recovery changes" >&2
        echo "  (${marker_file} has no ${marker_symbol})" >&2
        echo "Copy manifests/marble-twrp16.xml into .repo/local_manifests/," >&2
        echo "then sync bootable/recovery. See the README." >&2
        exit 1
    fi
done

# The Wi-Fi product's supplicant binaries are defined only in TWRP's
# external/wpa_supplicant_8 fork. With the AOSP project checked out instead,
# ALLOW_MISSING_DEPENDENCIES would drop them and build a Wi-Fi-less image
# without complaining.
if [[ "${twrp_product}" == "twrp_marble_wifi" ]]; then
    wpa_bp="${twrp_source}/external/wpa_supplicant_8/wpa_supplicant/Android.bp"
    if ! grep -q 'name: "wpa_cli_recovery"' "${wpa_bp}" 2>/dev/null; then
        echo "external/wpa_supplicant_8 is not TWRP's fork" >&2
        echo "  (${wpa_bp} defines no wpa_cli_recovery)" >&2
        echo "repo sync refuses to switch it in place; see the README for the" >&2
        echo "paths to delete before syncing that project again." >&2
        exit 1
    fi
fi
