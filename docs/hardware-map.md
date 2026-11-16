# Qualcomm Snapdragon 400 (MSM8226 / APQ8026) Hardware Architecture
**Target Device**: Samsung Galaxy Tab 4 10.1 (SM-T530 / matissewifi)  
**Architecture**: ARMv7-A (Quad-core ARM Cortex-A7 @ 1.2 GHz)  
**Darwin Version**: Darwin 16.7.0 (iOS 10.3.3) — iPad Architecture Profile

---

## 1. Physical Memory Map

| Region | Physical Address Range | Size | Function / Description |
|---|---|---|---|
| **DRAM Base** | `0x00000000 - 0x60000000` | 1.5 GB | Mobile LPDDR3 SDRAM |
| **Darwin Kernel** | `0x00008000 - 0x00200000` | ~2 MB | Mach-O 32-bit `mach_kernel` |
| **Tags / QCDT** | `0x01E00000 - 0x01F00000` | 1 MB | Kernel tags & parameter block |
| **Early Stack** | `0x01FF0000 - 0x02000000` | 64 KB | Bootstrap SVC stack |
| **Darwin Ramdisk**| `0x02000000 - 0x03000000` | 16 MB | Staging HFS+ Root Ramdisk |
| **Framebuffer** | `0x03200000 - 0x03400000` | 2 MB | 1280x800 WXGA RGB565 display buffer |

---

## 2. Qualcomm MSM8226 / APQ8026 MMIO Peripherals

| Subsystem | Base Physical Address | Key Registers & Offsets |
|---|---|---|
| **GIC Distributor** | `0xF9000000` | `+0x00` CTLR, `+0x100` ISENABLER, `+0x400` IPRIORITYR |
| **GIC CPU Interface**| `0xF9002000` | `+0x00` CTLR, `+0x04` PMR, `+0x0C` IAR, `+0x10` EOIR |
| **UARTDM (Console)**| `0xF991E000` | `+0x08` SR, `+0x10` CR, `+0x40` NCF_TX, `+0x70` TF (115200 8N1) |
| **AP System Timer** | `0xF9020000` | CP15 Architected Generic Timer (100 Hz Mach tick) |
| **MDSS Display** | `0xFD900000` | 1280x800 WXGA 10.1" TFT LCD panel interface |
| **I2C Touch** | `0xF9924000` | Atmel maXTouch multi-touch digitizer (`0x4A`) |

---

## 3. Bootloader Parameters (Qualcomm Little Kernel / LK)

- **Device Codename**: `matissewifi`, `matissewifiue`
- **Page Size**: `2048` bytes
- **Kernel Base**: `0x00000000`
- **Kernel Offset**: `0x00008000` (`0x00008000`)
- **Ramdisk Offset**: `0x02000000` (`0x02000000`)
- **Tags Offset**: `0x01E00000` (`0x01E00000`)
- **DT Format**: Qualcomm QCDT (`51 43 44 54`) v1/v2 table
- **Cmdline**: `console=null androidboot.hardware=qcom user_debug=23 root=/dev/ram0 rw`
- **Trailer**: `SEANDROIDENFORCE`
- **Flash Partition**: `/dev/block/platform/msm_sdcc.1/by-name/boot`
