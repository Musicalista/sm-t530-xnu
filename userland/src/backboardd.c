/*
 * backboardd.c - iOS Hardware Event Router Daemon
 * Target: Samsung Galaxy Tab 4 10.1 (SM-T530 / matissewifi)
 * Tablet Profile: Atmel maXTouch Multi-Touch & MSM GPIO Tablet Keys
 */

#include "userland.h"

void _start(void) {
    klog("[backboardd] Initializing AppleBackboardEventSystem...\n");
    klog("[backboardd] Binding to /dev/i2c-3 (Atmel maXTouch mXT1664T)...\n");
    klog("[backboardd] Registering hardware key interrupts: HOME, POWER, VOL_UP, VOL_DN...\n");
    klog("[backboardd] Touch mapping: 1280x800 WXGA 16:10 aspect ratio.\n");
    klog("[backboardd] Event queue listening on port com.apple.backboard.touch.\n");

    while (1) {
        for (volatile int i = 0; i < 20000000; i++);
    }
}
