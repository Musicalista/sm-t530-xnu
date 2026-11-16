/*
 * springboard.c - Apple iPad SpringBoard (Home Screen & UI Compositor)
 * Target: Samsung Galaxy Tab 4 10.1 (SM-T530 / matissewifi)
 * Resolution: 1280x800 WXGA 16:10 | Idiom: UIUserInterfaceIdiomPad (1)
 */

#include "userland.h"

struct AppIcon {
    const char *name;
    uint16_t   color;
    char       glyph;
};

static const struct AppIcon g_grid_apps[24] = {
    {"Safari",      COLOR_IOS_BLUE,   'S'},
    {"Mail",        COLOR_IOS_BLUE,   'M'},
    {"Photos",      COLOR_WHITE,      'P'},
    {"Camera",      COLOR_IOS_GRAY,   'C'},
    {"Maps",        COLOR_IOS_GREEN,  'M'},
    {"Clock",       COLOR_BLACK,      'T'},

    {"Weather",     COLOR_IOS_BLUE,   'W'},
    {"News",        COLOR_IOS_RED,    'N'},
    {"Notes",       COLOR_IOS_ORANGE, 'N'},
    {"Reminders",   COLOR_WHITE,      'R'},
    {"Calendar",    COLOR_WHITE,      'C'},
    {"Contacts",    COLOR_IOS_GRAY,   'C'},

    {"App Store",   COLOR_IOS_BLUE,   'A'},
    {"iTunes Store",COLOR_IOS_RED,    'I'},
    {"iBooks",      COLOR_IOS_ORANGE, 'B'},
    {"Podcasts",    COLOR_CARD_BG,    'P'},
    {"Videos",      COLOR_CARD_BG,    'V'},
    {"Game Center", COLOR_WHITE,      'G'},

    {"Preferences", COLOR_IOS_GRAY,   'P'},
    {"FaceTime",    COLOR_IOS_GREEN,  'F'},
    {"Photo Booth", COLOR_IOS_RED,    'B'},
    {"Calculator",  COLOR_BLACK,      '+'},
    {"Files",       COLOR_IOS_BLUE,   'F'},
    {"Terminal",    COLOR_BLACK,      '>'}
};

static const struct AppIcon g_dock_apps[6] = {
    {"Safari",      COLOR_IOS_BLUE,   'S'},
    {"Mail",        COLOR_IOS_BLUE,   'M'},
    {"Photos",      COLOR_WHITE,      'P'},
    {"Music",       COLOR_IOS_RED,    'M'},
    {"Preferences", COLOR_IOS_GRAY,   'P'},
    {"Camera",      COLOR_IOS_GRAY,   'C'}
};

void draw_icon(uint32_t cx, uint32_t cy, uint32_t size, uint16_t color, char glyph, const char *name) {
    uint32_t x = cx - size / 2;
    uint32_t y = cy - size / 2;

    /* Draw rounded icon body */
    fb_draw_rounded_rect(x, y, size, size, 14, color);

    /* Draw icon glyph centered */
    fb_draw_char(cx - 5, cy - 7, glyph, (color == COLOR_WHITE) ? COLOR_BLACK : COLOR_WHITE, 2);

    /* Draw label underneath */
    uint32_t len = 0;
    for (const char *p = name; *p; p++) len++;
    uint32_t text_x = cx - (len * 6) / 2;
    fb_draw_text(text_x, y + size + 8, name, COLOR_WHITE, 1);
}

void draw_status_bar(void) {
    /* Status bar background */
    fb_draw_rect(0, 0, FB_WIDTH, 24, COLOR_STATUSBAR);

    /* Left: "iPad" carrier and Wi-Fi symbol */
    fb_draw_text(16, 8, "iPad   Wi-Fi", COLOR_WHITE, 1);

    /* Center: "9:41 AM" */
    fb_draw_text(FB_WIDTH / 2 - 24, 8, "9:41 AM", COLOR_WHITE, 1);

    /* Right: "100%" battery */
    fb_draw_text(FB_WIDTH - 90, 8, "100% [===]", COLOR_WHITE, 1);
}

void draw_dock(void) {
    /* iPad Floating Glass Dock */
    uint32_t dock_w = 980;
    uint32_t dock_h = 100;
    uint32_t dock_x = (FB_WIDTH - dock_w) / 2;
    uint32_t dock_y = FB_HEIGHT - dock_h - 16;

    /* Outer glass shelf */
    fb_draw_rounded_rect(dock_x, dock_y, dock_w, dock_h, 24, COLOR_DOCK_GLASS);
    fb_draw_rounded_rect(dock_x + 2, dock_y + 2, dock_w - 4, 3, 2, COLOR_DOCK_BORDER);

    /* Pinned 6 Dock apps */
    uint32_t slot_w = dock_w / 6;
    for (uint32_t i = 0; i < 6; i++) {
        uint32_t cx = dock_x + slot_w * i + slot_w / 2;
        uint32_t cy = dock_y + dock_h / 2 - 4;
        draw_icon(cx, cy, 64, g_dock_apps[i].color, g_dock_apps[i].glyph, g_dock_apps[i].name);
    }
}

void draw_grid(void) {
    /* 6 columns x 4 rows */
    uint32_t start_x = 100;
    uint32_t start_y = 65;
    uint32_t col_spacing = 180;
    uint32_t row_spacing = 120;

    for (uint32_t row = 0; row < 4; row++) {
        for (uint32_t col = 0; col < 6; col++) {
            uint32_t idx = row * 6 + col;
            uint32_t cx = start_x + col * col_spacing + col_spacing / 2;
            uint32_t cy = start_y + row * row_spacing + 35;
            draw_icon(cx, cy, 68, g_grid_apps[idx].color, g_grid_apps[idx].glyph, g_grid_apps[idx].name);
        }
    }
}

void _start(void) {
    klog("[SpringBoard] Starting Apple iPad SpringBoard (PID 32)...\n");
    klog("[SpringBoard] Read /private/var/mobile/Library/Preferences/com.apple.MobileGestalt.plist\n");
    klog("[SpringBoard] Configured for iPad tablet UI (1280x800, WXGA 16:10, 6x4 icon grid, 6-app dock)\n");

    /* Render iPad Wallpaper Background */
    fb_fill(COLOR_BG_DARK);

    /* Draw UI Components */
    draw_status_bar();
    draw_grid();
    draw_dock();

    klog("[SpringBoard] iPad Home Screen rendered to IOMobileFramebuffer successfully.\n");
    klog("[SpringBoard] Listening for Atmel touch events and home button gestures.\n");

    while (1) {
        for (volatile int i = 0; i < 50000000; i++);
    }
}
