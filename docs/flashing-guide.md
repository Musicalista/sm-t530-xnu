# Flashing & Installation Guide: Samsung Galaxy Tab 4 10.1 (SM-T530)
**Kernel Target**: Darwin / XNU 16.7.0 (iOS 10.3.3) — iPad Architecture Profile  
**Binary Packages**: `boot.tar.md5` (Odin), `sm-t530-ios10-xnu-twrp.zip` (TWRP), `boot.img` (Fastboot/dd)

---

## Method 1: Samsung Odin (Recommended)

1. **Power off** the Galaxy Tab 4 10.1 completely.
2. Enter **Download Mode**:
   - Hold **Volume Down (-) + Home Button + Power Button** simultaneously.
   - When the warning prompt appears on the 10.1" screen, press **Volume Up (+)** to continue into Download Mode.
3. Connect the tablet to your PC via micro-USB.
4. Launch **Odin3 v3.07**, **v3.10**, or **v3.14.4**.
   - Verify that the `ID:COM` box indicates an active connection.
5. In Odin:
   - Click the **AP** (or **PDA**) slot button.
   - Select `boot.tar.md5`.
   - Ensure **Auto Reboot** and **F. Reset Time** are checked.
   - **Do NOT** check Re-Partition.
6. Click **Start**.
7. Odin will write the Darwin kernel to the boot partition and reboot.

---

## Method 2: TWRP Recovery ZIP

1. Copy `sm-t530-ios10-xnu-twrp.zip` to your microSD card or internal storage.
2. Power off the tablet.
3. Enter **Recovery Mode**:
   - Hold **Volume Up (+) + Home Button + Power Button** until the Samsung Galaxy Tab 4 logo appears, then release.
4. In TWRP:
   - Tap **Install**.
   - Select `sm-t530-ios10-xnu-twrp.zip`.
   - Swipe to confirm flash.
5. Tap **Reboot System**.

---

## Method 3: Direct Shell / dd Flashing

If you have root access in an Android shell or TWRP terminal:

```sh
adb push boot.img /sdcard/boot.img
adb shell
su
dd if=/sdcard/boot.img of=/dev/block/platform/msm_sdcc.1/by-name/boot bs=2048
reboot
```
