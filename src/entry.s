/*
 * entry.s - Low-Level ARMv7 Entry Trampoline & Linux zImage Header
 * Target: Samsung Galaxy Tab 4 10.1 (SM-T530 / matissewifi, Qualcomm APQ8026)
 * Darwin 16.7.0 (iOS 10.3.3)
 */

.text
.arm
.globl __entry
.globl __start

__entry:
    /* Standard ARM Linux zImage header at offset 0 */
    b       __start                 /* 0x00: Branch to real entry point */
    .word   0x00000000              /* 0x04: Reserved */
    .word   0x00000000              /* 0x08: Reserved */
    .word   0x00000000              /* 0x0C: Reserved */
    .word   0x00000000              /* 0x10: Reserved */
    .word   0x00000000              /* 0x14: Reserved */
    .word   0x00000000              /* 0x18: Reserved */
    .word   0x00000000              /* 0x1C: Reserved */
    .word   0x00000000              /* 0x20: Reserved */
    .word   0x016f2818              /* 0x24: Linux zImage Magic */
    .word   0x00008000              /* 0x28: Kernel Start Address */
    .word   0x00200000              /* 0x2C: Kernel End Address */

__start:
    /* 1. Ensure CPU is in Supervisor (SVC) mode with interrupts masked */
    msr     cpsr_c, #0xD3

    /* 2. Save incoming bootloader registers */
    mov     r4, r0                  /* r0 = 0 */
    mov     r5, r1                  /* r1 = Machine ID */
    mov     r6, r2                  /* r2 = ATAGS / DTB pointer */

    /* 3. Invalidate Cortex-A7 Caches & TLB via CP15 */
    mov     r0, #0
    mcr     p15, 0, r0, c7, c7, 0   /* Invalidate entire I/D cache */
    mcr     p15, 0, r0, c8, c7, 0   /* Invalidate unified TLB */
    dsb                             /* Data Synchronization Barrier */
    isb                             /* Instruction Synchronization Barrier */

    /* 4. Disable MMU, Alignment faults, enable I-Cache initially */
    mrc     p15, 0, r0, c1, c0, 0   /* Read SCTLR */
    bic     r0, r0, #0x00000001     /* Disable MMU */
    bic     r0, r0, #0x00000002     /* Disable Alignment checking */
    bic     r0, r0, #0x00000004     /* Disable D-Cache */
    orr     r0, r0, #0x00001000     /* Enable I-Cache */
    mcr     p15, 0, r0, c1, c0, 0   /* Write SCTLR */

    /* 5. Enable SMP coherency in Cortex-A7 ACTLR (bit 6) */
    mrc     p15, 0, r0, c1, c0, 1   /* Read ACTLR */
    orr     r0, r0, #(1 << 6)       /* Enable SMP mode */
    mcr     p15, 0, r0, c1, c0, 1   /* Write ACTLR */
    isb

    /* 6. Enable VFPv4 & NEON Coprocessors (CP10 and CP11) */
    mrc     p15, 0, r0, c1, c0, 2   /* Read CPACR */
    orr     r0, r0, #0x00F00000     /* Full access for CP10 & CP11 */
    mcr     p15, 0, r0, c1, c0, 2   /* Write CPACR */
    isb
    mov     r0, #0x40000000         /* VFP Enable bit in FPEXC */
    vmsr    fpexc, r0

    /* 7. Early visual checkpoint: paint top 20 rows of 1280x800 LCD with iOS Cyan (0x07FF) */
    ldr     r7, =0x03200000         /* Framebuffer physical address */
    ldr     r8, =0x07FF07FF         /* Packed 16-bit RGB565 Cyan color */
    ldr     r9, =12800              /* 1280 pixels * 20 rows / 2 (words) */
paint_bar_loop:
    str     r8, [r7], #4
    subs    r9, r9, #1
    bne     paint_bar_loop

    /* 8. Initialize early bootstrap stack in safe DRAM (0x01FF0000) */
    ldr     sp, =0x01FF0000

    /* 9. Pass bootloader arguments to C initialization */
    mov     r0, r4                  /* boot argument 0 */
    mov     r1, r5                  /* machine type */
    mov     r2, r6                  /* ATAGS / DTB pointer */
    bl      _darwin_arm_init

    /* Infinite loop fallback if kernel halts */
halt_loop:
    wfe
    b       halt_loop
