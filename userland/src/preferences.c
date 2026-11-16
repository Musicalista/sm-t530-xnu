/*
 * preferences.c - Apple iPad Preferences (Settings) App
 * Target: Samsung Galaxy Tab 4 10.1 (SM-T530 / matissewifi)
 * Layout: Split View (Sidebar + Detail View) - UIUserInterfaceIdiomPad (1)
 */

#include "userland.h"

void draw_preferences_ui(void) {
    /* 1. Clear background to iOS light gray / dark slate */
    fb_fill(COLOR_CARD_BG);

    /* 2. Top Navigation Bar */
    fb_draw_rect(0, 0, FB_WIDTH, 48, COLOR_STATUSBAR);
    fb_draw_text(16, 16, "< Settings", COLOR_IOS_BLUE, 2);
    fb_draw_text(FB_WIDTH / 2 - 30, 16, "About", COLOR_WHITE, 2);

    /* 3. Left Sidebar (360px wide) */
    uint32_t sidebar_w = 340;
    fb_draw_rect(0, 48, sidebar_w, FB_HEIGHT - 48, COLOR_DOCK_GLASS);
    fb_draw_rect(sidebar_w, 48, 2, FB_HEIGHT - 48, COLOR_DOCK_BORDER);

    /* Sidebar Items */
    const char *items[] = {
        "Airplane Mode",
        "Wi-Fi",
        "Bluetooth",
        "Do Not Disturb",
        "> General",
        "Display & Brightness",
        "Wallpaper",
        "Sounds",
        "Touch ID & Passcode",
        "Battery",
        "Privacy",
        "iCloud",
        "iTunes & App Store"
    };

    for (int i = 0; i < 13; i++) {
        uint32_t item_y = 60 + i * 50;
        if (i == 4) {
            /* Highlight active 'General' row */
            fb_draw_rect(4, item_y - 8, sidebar_w - 8, 44, COLOR_IOS_BLUE);
            fb_draw_text(24, item_y + 4, items[i], COLOR_WHITE, 2);
        } else {
            fb_draw_text(24, item_y + 4, items[i], COLOR_WHITE, 2);
        }
        fb_draw_rect(16, item_y + 40, sidebar_w - 32, 1, COLOR_DOCK_BORDER);
    }

    /* 4. Right Detail View (About this iPad) */
    uint32_t detail_x = sidebar_w + 30;
    uint32_t detail_w = FB_WIDTH - detail_x - 30;
    uint32_t table_y  = 70;

    fb_draw_rounded_rect(detail_x, table_y, detail_w, 680, 16, COLOR_STATUSBAR);

    struct KeyValue {
        const char *key;
        const char *val;
    };

    const struct KeyValue about_rows[] = {
        {"Name",             "iPad (4th generation)"},
        {"Capacity",         "16.0 GB"},
        {"Available",        "14.2 GB"},
        {"Version",          "10.3.3 (14G60) - iPadOS ARMv7 Edition"},
        {"Carrier",          "Wi-Fi"},
        {"Model",            "MD510LL/A (SM-T530)"},
        {"Serial Number",    "DMQLL0V1F185"},
        {"Wi-Fi Address",    "00:26:37:A1:8B:24"},
        {"SoC / CPU",        "Qualcomm Snapdragon 400 (APQ8026 Quad Cortex-A7)"},
        {"Display",          "10.1\" WXGA 1280x800 TFT LCD Panel"},
        {"RAM",              "1.5 GB LPDDR3"},
        {"Touch Digitizer",  "Atmel maXTouch mXT1664T (10-point)"},
        {"Kernel",           "Darwin 16.7.0 (xnu-3789.70.16~1/RELEASE_ARM_T530)"},
        {"Security",         "AMFI Codesign Bypass Active (Testing Mode)"}
    };

    for (int i = 0; i < 14; i++) {
        uint32_t row_y = table_y + 16 + i * 46;
        fb_draw_text(detail_x + 20, row_y, about_rows[i].key, COLOR_LIGHT_GRAY, 2);

        /* Right-aligned or offset value */
        fb_draw_text(detail_x + 260, row_y, about_rows[i].val, COLOR_WHITE, 2);

        if (i < 13) {
            fb_draw_rect(detail_x + 20, row_y + 36, detail_w - 40, 1, COLOR_DOCK_BORDER);
        }
    }
}

void _start(void) {
    klog("[Preferences] Launching Preferences.app (PID 48)...\n");
    klog("[Preferences] Idiom: UIUserInterfaceIdiomPad. Rendering split view.\n");

    draw_preferences_ui();

    while (1) {
        for (volatile int i = 0; i < 50000000; i++);
    }
}
