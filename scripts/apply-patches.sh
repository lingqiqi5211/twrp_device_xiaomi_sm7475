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
    "minuitwrp/events.cpp:open_ff_haptics"
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
        echo "then sync bootable/recovery. See patches/README.md." >&2
        exit 1
    fi
done

apply_patch_series() {
    local repo="$1"
    local series_name="$2"
    local patch_pattern="$3"
    local patch
    local series_hash
    local state_dir
    local state_file
    local -a patches
    local -a touched_files

    mapfile -t patches < <(compgen -G "${patch_pattern}" | sort)
    if [[ "${#patches[@]}" -eq 0 ]]; then
        return 0
    fi

    series_hash="$({
        for patch in "${patches[@]}"; do
            sha256sum "${patch}" | cut -d' ' -f1
        done
    } | sha256sum | cut -d' ' -f1)"
    state_dir="$(git -C "${repo}" rev-parse --absolute-git-dir)/twrp-marble-patches"
    state_file="${state_dir}/${series_name}-${series_hash}.sha256"

    if [[ -f "${state_file}" ]] &&
            (cd "${repo}" && sha256sum --status -c "${state_file}"); then
        for patch in "${patches[@]}"; do
            echo "Already applied: ${patch}"
        done
        return 0
    fi

    for patch in "${patches[@]}"; do
        if git -C "${repo}" apply --check "${patch}" 2>/dev/null; then
            git -C "${repo}" apply "${patch}"
            echo "Applied: ${patch}"
        elif git -C "${repo}" apply --check --ignore-space-change "${patch}" 2>/dev/null; then
            git -C "${repo}" apply --ignore-space-change "${patch}"
            echo "Applied with line-ending compatibility: ${patch}"
        elif git -C "${repo}" apply --reverse --check "${patch}" 2>/dev/null; then
            echo "Already applied: ${patch}"
        elif git -C "${repo}" apply --reverse --check --ignore-space-change "${patch}" 2>/dev/null; then
            echo "Already applied with line-ending compatibility: ${patch}"
        else
            echo "Patch does not apply cleanly: ${patch}" >&2
            echo "Use a clean source checkout if the patch series changed." >&2
            exit 1
        fi
    done

    mapfile -t touched_files < <(
        sed -n 's|^+++ b/||p' "${patches[@]}" | grep -v '^/dev/null$' | sort -u
    )
    if [[ "${#touched_files[@]}" -eq 0 ]]; then
        echo "No patched files found for series: ${series_name}" >&2
        exit 1
    fi
    mkdir -p "${state_dir}"
    (cd "${repo}" && sha256sum "${touched_files[@]}") > "${state_file}"
}

core_repo="${twrp_source}/system/core"
if ! git -C "${core_repo}" rev-parse --git-dir >/dev/null 2>&1; then
    echo "system/core repository not found at: ${core_repo}" >&2
    exit 1
fi

apply_patch_series \
    "${core_repo}" \
    system-core \
    "${tree_root}/patches/system-core/*.patch"

wpa_repo="${twrp_source}/external/wpa_supplicant_8"
if [[ "${twrp_product}" == "twrp_marble_wifi" ]]; then
    if ! git -C "${wpa_repo}" rev-parse --git-dir >/dev/null 2>&1; then
        echo "wpa_supplicant_8 repository is required for the Wi-Fi patches" >&2
        exit 1
    fi
    wpa_revision="3ef7b491990ee71f3cbad5c70b274430fa8d5c13"
    actual_wpa_revision="$(git -C "${wpa_repo}" rev-parse HEAD)"
    if [[ "${actual_wpa_revision}" != "${wpa_revision}" ]]; then
        echo "Unexpected wpa_supplicant_8 revision: ${actual_wpa_revision}" >&2
        echo "Expected: ${wpa_revision}" >&2
        exit 1
    fi

    apply_patch_series \
        "${wpa_repo}" \
        external-wpa-supplicant-8 \
        "${tree_root}/patches/external-wpa-supplicant-8/*.patch"
fi
