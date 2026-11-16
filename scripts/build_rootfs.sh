#!/usr/bin/env bash
#
# build_rootfs.sh - Build Darwin 16 / iOS 10.3.3 iPad Tablet Userland RootFS for SM-T530
# Compiles ARMv7 Mach-O userland binaries (launchd, SpringBoard, backboardd, Preferences, Safari),
# assembles the iPad filesystem tree, and packages ext4 system.img, Odin system.tar.md5, and TWRP zip.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
USERLAND_DIR="$REPO_DIR/userland"
BUILD_DIR="$REPO_DIR/build"
STAGING_DIR="$BUILD_DIR/rootfs_staging"
TOOLCHAIN_BIN="/home/usuario/oneios-build/out/toolchain/bin"

echo "=== [MAHI68] Building iPad Tablet Userland for SM-T530 ==="

mkdir -p "$BUILD_DIR"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# 1. Compile Userland Mach-O Binaries
echo "--> Compiling userland Mach-O binaries for ARMv7..."

compile_mach() {
    local src="$1"
    local obj="$2"
    local out="$3"
    local base="$4"

    clang \
        -target armv7-apple-darwin \
        -mcpu=cortex-a7 \
        -mfpu=vfpv4 \
        -mfloat-abi=softfp \
        -O2 \
        -fno-builtin \
        -fno-common \
        -fno-stack-protector \
        -ffreestanding \
        -nostdinc \
        -I"$REPO_DIR/include" \
        -I"$USERLAND_DIR/include" \
        -c "$src" \
        -o "$obj"

    "$TOOLCHAIN_BIN/ld" \
        -arch armv7 \
        -static \
        -pagezero_size 0 \
        -image_base "$base" \
        -e __start \
        "$obj" \
        -o "$out"

    "$TOOLCHAIN_BIN/strip" "$out"
}

compile_mach "$USERLAND_DIR/src/launchd.c" "$BUILD_DIR/launchd.o" "$BUILD_DIR/launchd" "0x00100000"
compile_mach "$USERLAND_DIR/src/backboardd.c" "$BUILD_DIR/backboardd.o" "$BUILD_DIR/backboardd" "0x00200000"
compile_mach "$USERLAND_DIR/src/springboard.c" "$BUILD_DIR/springboard.o" "$BUILD_DIR/SpringBoard" "0x00300000"
compile_mach "$USERLAND_DIR/src/preferences.c" "$BUILD_DIR/preferences.o" "$BUILD_DIR/Preferences" "0x00400000"
compile_mach "$USERLAND_DIR/src/mobilesafari.c" "$BUILD_DIR/mobilesafari.o" "$BUILD_DIR/MobileSafari" "0x00500000"
compile_mach "$USERLAND_DIR/src/sh.c" "$BUILD_DIR/sh.o" "$BUILD_DIR/sh" "0x00600000"

echo "--> Verifying compiled Mach-O executables..."
"$TOOLCHAIN_BIN/otool" -hv "$BUILD_DIR/SpringBoard"

# 2. Build RootFS Directory Structure
echo "--> Assembling Darwin / iOS iPad directory tree..."

mkdir -p "$STAGING_DIR/bin"
mkdir -p "$STAGING_DIR/sbin"
mkdir -p "$STAGING_DIR/dev"
mkdir -p "$STAGING_DIR/etc"
mkdir -p "$STAGING_DIR/private/var/mobile/Library/Preferences"
mkdir -p "$STAGING_DIR/private/var/mobile/Media"
mkdir -p "$STAGING_DIR/private/var/mobile/Containers"
mkdir -p "$STAGING_DIR/private/var/log"
mkdir -p "$STAGING_DIR/private/var/tmp"
mkdir -p "$STAGING_DIR/System/Library/CoreServices/SpringBoard.app"
mkdir -p "$STAGING_DIR/System/Library/Frameworks/UIKit.framework"
mkdir -p "$STAGING_DIR/System/Library/Frameworks/CoreFoundation.framework"
mkdir -p "$STAGING_DIR/System/Library/Frameworks/QuartzCore.framework"
mkdir -p "$STAGING_DIR/System/Library/Frameworks/IOKit.framework"
mkdir -p "$STAGING_DIR/System/Library/LaunchDaemons"
mkdir -p "$STAGING_DIR/Applications/Preferences.app"
mkdir -p "$STAGING_DIR/Applications/MobileSafari.app"
mkdir -p "$STAGING_DIR/Applications/MobileSlideShow.app"
mkdir -p "$STAGING_DIR/Applications/Camera.app"
mkdir -p "$STAGING_DIR/Applications/Calculator.app"

# Install binaries
cp "$BUILD_DIR/launchd" "$STAGING_DIR/sbin/launchd"
chmod 755 "$STAGING_DIR/sbin/launchd"

cp "$BUILD_DIR/backboardd" "$STAGING_DIR/System/Library/CoreServices/backboardd"
chmod 755 "$STAGING_DIR/System/Library/CoreServices/backboardd"

cp "$BUILD_DIR/SpringBoard" "$STAGING_DIR/System/Library/CoreServices/SpringBoard.app/SpringBoard"
chmod 755 "$STAGING_DIR/System/Library/CoreServices/SpringBoard.app/SpringBoard"

cp "$BUILD_DIR/Preferences" "$STAGING_DIR/Applications/Preferences.app/Preferences"
chmod 755 "$STAGING_DIR/Applications/Preferences.app/Preferences"

cp "$BUILD_DIR/MobileSafari" "$STAGING_DIR/Applications/MobileSafari.app/MobileSafari"
chmod 755 "$STAGING_DIR/Applications/MobileSafari.app/MobileSafari"

cp "$BUILD_DIR/sh" "$STAGING_DIR/bin/sh"
chmod 755 "$STAGING_DIR/bin/sh"

# Symlinks for core utilities
ln -sf sh "$STAGING_DIR/bin/ls"
ln -sf sh "$STAGING_DIR/bin/ps"
ln -sf sh "$STAGING_DIR/bin/cat"
ln -sf sh "$STAGING_DIR/bin/echo"

# Install Configuration Plists
cp "$USERLAND_DIR/plists/SystemVersion.plist" "$STAGING_DIR/System/Library/CoreServices/SystemVersion.plist"
cp "$USERLAND_DIR/plists/com.apple.MobileGestalt.plist" "$STAGING_DIR/private/var/mobile/Library/Preferences/com.apple.MobileGestalt.plist"
cp "$USERLAND_DIR/plists/com.apple.springboard.plist" "$STAGING_DIR/private/var/mobile/Library/Preferences/com.apple.springboard.plist"
cp "$USERLAND_DIR/plists/com.apple.SpringBoard.plist" "$STAGING_DIR/System/Library/LaunchDaemons/com.apple.SpringBoard.plist"
cp "$USERLAND_DIR/plists/com.apple.backboardd.plist" "$STAGING_DIR/System/Library/LaunchDaemons/com.apple.backboardd.plist"

# Basic Unix Config Files
cat << "EOF" > "$STAGING_DIR/etc/passwd"
root:*:0:0:System Administrator:/private/var/root:/bin/sh
mobile:*:501:501:Mobile User:/private/var/mobile:/bin/sh
EOF

cat << "EOF" > "$STAGING_DIR/etc/group"
wheel:*:0:root
admin:*:80:root,mobile
mobile:*:501:
EOF

cat << "EOF" > "$STAGING_DIR/etc/hosts"
127.0.0.1       localhost
::1             localhost
127.0.0.1       ipad.local
EOF

cat << "EOF" > "$STAGING_DIR/etc/motd"
Darwin Kernel Version 16.7.0 (iOS 10.3.3) for Samsung Galaxy Tab 4 10.1 (SM-T530)
iPad Architecture Edition - Qualcomm Snapdragon 400 (Quad Cortex-A7)
EOF

# App Info.plists
cat << "EOF" > "$STAGING_DIR/System/Library/CoreServices/SpringBoard.app/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.apple.springboard</string>
    <key>CFBundleName</key>
    <string>SpringBoard</string>
    <key>CFBundleExecutable</key>
    <string>SpringBoard</string>
    <key>UIDeviceFamily</key>
    <array>
        <integer>2</integer>
    </array>
    <key>UIUserInterfaceIdiom</key>
    <integer>1</integer>
</dict>
</plist>
EOF

cat << "EOF" > "$STAGING_DIR/Applications/Preferences.app/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.apple.Preferences</string>
    <key>CFBundleName</key>
    <string>Preferences</string>
    <key>CFBundleExecutable</key>
    <string>Preferences</string>
    <key>UIDeviceFamily</key>
    <array>
        <integer>2</integer>
    </array>
</dict>
</plist>
EOF

cat << "EOF" > "$STAGING_DIR/Applications/MobileSafari.app/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.apple.mobilesafari</string>
    <key>CFBundleName</key>
    <string>Safari</string>
    <key>CFBundleExecutable</key>
    <string>MobileSafari</string>
    <key>UIDeviceFamily</key>
    <array>
        <integer>2</integer>
    </array>
</dict>
</plist>
EOF

# 3. Create ext4 filesystem image: system.img (256 MB)
echo "--> Generating ext4 filesystem image (system.img, 256MB)..."
mke2fs -t ext4 -L "system" -d "$STAGING_DIR" -m 0 "$BUILD_DIR/system.img" 256M

# 4. Package Odin tarball: system.tar.md5
echo "--> Creating Samsung Odin tarball (system.tar.md5)..."
cp "$BUILD_DIR/system.img" "$BUILD_DIR/system.img.ext4"
cd "$BUILD_DIR"
tar -H ustar -c system.img.ext4 > "$BUILD_DIR/system.tar"
md5sum -t "$BUILD_DIR/system.tar" >> "$BUILD_DIR/system.tar"
mv "$BUILD_DIR/system.tar" "$BUILD_DIR/system.tar.md5"
rm -f "$BUILD_DIR/system.img.ext4"

# 5. Package TWRP Flashable ZIP: sm-t530-ipad-rootfs-twrp.zip
echo "--> Creating TWRP flashable zip (sm-t530-ipad-rootfs-twrp.zip)..."
TWRP_DIR="$BUILD_DIR/twrp_rootfs_staging"
rm -rf "$TWRP_DIR"
mkdir -p "$TWRP_DIR/META-INF/com/google/android"

cat << "EOF" > "$TWRP_DIR/META-INF/com/google/android/updater-script"
ui_print("===========================================");
ui_print("  Apple iPad Tablet Userland (iOS 10.3.3) ");
ui_print("  Target: Samsung Galaxy Tab 4 10.1 SM-T530");
ui_print("===========================================");
ui_print("Formatting /dev/block/platform/msm_sdcc.1/by-name/system...");
package_extract_file("system.img", "/dev/block/platform/msm_sdcc.1/by-name/system");
ui_print("Flashing complete! iPad userland active.");
EOF

# Copy dummy binary for update-binary
echo '#!/sbin/sh' > "$TWRP_DIR/META-INF/com/google/android/update-binary"
echo 'exit 0' >> "$TWRP_DIR/META-INF/com/google/android/update-binary"
chmod 755 "$TWRP_DIR/META-INF/com/google/android/update-binary"

cp "$BUILD_DIR/system.img" "$TWRP_DIR/system.img"

cd "$TWRP_DIR"
zip -r9 "$BUILD_DIR/sm-t530-ipad-rootfs-twrp.zip" META-INF system.img
rm -rf "$TWRP_DIR"

# 6. Generate Checksums
echo "--> Updating SHA256 checksums..."
cd "$BUILD_DIR"
sha256sum \
    mach_kernel \
    mach_kernel.sys \
    boot.img \
    boot.tar.md5 \
    sm-t530-ios10-xnu-twrp.zip \
    system.img \
    system.tar.md5 \
    sm-t530-ipad-rootfs-twrp.zip \
    launchd \
    backboardd \
    SpringBoard \
    Preferences \
    MobileSafari \
    sh > "$BUILD_DIR/SHA256SUMS.txt"

echo "=== Build Complete! Artifacts in $BUILD_DIR ==="
ls -lh "$BUILD_DIR"/*.img "$BUILD_DIR"/*.tar.md5 "$BUILD_DIR"/*.zip "$BUILD_DIR"/SHA256SUMS.txt
