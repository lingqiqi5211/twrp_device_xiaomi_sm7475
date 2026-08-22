#!/system/bin/sh

set -eu

iface="${1:-wlan0}"
/system/bin/dhcpdbg "${iface}"

ip_address="$(/system/bin/ifconfig "${iface}" | /system/bin/awk '
    /inet / {
        for (i = 1; i <= NF; ++i) {
            # toybox prints "inet addr:1.2.3.4"; newer ifconfig prints "inet 1.2.3.4".
            # Pick the value first, then strip the prefix, so neither form leaks "addr:".
            if ($i ~ /^addr:/) {
                value = $i
            } else if ($i == "inet" && (i + 1) <= NF) {
                value = $(i + 1)
            } else {
                continue
            }
            sub(/^addr:/, "", value)
            print value
            exit
        }
    }
')"
/system/bin/setprop "net.${iface}.ipaddress" "${ip_address}"

gateway_hex="$(/system/bin/awk -v iface="${iface}" '
    NR > 1 && $1 == iface && $2 == "00000000" { print $3; exit }
' /proc/net/route)"
gateway=""
if [ "${#gateway_hex}" -eq 8 ]; then
    byte1="$(printf '%d' "0x${gateway_hex#??????}")"
    upper="${gateway_hex%??}"
    byte2="$(printf '%d' "0x${upper#????}")"
    upper="${gateway_hex%????}"
    byte3="$(printf '%d' "0x${upper#??}")"
    byte4="$(printf '%d' "0x${gateway_hex%??????}")"
    gateway="${byte1}.${byte2}.${byte3}.${byte4}"
fi
/system/bin/setprop "net.${iface}.gateway" "${gateway}"

dns1="$(/system/bin/getprop "net.${iface}.dns1")"
dns2="$(/system/bin/getprop "net.${iface}.dns2")"

: > /etc/resolv.conf
if [ -n "${dns1}" ]; then
    echo "nameserver ${dns1}" >> /etc/resolv.conf
fi
if [ -n "${dns2}" ] && [ "${dns2}" != "${dns1}" ]; then
    echo "nameserver ${dns2}" >> /etc/resolv.conf
fi
/system/bin/chmod 0644 /etc/resolv.conf
