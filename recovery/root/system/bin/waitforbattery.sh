#!/system/bin/sh

# Do not block Android init while the PMIC power-supply node is being created.
# Health is useful to the UI but is not part of metadata or FBE decryption.

battery_path=/sys/class/power_supply/battery
attempt=0
max_attempts=100

while [ ! -e "${battery_path}" ] && [ "${attempt}" -lt "${max_attempts}" ]; do
    sleep 0.1
    attempt=$((attempt + 1))
done

if [ -e "${battery_path}" ]; then
    echo "I:battery_wait: ready after ${attempt} attempts" >> /tmp/recovery.log
else
    echo "E:battery_wait: timed out after ${max_attempts} attempts" >> /tmp/recovery.log
fi

# Start the services even after a timeout so devices without this exact sysfs
# path retain the health implementation's own fallback behavior.
setprop twrp.battery.ready true

# The kernel may still hold an ADSP firmware file for a short time after the
# battery node appears. Retry in the background so /firmware does not remain
# mounted for the whole recovery session when the first unmount returns busy.
attempt=0
max_attempts=50
while grep -q " /firmware " /proc/mounts && [ "${attempt}" -lt "${max_attempts}" ]; do
    if umount /firmware 2>/dev/null; then
        echo "I:firmware_cleanup: unmounted after ${attempt} retries" >> /tmp/recovery.log
        exit 0
    fi
    sleep 0.1
    attempt=$((attempt + 1))
done

if grep -q " /firmware " /proc/mounts; then
    echo "E:firmware_cleanup: still mounted after ${max_attempts} retries" >> /tmp/recovery.log
fi
