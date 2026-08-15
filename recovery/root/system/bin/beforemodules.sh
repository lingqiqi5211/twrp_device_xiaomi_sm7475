#!/system/bin/sh

# Detect current firmware and use proper kernel modules.

LOGF=/tmp/recovery.log
slot="$(getprop ro.boot.slot_suffix)"
if [[ -z "${slot}" ]]; then
    slot="$(bootctl get-current-slot | xargs bootctl get-suffix)"
fi
modules=/vendor/lib/modules

mkdir -p "${modules}/1.1"
if strings "/dev/block/bootdevice/by-name/xbl_config${slot}" | grep -q 'led_blink'; then
    echo "I:modules_fix: Use kernel modules for HyperOS firmware!" >> "${LOGF}"
    mount "${modules}/hos1" "${modules}/1.1" --bind
else
    echo "I:modules_fix: Use kernel modules for MIUI14 firmware!" >> "${LOGF}"
    mount "${modules}/miui14" "${modules}/1.1" --bind
fi

# Work around a loaded Goodix module that did not create its platform device.
if grep -q '^goodix_core ' /proc/modules && \
        [[ ! -d /sys/devices/platform/goodix_ts.0 ]]; then
    if rmmod goodix_core; then
        echo "I:modules_fix: goodix_core unloaded successfully!" >> "${LOGF}"
    else
        echo "E:modules_fix: Cannot unload goodix_core!" >> "${LOGF}"
    fi
fi

exit 0
