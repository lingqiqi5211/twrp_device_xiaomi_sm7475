#!/system/bin/sh
#
# 采集 taro 系列(骁龙 8 Gen 1 / 8+ Gen 1 / 7+ Gen 2)机型做统一 TWRP 设备树所需的信息。
#
# 用法: 在【已开机的系统里】跑, 不是 recovery。不需要 root, 有 root 能多采两项。
#
#   adb push taro-collect.sh /sdcard/Download/
#   adb shell sh /sdcard/Download/taro-collect.sh
#
# 或者用手机上的终端 App:  sh /sdcard/Download/taro-collect.sh
#
# 结果会打印出来, 同时写到 /sdcard/Download/taro-info-<代号>.txt, 把那个文件发回即可。
# 只读取机型硬件配置, 不含 IMEI、序列号、账号等任何个人信息。

sku=$(getprop ro.boot.hardware.sku)
[ -n "$sku" ] || sku=$(getprop ro.product.device)
[ -n "$sku" ] || sku=unknown
out=/sdcard/Download/taro-info-${sku}.txt

has_root=0
su -c true >/dev/null 2>&1 && has_root=1

rootcat() { [ "$has_root" = 1 ] && su -c "cat $1" 2>/dev/null; }
rootls() { [ "$has_root" = 1 ] && su -c "ls $1" 2>/dev/null; }

p() { v=$(getprop "$1" 2>/dev/null); [ -n "$v" ] && printf '%-32s %s\n' "$1" "$v"; }
sec() { printf '\n===== %s =====\n' "$1"; }

collect() {
printf '# taro-collect  %s  root=%s\n' "$(date 2>/dev/null)" "$has_root"

sec 身份
for k in ro.boot.hardware.sku ro.boot.product.hardware.sku ro.boot.product.vendor.sku \
         ro.board.platform ro.product.device ro.product.name ro.product.model \
         ro.product.brand ro.product.manufacturer ro.boot.hwc ro.boot.hwlevel \
         ro.boot.hwversion ro.build.version.release ro.build.version.sdk; do p "$k"; done

sec 屏幕
printf '%-32s %s\n' 分辨率 "$(wm size 2>/dev/null | sed 's/.*: //' | tr -d '\r')"
printf '%-32s %s\n' 密度 "$(wm density 2>/dev/null | sed 's/.*: //' | tr -d '\r')"

sec 亮度
bl=$(ls /sys/class/backlight/ 2>/dev/null)
if [ -n "$bl" ]; then
    for b in $bl; do
        mb=$(cat "/sys/class/backlight/$b/max_brightness" 2>/dev/null)
        [ -n "$mb" ] || mb=$(rootcat "/sys/class/backlight/$b/max_brightness")
        printf '%-32s max=%s\n' "/sys/class/backlight/$b" "${mb:-需要 root, 或在 recovery 里读}"
    done
else
    echo '(/sys/class/backlight 下没有节点)'
fi

sec CPU温度分区
for z in /sys/class/thermal/thermal_zone*; do
    t=$(cat "$z/type" 2>/dev/null)
    case "$t" in *cpu*|*CPU*) printf '%-32s %s\n' "$z" "$t";; esac
done 2>/dev/null | head -8

sec 触摸
for d in goodix synaptics focaltech novatek chipone himax ilitek; do
    grep -qi "$d" /proc/modules 2>/dev/null && echo "已加载驱动: $d"
done
echo '--- 触摸相关内核模块 ---'
ls /vendor/lib/modules/ 2>/dev/null | grep -iE 'goodix|syna|focal|nova|himax|ili|touch' | head -10
echo '--- /vendor/firmware 里的触摸固件 ---'
fw=$(ls /vendor/firmware/ 2>/dev/null)
[ -n "$fw" ] || fw=$(rootls /vendor/firmware/)
if [ -n "$fw" ]; then
    echo "$fw" | grep -iE 'goodix|syna|focal|nova|himax|ili|tp_|touch' | head -12
else
    echo '(无权限, 需要 root; 没有也没关系, 从模块名能推出用哪家)'
fi

sec 振动器
ls /vendor/bin/hw/ 2>/dev/null | grep -i vibrat
getprop 2>/dev/null | grep -i vibrator | head -8

sec vintf
echo '--- /vendor/etc/vintf/ ---'
ls /vendor/etc/vintf/ 2>/dev/null
echo '--- keymaster / keymint 的声明 ---'
for f in /vendor/etc/vintf/manifest_*.xml /vendor/etc/vintf/manifest.xml; do
    [ -f "$f" ] || continue
    v=$(grep -A3 -E 'keymaster|keymint' "$f" 2>/dev/null | grep -o '@[0-9.]*::I[A-Za-z]*' | head -2 | tr '\n' ' ')
    [ -n "$v" ] && printf '%-40s %s\n' "$(basename "$f")" "$v"
done
echo '--- manifest/ 子目录(按服务拆分的片段) ---'
ls /vendor/etc/vintf/manifest/ 2>/dev/null | head -30

sec 分区
printf '%-32s %s\n' '独立 recovery 分区个数' "$(ls /dev/block/by-name/ 2>/dev/null | grep -c '^recovery')"
echo '--- by-name 全部分区 ---'
ls /dev/block/by-name/ 2>/dev/null | tr '\n' ' '
echo

sec 加密与fstab
for k in ro.crypto.type ro.crypto.state ro.crypto.metadata.enabled ro.crypto.volume.filenames_mode; do p "$k"; done
echo '--- fstab 里 userdata / metadata 两行 ---'
for f in /vendor/etc/fstab.qcom /vendor/etc/fstab.default /odm/etc/fstab.qcom; do
    [ -f "$f" ] && grep -E 'userdata|metadata' "$f" 2>/dev/null | head -3
done

sec 内核
uname -a 2>/dev/null
printf '%-32s %s\n' 'init 已加载模块数' "$(wc -l < /proc/modules 2>/dev/null)"
}

collect > "$out" 2>&1
cat "$out"
printf '\n结果已写入: %s\n把这个文件发回即可。\n' "$out"
