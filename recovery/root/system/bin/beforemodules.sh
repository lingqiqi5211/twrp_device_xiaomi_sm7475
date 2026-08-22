#!/system/bin/sh

# Drop a stale Goodix module from vendor_boot before TWRP selects modules from
# the mounted vendor partitions. Some kernels ship a recovery-time module that
# registers the driver but cannot bind the device, while vendor_dlkm contains
# the module matching the running kernel.

LOGF=/tmp/recovery.log

if grep -q '^goodix_core ' /proc/modules && \
        [ ! -e /sys/bus/spi/devices/spi0.0/driver ] && \
        [ ! -d /sys/devices/platform/goodix_ts.0 ]; then
    if rmmod goodix_core; then
        echo "I:modules_fix: unloaded unbound vendor_boot goodix_core" >> "${LOGF}"
    else
        echo "E:modules_fix: failed to unload unbound vendor_boot goodix_core" >> "${LOGF}"
        exit 1
    fi
fi

exit 0
