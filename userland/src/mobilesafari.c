/*
 * mobilesafari.c - Apple iPad MobileSafari Browser App
 * Target: Samsung Galaxy Tab 4 10.1 (SM-T530 / matissewifi)
 * Layout: iPad Desktop-Class Tabs & Address Bar - UIUserInterfaceIdiomPad (1)
 */

#include "userland.h"

void draw_safari_ui(void) {
    /* Background */
    fb_fill(COLOR_CARD_BG);

    /* 1. iPad Safari Tab Bar (Height 36px) */
    fb_draw_rect(0, 0, FB_WIDTH, 36, COLOR_STATUSBAR);

    /* Tab 1: Active "Apple" tab */
    fb_draw_rounded_rect(8, 6, 260, 30, 8, COLOR_CARD_BG);
    fb_draw_text(24, 14, "Apple - Start", COLOR_WHITE, 1);
    fb_draw_text(245, 14, "x", COLOR_IOS_GRAY, 1);

    /* Tab 2: Inactive "Documentation" tab */
    fb_draw_rounded_rect(276, 6, 260, 30, 8, COLOR_STATUSBAR);
    fb_draw_text(292, 14, "Darwin ARMv7 Kernel Docs", COLOR_LIGHT_GRAY, 1);
    fb_draw_text(515, 14, "x", COLOR_IOS_GRAY, 1);

    /* New Tab '+' button */
    fb_draw_text(550, 14, "+", COLOR_WHITE, 2);

    /* 2. Navigation Bar (Height 48px) */
    fb_draw_rect(0, 36, FB_WIDTH, 48, COLOR_STATUSBAR);
    fb_draw_text(16, 50, "<  >", COLOR_IOS_BLUE, 2);

    /* Centered URL Address Field */
    uint32_t url_w = 700;
    uint32_t url_x = (FB_WIDTH - url_w) / 2;
    fb_draw_rounded_rect(url_x, 42, url_w, 36, 10, COLOR_CARD_BG);
    fb_draw_text(url_x + 16, 52, "https://apple.com/ipad", COLOR_WHITE, 2);
    fb_draw_text(url_x + url_w - 30, 52, "R", COLOR_IOS_BLUE, 2); /* Reload */

    /* Share & Bookmarks on right */
    fb_draw_text(FB_WIDTH - 120, 50, "[^]  [B]  [+]", COLOR_IOS_BLUE, 2);

    /* Divider */
    fb_draw_rect(0, 84, FB_WIDTH, 2, COLOR_DOCK_BORDER);

    /* 3. Web Viewport Content */
    uint32_t content_y = 120;
    fb_draw_text(FB_WIDTH / 2 - 180, content_y, "Welcome to iPad Safari", COLOR_WHITE, 3);
    fb_draw_text(FB_WIDTH / 2 - 260, content_y + 50, "Running natively on Samsung Galaxy Tab 4 10.1 (SM-T530)", COLOR_LIGHT_GRAY, 2);

    /* Bookmarks Cards Grid */
    const char *bookmarks[] = {
        "Apple", "iCloud", "GitHub", "Wikipedia", "Reddit", "YouTube"
    };

    uint32_t b_start_x = 240;
    uint32_t b_spacing = 140;
    for (int i = 0; i < 6; i++) {
        uint32_t bx = b_start_x + i * b_spacing;
        fb_draw_rounded_rect(bx, 240, 90, 90, 18, COLOR_STATUSBAR);
        fb_draw_char(bx + 35, 265, bookmarks[i][0], COLOR_IOS_BLUE, 3);
        fb_draw_text(bx + 15, 340, bookmarks[i], COLOR_WHITE, 1);
    }
}

void _start(void) {
    klog("[MobileSafari] Launching MobileSafari.app (PID 64)...\n");
    klog("[MobileSafari] Initializing WebKit tabbed desktop-class iPad browser layout.\n");

    draw_safari_ui();

    while (1) {
        for (volatile int i = 0; i < 50000000; i++);
    }
}
