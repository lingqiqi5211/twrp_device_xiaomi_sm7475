#!/system/bin/sh

# Startup hook TWRP runs from /system/bin/runatboot.sh. It sets the public
# product identity for the two marble regional variants and installs the
# ZIP64-safe unzip front-end.

load_global() {
    echo "POCO F5" > /config/usb_gadget/g1/strings/0x409/product
    resetprop "ro.product.brand" "POCO"
    echo "I:unified-script: setting POCO F5 props" >> "${LOGF}"
}

load_CN() {
    echo "Redmi Note 12 Turbo" > /config/usb_gadget/g1/strings/0x409/product
    resetprop "ro.product.brand" "Redmi"
    echo "I:unified-script: setting Redmi Note 12 Turbo props" >> "${LOGF}"
}

# Route >4 GiB archives away from ziptool, which cannot extract past an
# archive's 4 GiB mark and makes a HyperOS flash a silent no-op. See
# unzip-zip64.
install_zip64_unzip() {
    if [ ! -x /system/bin/unzip-zip64 ] || [ ! -x /system/bin/7za ] ||
            [ ! -x /system/bin/ziptool ]; then
        echo "E:unzip-zip64: prerequisites missing, keeping stock unzip" >> "${LOGF}"
        return 0
    fi

    # ziptool picks its personality from argv[0], so the stock behaviour stays
    # reachable only through a link that is still named "unzip".
    if [ ! -e /system/bin/.ziptool/unzip ]; then
        if ! mkdir -p /system/bin/.ziptool ||
                ! ln -s /system/bin/ziptool /system/bin/.ziptool/unzip; then
            echo "E:unzip-zip64: cannot stage ziptool, keeping stock unzip" >> "${LOGF}"
            return 0
        fi
    fi

    if ln -sf /system/bin/unzip-zip64 /system/bin/unzip; then
        echo "I:unzip-zip64: >4GiB archives now go through 7za" >> "${LOGF}"
    else
        echo "E:unzip-zip64: failed to redirect /system/bin/unzip" >> "${LOGF}"
    fi
}

LOGF=/tmp/recovery.log
region="$(getprop ro.boot.hwc)"

echo "I:unified-script: detected region: ${region}" >> "${LOGF}"

case "${region}" in
    "CN")
        load_CN
        ;;
    *)
        load_global
        ;;
esac

install_zip64_unzip

exit 0
