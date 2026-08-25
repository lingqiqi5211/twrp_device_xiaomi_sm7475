#!/system/bin/sh

set -eu

log_tag="taro_wifi"
iface="wlan0"
ctrl_socket="/tmp/recovery/sockets/${iface}"
cnss_ready_marker="/tmp/taro-wifi-cnss-fs-ready"

log_message() {
    /system/bin/log -t "${log_tag}" "$*"
    echo "$*"
}

is_mounted() {
    /system/bin/grep -q " $1 " /proc/mounts
}

load_module() {
    module_name="$1"
    module_path="$2"
    if ! /system/bin/grep -q "^${module_name} " /proc/modules; then
        /system/bin/insmod "${module_path}"
    fi
}

signal_cnss_fs_ready() {
    if [ -w /sys/kernel/cnss/fs_ready ] && [ ! -e "${cnss_ready_marker}" ]; then
        echo 1 > /sys/kernel/cnss/fs_ready
        : > "${cnss_ready_marker}"
    fi
}

configure_ping_sockets() {
    if [ -w /proc/sys/net/ipv4/ping_group_range ]; then
        echo "0 2147483647" > /proc/sys/net/ipv4/ping_group_range
    fi
}

clear_network_state() {
    for property in ipaddress gateway dns1 dns2; do
        /system/bin/setprop "net.${iface}.${property}" ""
    done
    : > /etc/resolv.conf
    /system/bin/chmod 0644 /etc/resolv.conf
}

start_wifi() {
    slot_suffix="$(/system/bin/getprop ro.boot.slot_suffix)"
    if ! is_mounted /firmware; then
        /system/bin/mkdir -p /firmware
        /system/bin/mount -t vfat -o ro \
            "/dev/block/bootdevice/by-name/modem${slot_suffix}" /firmware
    fi

    if is_mounted /persist && ! is_mounted /mnt/vendor/persist; then
        /system/bin/mkdir -p /mnt/vendor/persist
        /system/bin/mount --bind /persist /mnt/vendor/persist
        /system/bin/mount -o remount,bind,ro /mnt/vendor/persist || true
    fi

    signal_cnss_fs_ready
    load_module cfg80211 /vendor/lib/modules/cfg80211.ko
    load_module qca6490 /vendor/lib/modules/qca_cld3_qca6490.ko

    /system/bin/setprop wifi.interface "${iface}"
    if [ "$(/system/bin/getprop init.svc.vendor.wifi_hal_legacy)" != "running" ]; then
        /system/bin/start vendor.wifi_hal_legacy
        attempt=0
        while [ "$(/system/bin/getprop init.svc.vendor.wifi_hal_legacy)" != "running" ]; do
            attempt=$((attempt + 1))
            if [ "${attempt}" -ge 50 ]; then
                log_message "Wi-Fi HAL service did not start"
                return 1
            fi
            /system/bin/sleep 0.1
        done
    fi

    if [ ! -e "/sys/class/net/${iface}" ]; then
        iface_name="$(/system/bin/taro_wifi_halctl start)" || return 1
        if [ "${iface_name}" != "${iface}" ]; then
            log_message "Wi-Fi HAL created unexpected interface: ${iface_name}"
            return 1
        fi
    fi
    /system/bin/ifconfig "${iface}" up
    configure_ping_sockets

    /system/bin/mkdir -p /tmp/recovery/sockets
    /system/bin/chown wifi:wifi /tmp/recovery/sockets
    /system/bin/chmod 0770 /tmp/recovery/sockets

    # TWRP's wpa_cli drops to the wifi user and puts its client socket straight
    # in /tmp, which the ramdisk leaves root:shell 0775. Sticky bit kept so one
    # user cannot remove another's socket.
    /system/bin/chmod 1777 /tmp
    if [ "$(/system/bin/getprop init.svc.wpa_supplicant_recovery)" != "running" ]; then
        /system/bin/rm -f "${ctrl_socket}"
        /system/bin/start wpa_supplicant_recovery
        attempt=0
        while [ ! -S "${ctrl_socket}" ]; do
            attempt=$((attempt + 1))
            if [ "${attempt}" -ge 100 ]; then
                log_message "wpa_supplicant control socket did not appear"
                return 1
            fi
            /system/bin/sleep 0.1
        done
    fi

    log_message "Wi-Fi runtime ready on ${iface}"
}

stop_wifi() {
    /system/bin/stop wpa_supplicant_recovery || true
    if [ -e "/sys/class/net/${iface}" ]; then
        /system/bin/ifconfig "${iface}" down || true
    fi
    clear_network_state
    /system/bin/rm -f "${ctrl_socket}"
    log_message "Wi-Fi stopped and network state cleared; HAL and kernel modules retained"
}

case "${1:-}" in
    start)
        start_wifi
        ;;
    stop)
        stop_wifi
        ;;
    *)
        echo "usage: taro-wifi-control {start|stop}" >&2
        exit 2
        ;;
esac
