#ifndef __DARWIN_BOOT_H__
#define __DARWIN_BOOT_H__

#include "t530_types.h"
#include "msm8226_regs.h"

/*
 * Darwin / XNU (iOS 10.3.3 / Darwin 16.7.0) ARMv7 Boot Structures
 * Apple iPad-class display & SMP architecture for SM-T530
 */

#define BOOT_LINE_LENGTH            1024U
#define DARWIN_ARM_BOOT_ARGS_VERSION 1U

/* Mach-O 32-bit Constants */
#define MH_MAGIC                    0xFEEDFACEU
#define CPU_TYPE_ARM                12U
#define CPU_SUBTYPE_ARM_V7          9U
#define MH_EXECUTE                  0x2U

/* Apple Boot Video Information */
struct Boot_Video {
    uint32_t v_baseAddr;   /* Physical/Virtual Framebuffer Address */
    uint32_t v_display;    /* Display Mode */
    uint32_t v_rowBytes;   /* Bytes per row (Stride: 2560) */
    uint32_t v_width;      /* 1280 */
    uint32_t v_height;     /* 800 */
    uint32_t v_depth;      /* 16 (RGB565) or 32 (ARGB) */
};

/* Darwin ARM Boot Arguments */
struct arm_boot_args {
    uint16_t          Revision;
    uint16_t          Version;
    uint32_t          virtBase;
    uint32_t          physBase;
    uint32_t          memSize;
    uint32_t          topOfKernelData;
    struct Boot_Video Video;
    uint32_t          machineType;
    void             *deviceTreeP;
    uint32_t          deviceTreeLength;
    char              commandLine[BOOT_LINE_LENGTH];
};

/* Platform Expert Subsystem Functions */
void pe_kprintf(const char *fmt, ...);
void msm8226_uart_init(void);
void msm8226_gic_init(void);
void msm8226_timer_init(void);
void msm8226_fb_init(void);
void msm8226_smp_init(void);
void msm8226_touch_init(void);
void msm8226_keypad_init(void);

#endif /* __DARWIN_BOOT_H__ */
