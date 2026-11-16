# Apple iPad Tablet Userland (iOS 10.3.3) on Samsung Galaxy Tab 4 10.1 (SM-T530)

## Architecture Overview
The SM-T530 (Qualcomm Snapdragon 400 APQ8026 / MSM8226, 4x ARM Cortex-A7 @ 1.2 GHz) runs a 32-bit ARMv7-A Darwin 16.7.0 kernel configured for the Apple iPad tablet class (`iPad3,1` / `j1ap`).

The userland stack runs Mach-O ARMv7 binaries with AMFI code signing bypass, rendering directly to Qualcomm MDSS 1280x800 WXGA framebuffer at `0x03200000`.

---

## Filesystem Layout

```
/
├── bin/
│   ├── sh                   (Darwin ARMv7 interactive shell)
│   ├── ls -> sh
│   ├── ps -> sh
│   ├── cat -> sh
│   └── echo -> sh
├── sbin/
│   └── launchd              (PID 1 system bootstrap)
├── etc/
│   ├── passwd
│   ├── group
│   ├── hosts
│   └── motd
├── dev/
├── private/var/mobile/
│   ├── Containers/
│   ├── Media/
│   └── Library/Preferences/
│       ├── com.apple.MobileGestalt.plist   (DeviceClass=iPad, UIUserInterfaceIdiom=1)
│       └── com.apple.springboard.plist     (6-app dock, split-view enabled)
├── System/Library/
│   ├── CoreServices/
│   │   ├── SystemVersion.plist             (iOS 10.3.3, Build 14G60)
│   │   ├── backboardd                      (Hardware Touch & Keypad router)
│   │   └── SpringBoard.app/
│   │       ├── Info.plist                  (UIDeviceFamily=2 [iPad])
│   │       └── SpringBoard                 (iPad UI WindowServer)
│   ├── Frameworks/
│   │   ├── UIKit.framework
│   │   ├── CoreFoundation.framework
│   │   ├── QuartzCore.framework
│   │   └── IOKit.framework
│   └── LaunchDaemons/
│       ├── com.apple.SpringBoard.plist
│       └── com.apple.backboardd.plist
└── Applications/
    ├── Preferences.app/                     (iPad 2-column Split View Settings)
    ├── MobileSafari.app/                    (iPad desktop-class tabs)
    ├── MobileSlideShow.app/
    ├── Camera.app/
    └── Calculator.app/
```

---

## Flashing Instructions

### Method 1: TWRP Recovery (Recommended)
1. Copy `sm-t530-ipad-rootfs-twrp.zip` and `sm-t530-ios10-xnu-twrp.zip` to a microSD card or internal storage.
2. Boot into TWRP recovery (**[Power] + [Volume Up] + [Home]**).
3. Flash `sm-t530-ios10-xnu-twrp.zip` (flashes Darwin Mach-O kernel to boot partition).
4. Flash `sm-t530-ipad-rootfs-twrp.zip` (extracts iPad `system.img` to `/dev/block/platform/msm_sdcc.1/by-name/system`).
5. Reboot system.

### Method 2: Samsung Odin (Download Mode)
1. Boot into Download Mode (**[Power] + [Volume Down] + [Home]**, then **[Volume Up]**).
2. Open Odin v3.09 or v3.10.
3. Place `boot.tar.md5` in **AP** / **PDA** slot to flash Darwin kernel.
4. Place `system.tar.md5` in **AP** / **PDA** slot to flash the iPad system partition.
5. Click **Start**.
