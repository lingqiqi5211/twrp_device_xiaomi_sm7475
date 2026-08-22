# marble recovery Wi-Fi runtime

This directory contains the optional Wi-Fi runtime used only by
`twrp_marble_wifi`. The stable `twrp_marble` product does not package or start
these files.

The proprietary files under `prebuilt/` were extracted read-only from the
installed marble stock ROM `OS4.0.0.9.XPCCNXM` on 2026-08-21. The included
kernel modules report `5.10.261-Glow-v5.0` as their vermagic. Their expected
hashes are recorded in `prebuilt/SHA256SUMS` and are checked by CI.

The runtime intentionally keeps the stock HIDL Wi-Fi HAL and kernel modules
loaded after Wi-Fi is stopped, because reinitializing the vendor stack is slow
and fragile in recovery. Stop still terminates `wpa_supplicant`, removes its
control socket, clears the published IP/gateway/DNS properties and empties
`/etc/resolv.conf`.

`marble_recovery_wpa_supplicant.conf` has `update_config=0`, so credentials
configured through the TWRP UI are held only by the running process and are not
stored in the recovery image or persistent partitions.

WPA2 and WPA2/WPA3 transition mode have been tested. Transition mode prefers
WPA2 compatibility. Pure WPA3-SAE is present in the UI path but is not yet
verified on hardware.
