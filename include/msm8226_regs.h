#ifndef __MSM8226_REGS_H__
#define __MSM8226_REGS_H__

#include "t530_types.h"

/*
 * Qualcomm Snapdragon 400 (APQ8026 / MSM8226) Memory & Register Map
 * Target Device: Samsung Galaxy Tab 4 10.1 (SM-T530 / matissewifi)
 */

#define MSM8226_SDRAM_BASE          0x00000000U
#define MSM8226_KERNEL_ENTRY        0x00008000U
#define MSM8226_ATAGS_BASE          0x01E00000U
#define MSM8226_RAMDISK_BASE        0x02000000U
#define MSM8226_PAGE_SIZE           2048U
#define MSM8226_RAM_SIZE            (1536U * 1024U * 1024U) /* 1.5 GB LPDDR3 */

/* ARM Generic Interrupt Controller (GIC) on MSM8226 */
#define MSM8226_GIC_DIST_BASE       0xF9000000U
#define MSM8226_GIC_CPU_BASE        0xF9002000U

#define GICD_CTLR                   (MSM8226_GIC_DIST_BASE + 0x000U)
#define GICD_TYPER                  (MSM8226_GIC_DIST_BASE + 0x004U)
#define GICD_ISENABLER(n)           (MSM8226_GIC_DIST_BASE + 0x100U + (n) * 4U)
#define GICD_ICENABLER(n)           (MSM8226_GIC_DIST_BASE + 0x180U + (n) * 4U)
#define GICD_ISPENDR(n)             (MSM8226_GIC_DIST_BASE + 0x200U + (n) * 4U)
#define GICD_ICPENDR(n)             (MSM8226_GIC_DIST_BASE + 0x280U + (n) * 4U)
#define GICD_IPRIORITYR(n)          (MSM8226_GIC_DIST_BASE + 0x400U + (n) * 4U)
#define GICD_ITARGETSR(n)           (MSM8226_GIC_DIST_BASE + 0x800U + (n) * 4U)

#define GICC_CTLR                   (MSM8226_GIC_CPU_BASE + 0x000U)
#define GICC_PMR                    (MSM8226_GIC_CPU_BASE + 0x004U)
#define GICC_IAR                    (MSM8226_GIC_CPU_BASE + 0x00CU)
#define GICC_EOIR                   (MSM8226_GIC_CPU_BASE + 0x010U)

/* Qualcomm MSM UARTDM (High-Speed Serial Console) */
#define MSM_UARTDM_BASE             0xF991E000U
#define MSM_UARTDM_MR1              (MSM_UARTDM_BASE + 0x00U)
#define MSM_UARTDM_MR2              (MSM_UARTDM_BASE + 0x04U)
#define MSM_UARTDM_SR               (MSM_UARTDM_BASE + 0x08U)
#define MSM_UARTDM_CR               (MSM_UARTDM_BASE + 0x10U)
#define MSM_UARTDM_MISR             (MSM_UARTDM_BASE + 0x10U)
#define MSM_UARTDM_IMR              (MSM_UARTDM_BASE + 0x14U)
#define MSM_UARTDM_IPR              (MSM_UARTDM_BASE + 0x18U)
#define MSM_UARTDM_TF               (MSM_UARTDM_BASE + 0x70U)
#define MSM_UARTDM_RF               (MSM_UARTDM_BASE + 0x70U)
#define MSM_UARTDM_NCF_TX           (MSM_UARTDM_BASE + 0x40U)

#define UARTDM_SR_TXRDY             (1U << 2)
#define UARTDM_SR_TXEMT             (1U << 3)

/* Display & Framebuffer (1280x800 WXGA 10.1" TFT) */
#define T530_LCD_WIDTH              1280U
#define T530_LCD_HEIGHT             800U
#define T530_LCD_BPP                16U
#define T530_LCD_STRIDE             (T530_LCD_WIDTH * 2U) /* 2560 bytes */
#define T530_FB_SIZE                (T530_LCD_STRIDE * T530_LCD_HEIGHT) /* 2048000 bytes (2 MB) */
#define T530_FB_PHYS_BASE           0x03200000U

/* Touchscreen & Input */
#define T530_TSP_I2C_ADDR_ATMEL     0x4AU
#define T530_TSP_I2C_ADDR_MELFAS    0x48U

#endif /* __MSM8226_REGS_H__ */
