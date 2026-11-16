#!/usr/bin/env python3
"""
patch_kernel_zimage.py - Patch Mach-O kernel binary into executable ARM Linux zImage for Qualcomm LK
Calculates branch to __entry and inserts ARM zImage magic at offset 0x24.
"""

import sys
import struct
import subprocess

def get_entry_address(sys_path, nm_path):
    cmd = [nm_path, sys_path]
    res = subprocess.run(cmd, capture_output=True, text=True, check=True)
    for line in res.stdout.splitlines():
        if "__entry" in line:
            parts = line.split()
            return int(parts[0], 16)
    raise RuntimeError("Symbol __entry not found in " + sys_path)

def main():
    if len(sys.argv) < 5:
        print(f"Usage: {sys.argv[0]} <mach_kernel.sys> <mach_kernel> <toolchain_nm> <output_zImage>")
        sys.exit(1)

    sys_path = sys.argv[1]
    mach_path = sys.argv[2]
    nm_path = sys.argv[3]
    out_path = sys.argv[4]

    entry_addr = get_entry_address(sys_path, nm_path)
    base_addr = 0x00008000
    offset = entry_addr - (base_addr + 8)
    branch_imm24 = (offset >> 2) & 0x00FFFFFF
    branch_opcode = 0xEA000000 | branch_imm24

    with open(mach_path, "rb") as f:
        data = bytearray(f.read())

    # 1. Insert ARM Branch to __entry at offset 0x00
    struct.pack_into("<I", data, 0x00, branch_opcode)

    # 2. Insert Linux zImage Header at offset 0x24
    ZIMAGE_MAGIC = 0x016f2818
    start_addr = base_addr
    end_addr = base_addr + len(data)

    struct.pack_into("<I", data, 0x24, ZIMAGE_MAGIC)
    struct.pack_into("<I", data, 0x28, start_addr)
    struct.pack_into("<I", data, 0x2C, end_addr)

    with open(out_path, "wb") as f:
        f.write(data)

    print(f"[*] Successfully patched zImage: {out_path}")
    print(f"    Base Address:   0x{base_addr:08x}")
    print(f"    Entry Symbol:   0x{entry_addr:08x}")
    print(f"    Branch Opcode:  0x{branch_opcode:08x} (b 0x{entry_addr:08x})")
    print(f"    zImage Magic:   0x{ZIMAGE_MAGIC:08x} at offset 0x24")
    print(f"    Kernel Range:   0x{start_addr:08x} - 0x{end_addr:08x}")

if __name__ == "__main__":
    main()
