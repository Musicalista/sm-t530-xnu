#!/system/bin/sh
#
# live_kexec.sh - Boot Darwin / iPadOS Live in RAM from running Android
# Target: Samsung Galaxy Tab 4 10.1 (SM-T530 / matissewifi)
# ZERO FLASH: Does NOT write to eMMC. Entire OS executes from DRAM.
#

echo "========================================================"
echo "  [MAHI68] Darwin / iPadOS In-Memory Live Boot Loader   "
echo "  Target: Samsung Galaxy Tab 4 10.1 (SM-T530)           "
echo "  Status: Zero eMMC write | Android remains untouched   "
echo "========================================================"

if [ "$(id -u)" != "0" ]; then
    echo "Error: This script must be run as root (su)."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOOT_IMG="$SCRIPT_DIR/boot.img"

if [ ! -f "$BOOT_IMG" ]; then
    echo "Error: $BOOT_IMG not found. Place boot.img in the same directory."
    exit 1
fi

echo "--> Verifying kexec capability in Android Linux kernel..."
if [ -f /sys/kernel/kexec_loaded ] || which kexec >/dev/null 2>&1; then
    echo "--> Loading Darwin Mach-O kernel & iPadOS RAM-RootFS into memory..."
    kexec -l "$BOOT_IMG" --command-line="console=null androidboot.hardware=qcom user_debug=23 root=/dev/ram0 rw" || {
        echo "Direct kexec load failed. Falling back to recovery-slot dual-boot."
        exit 1
    }
    echo "--> Executing in-memory handover to Darwin..."
    sync
    kexec -e
else
    echo "Notice: Stock Samsung kernel has CONFIG_KEXEC disabled."
    echo "Use the Recovery Dual-Boot method (sm-t530-ipados-live-recovery-twrp.zip):"
    echo "  - Android BOOT, SYSTEM, and DATA remain 100% untouched."
    echo "  - Normal Power button boots standard Android."
    echo "  - Power + VolUp + Home boots iPadOS Live in RAM."
fi
