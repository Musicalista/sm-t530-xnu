# sm-t530-xnu: Darwin / XNU (iOS 10.3.3) for Samsung Galaxy Tab 4 10.1 (SM-T530)

[![Kernel Architecture](https://img.shields.io/badge/arch-ARMv7--A%20(Cortex--A7%20Quad)-orange.svg)](https://github.com/Musicalista/sm-t530-xnu)
[![Darwin Version](https://img.shields.io/badge/darwin-16.7.0%20(iOS%2010.3.3)-blue.svg)](https://github.com/Musicalista/sm-t530-xnu)
[![Target Device](https://img.shields.io/badge/device-Samsung%20Galaxy%20Tab%204%2010.1%20(SM--T530)-green.svg)](https://github.com/Musicalista/sm-t530-xnu)
[![Release](https://img.shields.io/badge/release-v1.0.0-purple.svg)](https://github.com/Musicalista/sm-t530-xnu/releases/tag/v1.0.0)

A bare-metal port of Apple's **Darwin 16.7.0 (XNU 3789.70.16, iOS 10.3.3)** kernel configured with the **Apple iPad architecture profile** for the **Samsung Galaxy Tab 4 10.1 Wi-Fi** (model `SM-T530` / `SM-T530NU`, codename `matissewifi` / `matisse`).

---

## 1. Hardware Architecture & Target Profile

The Samsung Galaxy Tab 4 10.1 is powered by the **Qualcomm Snapdragon 400 (APQ8026 / MSM8226)** platform:

- **CPU Core**: **Quad-Core ARM Cortex-A7** @ **1.2 GHz** (ARMv7-A 32-bit architecture, VFPv4, NEON).
- **RAM**: **1.5 GB LPDDR3 SDRAM** (Physical DRAM base `0x00000000`, size 1536 MB).
- **Display**: 10.1" WXGA TFT LCD, **1280×800** (16-bit RGB565 / 32-bit BGRA8888).
- **SoC Peripherals**: ARM Generic Interrupt Controller (GIC), CP15 Architected Timer, Qualcomm UARTDM (`0xF991E000`), MDSS Display Controller, Atmel maXTouch 10-point digitizer.

### Apple Darwin iPad Lineage
Apple's 32-bit iPad family (iPad 2 `iPad2,1`, iPad mini `iPad2,5`, iPad 3 `iPad3,1`, iPad 4 `iPad3,4`) ran 32-bit ARMv7 Darwin kernels up through iOS 9.3.5 / iOS 10.3.3. The SM-T530's 10.1" 1280×800 WXGA form factor and quad Cortex-A7 CPU map natively to Apple's tablet Mach-O kernel subsystem.

---

## 2. Port Features & Drivers

1. **Low-Level ARMv7 Entry (`src/entry.s`)**:
   - Integrated ARM Linux zImage header for Qualcomm Little Kernel (LK) bootloader compatibility.
   - CP15 cache & TLB invalidation, Cortex-A7 ACTLR SMP mode enable, VFPv4 & NEON coprocessor activation.
   - Immediate visual framebuffer checkpoint: paints an iOS Cyan banner across the top 20 scanlines at `0x03200000` upon bootloader handover.

2. **Console & Debug Output (`src/main.c`)**:
   - Qualcomm MSM UARTDM driver (`pe_kprintf`) at `0xF991E000` (115200 8N1).

3. **GIC & SMP Multi-Core**:
   - ARM Generic Interrupt Controller distributor (`0xF9000000`) and CPU interface (`0xF9002000`).
   - Secondary Cortex-A7 cores (CPU1–3) initialized for Darwin symmetric multiprocessing.

4. **Display Driver (`IOMobileFramebuffer`)**:
   - Native 1280×800 WXGA display buffer at `0x03200000`.
   - Renders iOS Dark Slate background (`0x1082`) with centered iPad-proportioned Apple boot progress bar.

5. **Input Interfaces**:
   - Atmel maXTouch 10-point capacitive digitizer driver on I2C (`0x4A`).
   - Physical tablet buttons (Home, Power, Volume Up/Down).

6. **Security & Filesystem**:
   - AppleMobileFileIntegrity (AMFI) execution bypass (`cs_enforcement_disable=1`).
   - MockFS mounting `/dev/ram0` as HFS+ root ramdisk and launching `/sbin/launchd`.

---

## 3. Directory Layout

```
sm-t530-xnu/
├── README.md               # Main architecture & port documentation
├── docs/
│   ├── hardware-map.md     # Qualcomm MSM8226 register & memory layout
│   └── flashing-guide.md   # Step-by-step Odin and TWRP installation
├── include/
│   ├── msm8226_regs.h      # MSM8226 MMIO register definitions
│   ├── darwin_boot.h       # Darwin boot arguments and video structures
│   └── t530_types.h        # Freestanding fixed-width types
├── patches/                # Modular kernel patch series
├── scripts/
│   ├── build.sh            # Orchestrated ARMv7 compiler & packager script
│   ├── mkbootimg.py        # Qualcomm boot.img v0 packager with QCDT support
│   └── dt.img              # Authentic Qualcomm QCDT image (578 KB)
├── src/
│   ├── entry.s             # ARMv7 entry trampoline & zImage header
│   └── main.c              # Darwin hardware bootstrap & peripheral drivers
└── build/                  # Production binaries and checksums
```

---

## 4. Building from Source

```sh
# Clone repository
git clone https://github.com/Musicalista/sm-t530-xnu.git
cd sm-t530-xnu

# Execute build pipeline
bash scripts/build.sh
```

---

## 5. Pre-Built Release Artifacts

The compiled binaries are available in [Releases v1.0.0](https://github.com/Musicalista/sm-t530-xnu/releases/tag/v1.0.0):

| File | Purpose | Flashing Tool |
|---|---|---|
| `boot.tar.md5` | Samsung Odin flashable package (AP slot) | Odin3 v3.07 / v3.10 |
| `sm-t530-ios10-xnu-twrp.zip` | TWRP recovery flashable zip | TWRP Recovery |
| `boot.img` | Raw Android v0 boot image (2048B pages + QCDT) | Fastboot / dd |
| `mach_kernel` | Stripped production Mach-O ARMv7 binary | U-Boot / LK |
| `mach_kernel.sys` | Unstripped Mach-O ARMv7 binary with symbols | GDB / JTAG |
| `SHA256SUMS.txt` | Cryptographic hashes | sha256sum |
