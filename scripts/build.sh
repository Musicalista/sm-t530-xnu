#!/usr/bin/env bash
#
# Build script for Samsung Galaxy Tab 4 10.1 SM-T530 (matissewifi) Darwin / XNU Kernel.
# Compiles 32-bit ARMv7 Mach-O kernel binary and packages Android boot.img, Odin tarballs, and TWRP zips.
# Includes Live-in-RAM RootFS (zero flash wear, no modification to Android system/data).
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$REPO_DIR/build"
USERLAND_DIR="$REPO_DIR/userland"
STAGING_DIR="$BUILD_DIR/rootfs_staging"
TOOLCHAIN_BIN="/home/usuario/oneios-build/out/toolchain/bin"

echo "=== [MAHI68] Building Darwin / XNU for Samsung Galaxy Tab 4 10.1 SM-T530 ==="
echo "Repo: $REPO_DIR"
echo "Build: $BUILD_DIR"

mkdir -p "$BUILD_DIR"

# 1. Compile assembly entry trampoline
echo "--> Compiling src/entry.s (ARMv7 Cortex-A7 Linux zImage header & visual checkpoint)..."
clang \
    -target armv7-apple-darwin \
    -mcpu=cortex-a7 \
    -mfpu=vfpv4 \
    -mfloat-abi=softfp \
    -c "$REPO_DIR/src/entry.s" \
    -o "$BUILD_DIR/entry.o"

# 2. Compile kernel bootstrap C code
echo "--> Compiling src/main.c (Darwin hardware initialization & MSM8226 GIC/Timer/LCDC)..."
clang \
    -target armv7-apple-darwin \
    -mcpu=cortex-a7 \
    -mfpu=vfpv4 \
    -mfloat-abi=softfp \
    -O2 \
    -Wall \
    -Wextra \
    -fno-builtin \
    -fno-common \
    -fno-stack-protector \
    -ffreestanding \
    -nostdinc \
    -I"$REPO_DIR/include" \
    -c "$REPO_DIR/src/main.c" \
    -o "$BUILD_DIR/main.o"

# 3. Link 32-bit ARMv7 Mach-O kernel binary
echo "--> Linking Mach-O 32-bit ARMv7 kernel binary at 0x00008000..."
"$TOOLCHAIN_BIN/ld" \
    -arch armv7 \
    -static \
    -image_base 0x00008000 \
    -pagezero_size 0 \
    -e __entry \
    "$BUILD_DIR/entry.o" \
    "$BUILD_DIR/main.o" \
    -o "$BUILD_DIR/mach_kernel.sys"

echo "--> Stripping symbols for production kernel..."
cp "$BUILD_DIR/mach_kernel.sys" "$BUILD_DIR/mach_kernel"
"$TOOLCHAIN_BIN/strip" "$BUILD_DIR/mach_kernel"

# 4. Patch Mach-O kernel into executable ARM Linux zImage for Qualcomm LK
echo "--> Generating executable ARM Linux zImage (zImage)..."
python3 "$REPO_DIR/scripts/patch_kernel_zimage.py" \
    "$BUILD_DIR/mach_kernel.sys" \
    "$BUILD_DIR/mach_kernel" \
    "$TOOLCHAIN_BIN/nm" \
    "$BUILD_DIR/zImage"
cp "$BUILD_DIR/zImage" "$BUILD_DIR/kernel.mach"

# 5. Compile Userland & Generate Live RAM RootFS (ramdisk_live.img)
echo "--> Generating Live-in-RAM RootFS (ramdisk_live.img)..."
if [ ! -f "$BUILD_DIR/SpringBoard" ]; then
    bash "$REPO_DIR/scripts/build_rootfs.sh"
fi

(
    cd "$STAGING_DIR"
    find . | cpio -o -H newc | gzip -9 > "$BUILD_DIR/ramdisk_live.img"
)
cp "$BUILD_DIR/ramdisk_live.img" "$BUILD_DIR/ramdisk.img"

# 6. Package Android boot.img (Header v0 + QCDT + Live RAM RootFS)
echo "--> Packaging Qualcomm boot.img with Live RAM RootFS..."
python3 "$REPO_DIR/scripts/mkbootimg.py" \
    --kernel "$BUILD_DIR/zImage" \
    --ramdisk "$BUILD_DIR/ramdisk_live.img" \
    --dt "$REPO_DIR/scripts/dt.img" \
    --base 0x00000000 \
    --kernel_offset 0x00008000 \
    --ramdisk_offset 0x02000000 \
    --tags_offset 0x01e00000 \
    --pagesize 2048 \
    --cmdline "console=null androidboot.hardware=qcom user_debug=23 root=/dev/ram0 rw" \
    --board "matissewifi" \
    -o "$BUILD_DIR/boot.img"

# 7. Create recovery.img for Non-Invasive Dual-Boot
cp "$BUILD_DIR/boot.img" "$BUILD_DIR/recovery.img"

# 8. Create Samsung Odin flashable packages (boot.tar.md5 and recovery.tar.md5)
echo "--> Packaging Samsung Odin boot.tar.md5 and recovery.tar.md5..."
(
    cd "$BUILD_DIR"
    tar -H ustar -c boot.img > boot.tar
    md5sum -t boot.tar >> boot.tar
    mv boot.tar boot.tar.md5

    tar -H ustar -c recovery.img > recovery.tar
    md5sum -t recovery.tar >> recovery.tar
    mv recovery.tar recovery.tar.md5
)

# 8. Create TWRP recovery flashable zip (Boot Partition)
echo "--> Packaging TWRP boot flashable zip..."
mkdir -p "$BUILD_DIR/twrp_staging/META-INF/com/google/android"
cp "$BUILD_DIR/boot.img" "$BUILD_DIR/twrp_staging/"
cat << 'EOF' > "$BUILD_DIR/twrp_staging/META-INF/com/google/android/updater-script"
ui_print("===========================================");
ui_print("  Darwin/XNU 16.7.0 (iOS 10.3.3) Kernel   ");
ui_print("  Samsung Galaxy Tab 4 10.1 SM-T530       ");
ui_print("===========================================");
ui_print("Flashing Darwin kernel to /dev/block/platform/msm_sdcc.1/by-name/boot...");
package_extract_file("boot.img", "/dev/block/platform/msm_sdcc.1/by-name/boot");
ui_print("Done! Reboot to test.");
EOF

cat << 'EOF' > "$BUILD_DIR/twrp_staging/META-INF/com/google/android/update-binary"
#!/sbin/sh
OUTFD=$2
ZIPFILE=$3
ui_print() {
    echo "ui_print $1" >&$OUTFD
    echo "ui_print" >&$OUTFD
}
ui_print "Flashing Galaxy Tab 4 10.1 Darwin XNU Kernel..."
if [ -b /dev/block/platform/msm_sdcc.1/by-name/boot ]; then
    unzip -p "$ZIPFILE" boot.img > /dev/block/platform/msm_sdcc.1/by-name/boot
    ui_print "Kernel written to /dev/block/platform/msm_sdcc.1/by-name/boot"
elif [ -b /dev/block/bootdevice/by-name/boot ]; then
    unzip -p "$ZIPFILE" boot.img > /dev/block/bootdevice/by-name/boot
    ui_print "Kernel written to /dev/block/bootdevice/by-name/boot"
elif [ -b /dev/block/by-name/boot ]; then
    unzip -p "$ZIPFILE" boot.img > /dev/block/by-name/boot
    ui_print "Kernel written to /dev/block/by-name/boot"
fi
ui_print "Flashing complete."
exit 0
EOF
chmod +x "$BUILD_DIR/twrp_staging/META-INF/com/google/android/update-binary"

python3 -c "
import zipfile, os
zf = zipfile.ZipFile('$BUILD_DIR/sm-t530-ios10-xnu-twrp.zip', 'w', zipfile.ZIP_DEFLATED)
for root, _, files in os.walk('$BUILD_DIR/twrp_staging'):
    for f in files:
        full_path = os.path.join(root, f)
        rel_path = os.path.relpath(full_path, '$BUILD_DIR/twrp_staging')
        zf.write(full_path, rel_path)
zf.close()
"
rm -rf "$BUILD_DIR/twrp_staging"

# 9. Create Dual-Boot TWRP flashable zip (Recovery Partition - Zero Android Impact)
echo "--> Packaging TWRP recovery dual-boot zip (sm-t530-ipados-live-recovery-twrp.zip)..."
mkdir -p "$BUILD_DIR/twrp_rec_staging/META-INF/com/google/android"
cp "$BUILD_DIR/recovery.img" "$BUILD_DIR/twrp_rec_staging/"

cat << 'EOF' > "$BUILD_DIR/twrp_rec_staging/META-INF/com/google/android/update-binary"
#!/sbin/sh
OUTFD=$2
ZIPFILE=$3
ui_print() {
    echo "ui_print $1" >&$OUTFD
    echo "ui_print" >&$OUTFD
}
ui_print "==========================================="
ui_print "  iPadOS Live-in-RAM (Dual-Boot Recovery)  "
ui_print "  Target: Samsung Galaxy Tab 4 10.1 SM-T530"
ui_print "==========================================="
ui_print "Flashing to RECOVERY partition..."
ui_print "NOTE: Android BOOT, SYSTEM, and DATA remain 100% untouched!"

if [ -b /dev/block/platform/msm_sdcc.1/by-name/recovery ]; then
    unzip -p "$ZIPFILE" recovery.img > /dev/block/platform/msm_sdcc.1/by-name/recovery
    ui_print "Flashed to /dev/block/platform/msm_sdcc.1/by-name/recovery"
elif [ -b /dev/block/bootdevice/by-name/recovery ]; then
    unzip -p "$ZIPFILE" recovery.img > /dev/block/bootdevice/by-name/recovery
    ui_print "Flashed to /dev/block/bootdevice/by-name/recovery"
fi

ui_print "Installation complete!"
ui_print "Normal Power On -> Boots original Android"
ui_print "Power + VolUp + Home -> Boots iPadOS Live in RAM"
exit 0
EOF
chmod +x "$BUILD_DIR/twrp_rec_staging/META-INF/com/google/android/update-binary"

python3 -c "
import zipfile, os
zf = zipfile.ZipFile('$BUILD_DIR/sm-t530-ipados-live-recovery-twrp.zip', 'w', zipfile.ZIP_DEFLATED)
for root, _, files in os.walk('$BUILD_DIR/twrp_rec_staging'):
    for f in files:
        full_path = os.path.join(root, f)
        rel_path = os.path.relpath(full_path, '$BUILD_DIR/twrp_rec_staging')
        zf.write(full_path, rel_path)
zf.close()
"
rm -rf "$BUILD_DIR/twrp_rec_staging"

# 10. Update Checksums
echo "--> Generating SHA256SUMS.txt..."
(
    cd "$BUILD_DIR"
    sha256sum \
        mach_kernel \
        mach_kernel.sys \
        zImage \
        boot.img \
        boot.tar.md5 \
        recovery.img \
        recovery.tar.md5 \
        sm-t530-ios10-xnu-twrp.zip \
        sm-t530-ipados-live-recovery-twrp.zip \
        ramdisk_live.img \
        launchd \
        backboardd \
        SpringBoard \
        Preferences \
        MobileSafari \
        sh > SHA256SUMS.txt
)

echo "=== Build Complete! All artifacts ready in $BUILD_DIR ==="
