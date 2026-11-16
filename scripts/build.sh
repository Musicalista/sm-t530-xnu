#!/usr/bin/env bash
#
# Build script for Samsung Galaxy Tab 4 10.1 SM-T530 (matissewifi) Darwin / XNU Kernel.
# Compiles 32-bit ARMv7 Mach-O kernel binary and packages Android boot.img, Odin tarball, and TWRP zip.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$REPO_DIR/build"
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

# 4. Create stripped kernel binary for production boot.img
echo "--> Generating stripped production kernel binary..."
"$TOOLCHAIN_BIN/strip" -u -r "$BUILD_DIR/mach_kernel.sys" -o "$BUILD_DIR/mach_kernel"

# 5. Extract raw bootable kernel payload for LK execution
echo "--> Generating raw bootable kernel image..."
cp "$BUILD_DIR/mach_kernel" "$BUILD_DIR/kernel.mach"

# 6. Create staging ramdisk
echo "--> Creating staging ramdisk..."
python3 -c "
import gzip
with gzip.open('$BUILD_DIR/ramdisk.img', 'wb') as f:
    f.write(b'Darwin/XNU iOS 10.3.3 Staging Ramdisk for Samsung Galaxy Tab 4 10.1 SM-T530 (matissewifi)\n')
"

# 7. Package Android boot.img using mkbootimg.py
echo "--> Packaging boot.img (Header v0 for Qualcomm Snapdragon 400 with QCDT)..."
python3 "$REPO_DIR/scripts/mkbootimg.py" \
    --kernel "$BUILD_DIR/kernel.mach" \
    --ramdisk "$BUILD_DIR/ramdisk.img" \
    --dt "$REPO_DIR/scripts/dt.img" \
    --base 0x00000000 \
    --kernel_offset 0x00008000 \
    --ramdisk_offset 0x02000000 \
    --tags_offset 0x01e00000 \
    --pagesize 2048 \
    --cmdline "console=null androidboot.hardware=qcom user_debug=23 root=/dev/ram0 rw" \
    --board "matissewifi" \
    -o "$BUILD_DIR/boot.img"

# 8. Create Samsung Odin flashable package (boot.tar.md5)
echo "--> Packaging Samsung Odin boot.tar.md5..."
(
    cd "$BUILD_DIR"
    tar -H ustar -c boot.img > boot.tar
    md5sum -t boot.tar >> boot.tar
    mv boot.tar boot.tar.md5
)

# 9. Create TWRP recovery flashable zip
echo "--> Packaging TWRP recovery flashable zip..."
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
else
    ui_print "Error: Could not locate boot partition!"
    exit 1
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

# 10. Generate checksums
echo "--> Generating SHA256SUMS.txt..."
(
    cd "$BUILD_DIR"
    sha256sum mach_kernel mach_kernel.sys boot.img boot.tar.md5 sm-t530-ios10-xnu-twrp.zip > SHA256SUMS.txt
)

echo "=== Build Complete! Artifacts in $BUILD_DIR: ==="
ls -lh "$BUILD_DIR"
cat "$BUILD_DIR/SHA256SUMS.txt"
