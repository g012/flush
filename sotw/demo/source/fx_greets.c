#include <stdlib.h>
#include <string.h>
#include <gba.h>

#include <maxmod.h>

#include "3d.h"

#pragma GCC diagnostic ignored "-Wunused-function"

#define PAD_KEYS (*(volatile u32*)0x04000130)
#define MAX_VERTICES 300

extern const s16 revision_logo[];
extern const u8 greets_bg[];

// imported from fx_greets
void fadepal(u16 *dest, const u16 *pal, u16 lv, u16 start, u16 stop);

void render(u16 *b, const s16 *obj, s16* two_d_buf, u32 t) {
    s32 matrix[9];
    static const s16 light[3] = {-18918,18918,18918};
    s16 tx=0,ty=0,tz=-530,rx=0x3500,ry=0x3c00,rz=(3*t)&0x3fff;
    // clear_screen(b);
    memcpy(b, greets_bg+240*(t/8), 240*160);
    // copy_lines(b, greets_bg+240*(t/8),160);
    make_matrix(matrix, rx, ry, rz);
    rotransjectionn(two_d_buf, obj+2, matrix, tx, ty, tz, 112);
    rz = (1*t)&0x3fff;
    make_matrix(matrix, rx, ry, rz);
    rotransjectionn(two_d_buf+112*3, obj+2+112*3, matrix, tx, ty, tz, 48);
    rz = (-2*t)&0x3fff;
    make_matrix(matrix, rx, ry, rz);
    rotransjectionn(two_d_buf+(112+48)*3, obj+2+(112+48)*3, matrix, tx, ty, tz, 98);

    draw_object(b, two_d_buf, matrix, obj, light);
}

void main_greets(void) {
    u16 palette[256];
    static const u8 palette_data[] = {
        0,   0,   0,   31,
        255, 255, 255, 1,
        255, 0, 0, 1,
        64, 96, 128, 1,
        0,   0,   255, 222,
        0,   0,   255, 0
    };
    u32 t = 0;
    s16 *two_d_buf = malloc(MAX_VERTICES*3*2);

    palette_generation(palette_data, palette);

    REG_DISPCNT = MODE_4 | BG2_ON;
    u32 s_bb = (u32)MODE5_BB;

    u32 time = 600;
    while(time-->0) {
        BG_PALETTE[0] = 0;
        int lv = (time < 128)?(time*2):((time>600-32)?((600-time)*8):256);
        fadepal(BG_PALETTE, palette, lv, 0, 256);
        render((u16 *)s_bb, revision_logo, two_d_buf, t++);
        if (!(PAD_KEYS & 0x200))
            BG_PALETTE[0] = 0x3def;
        VBlankIntrWait();
        s_bb ^= 0xA000;
        REG_DISPCNT ^= BACKBUFFER;
    }
    memset(BG_PALETTE, 0, 512);
    free(two_d_buf);
}
