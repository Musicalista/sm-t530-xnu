#!/usr/bin/env python3
"""
Standalone Android boot.img v0 packager for Qualcomm MSM8226 / APQ8026 platforms.
Generates compliant boot images for Samsung Galaxy Tab 4 10.1 (SM-T530 / matissewifi).
"""

import argparse
import os
import struct
import hashlib

BOOT_MAGIC = b"ANDROID!"
BOOT_MAGIC_SIZE = 8
BOOT_NAME_SIZE = 16
BOOT_ARGS_SIZE = 512
BOOT_EXTRA_ARGS_SIZE = 1024

def write_padded(f_out, data, page_size):
    f_out.write(data)
    pad = (page_size - (len(data) & (page_size - 1))) & (page_size - 1)
    f_out.write(b'\x00' * pad)

def main():
    parser = argparse.ArgumentParser(description="Package Android boot.img v0 for Qualcomm MSM8226")
    parser.add_argument("--kernel", required=True, help="path to kernel binary")
    parser.add_argument("--ramdisk", default=None, help="path to ramdisk binary")
    parser.add_argument("--second", default=None, help="path to second bootloader")
    parser.add_argument("--dt", default=None, help="path to device tree blob / dt.img")
    parser.add_argument("--base", type=lambda x: int(x, 0), default=0x00000000)
    parser.add_argument("--kernel_offset", type=lambda x: int(x, 0), default=0x00008000)
    parser.add_argument("--ramdisk_offset", type=lambda x: int(x, 0), default=0x02000000)
    parser.add_argument("--second_offset", type=lambda x: int(x, 0), default=0x00f00000)
    parser.add_argument("--tags_offset", type=lambda x: int(x, 0), default=0x01e00000)
    parser.add_argument("--pagesize", type=lambda x: int(x, 0), default=2048)
    parser.add_argument("--cmdline", default="console=null androidboot.hardware=qcom user_debug=23 root=/dev/ram0 rw")
    parser.add_argument("--board", default="matissewifi")
    parser.add_argument("-o", "--output", required=True, help="output boot.img path")
    args = parser.parse_args()

    with open(args.kernel, "rb") as f:
        kernel_data = f.read()

    ramdisk_data = b""
    if args.ramdisk and os.path.exists(args.ramdisk):
        with open(args.ramdisk, "rb") as f:
            ramdisk_data = f.read()

    second_data = b""
    if args.second and os.path.exists(args.second):
        with open(args.second, "rb") as f:
            second_data = f.read()

    dt_data = b""
    if args.dt and os.path.exists(args.dt):
        with open(args.dt, "rb") as f:
            dt_data = f.read()

    kernel_size = len(kernel_data)
    kernel_addr = args.base + args.kernel_offset
    ramdisk_size = len(ramdisk_data)
    ramdisk_addr = args.base + args.ramdisk_offset
    second_size = len(second_data)
    second_addr = args.base + args.second_offset
    tags_addr = args.base + args.tags_offset
    page_size = args.pagesize
    dt_size = len(dt_data)

    os_version = 0

    name_bytes = args.board.encode("utf-8")[:BOOT_NAME_SIZE].ljust(BOOT_NAME_SIZE, b"\x00")
    cmdline_bytes = args.cmdline.encode("utf-8")[:BOOT_ARGS_SIZE].ljust(BOOT_ARGS_SIZE, b"\x00")

    # Compute SHA1 checksum
    sha = hashlib.sha1()
    sha.update(kernel_data)
    sha.update(struct.pack("<I", kernel_size))
    sha.update(ramdisk_data)
    sha.update(struct.pack("<I", ramdisk_size))
    sha.update(second_data)
    sha.update(struct.pack("<I", second_size))
    if dt_data:
        sha.update(dt_data)
        sha.update(struct.pack("<I", dt_size))
    digest = sha.digest().ljust(32, b"\x00")

    extra_cmdline = b"\x00" * BOOT_EXTRA_ARGS_SIZE

    # In Qualcomm boot_img_hdr, dt_size replaces unused at offset 36
    header = struct.pack(
        "<8s10I16s512s32s1024s",
        BOOT_MAGIC,
        kernel_size,
        kernel_addr,
        ramdisk_size,
        ramdisk_addr,
        second_size,
        second_addr,
        tags_addr,
        page_size,
        dt_size,
        os_version,
        name_bytes,
        cmdline_bytes,
        digest,
        extra_cmdline
    )

    with open(args.output, "wb") as f_out:
        write_padded(f_out, header, page_size)
        write_padded(f_out, kernel_data, page_size)
        if ramdisk_size > 0:
            write_padded(f_out, ramdisk_data, page_size)
        if second_size > 0:
            write_padded(f_out, second_data, page_size)
        if dt_size > 0:
            write_padded(f_out, dt_data, page_size)
        # Append exact 16-byte Samsung SEAndroid Enforcement footer
        f_out.write(b"SEANDROIDENFORCE")

    print(f"[*] Successfully packaged boot.img: {args.output}")
    print(f"    Kernel Size:  {kernel_size} bytes (Addr: 0x{kernel_addr:08x})")
    print(f"    Ramdisk Size: {ramdisk_size} bytes (Addr: 0x{ramdisk_addr:08x})")
    print(f"    DT Size:      {dt_size} bytes")
    print(f"    Page Size:    {page_size} bytes")
    print(f"    Base:         0x{args.base:08x}")
    print(f"    Cmdline:      {args.cmdline}")

if __name__ == "__main__":
    main()
