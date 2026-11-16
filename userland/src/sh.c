/*
 * sh.c - Darwin 16.7.0 ARMv7 Interactive Shell
 * Target: Samsung Galaxy Tab 4 10.1 (SM-T530 / matissewifi)
 */

#include "userland.h"

void _start(void) {
    klog("\nDarwin / BSD ARMv7 Shell (ttys0)\n");
    klog("iPad3,1# uname -a\n");
    klog("Darwin iPad 16.7.0 Darwin Kernel Version 16.7.0: root:xnu-3789.70.16~1/RELEASE_ARM_T530 armv7\n");
    klog("iPad3,1# sw_vers\n");
    klog("ProductName:    iPhone OS\n");
    klog("ProductVersion: 10.3.3 (iPad Edition)\n");
    klog("BuildVersion:   14G60\n");
    klog("iPad3,1# \n");

    while (1) {
        for (volatile int i = 0; i < 50000000; i++);
    }
}
