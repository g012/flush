#include <stdlib.h>
#include <string.h>
#include <gba.h>

#include <maxmod.h>

#include "3d.h"

#pragma GCC diagnostic ignored "-Wunused-function"

#define PAD_KEYS (*(volatile u32*)0x04000130)
#define MAX_VERTICES 300

extern const s16 credits_505[];
extern const s16 credits_fra[];
extern const s16 credits_g012[];
extern const s16 credits_maracuja[];
extern const s16 credits_p0ke[];
extern const s16 credits_zerkman[];

static void prod_matvec(s16 dest[3], const s32 mat[9], const s16 vec[3]) {
    dest[0] = (mat[0]*vec[0] + mat[1]*vec[1] + mat[2]*vec[2])>>15;
    dest[1] = (mat[3]*vec[0] + mat[4]*vec[1] + mat[5]*vec[2])>>15;
    dest[2] = (mat[6]*vec[0] + mat[7]*vec[1] + mat[8]*vec[2])>>15;
}

void fadepal(u16 *dest, const u16 *pal, u16 lv, u16 start, u16 stop) {
    int i;
    for (i = start; i < stop; ++i) {
        u32 c = pal[i];
        u32 r = (c&31)*lv/256;
        u32 g = ((c>>5)&31)*lv/256;
        u32 b = ((c>>10)&31)*lv/256;
        dest[i] = r|(g<<5)|(b<<10);
    }
}

static void render(u16 *b, const u16 *palette, u32 t) {
    s16 two_d_buf[MAX_VERTICES*3];
    static const s16 light[3] = {-26754,18919,0};
    s32 matrix[9];
    s32 lmatrix[9];
    s16 rlight[3], llight[3];
    s16 tx=0,ty=0,tz=-400;
    s16 rx[] = {0x1300, 0x1200, 0xf00, 0x1200, 0x1100, 0xe00};
    s16 ry[] = {0x300, 0x3e00, 0x3d00, 0x200, 0x200, 0x100};
    s16 rz[] = {0x100, 0x200, 0x3f00, 0x200, 0x300, 0x3d00};
    int id = t / 256;
    int pha = t & 255;
    u16 intensity = 256;
    const s16* objs[] = {credits_505,credits_fra,credits_g012,credits_maracuja,credits_p0ke,credits_zerkman};
    while (id >= 6) id -= 6;

    if (pha < 32)
        intensity = pha*8;
    else if (pha >= 224)
        intensity = (256-pha)*8;

    fadepal(BG_PALETTE, palette, intensity, 0, 224);

    make_matrix(matrix, rx[id], ry[id], rz[id]);
    make_matrix(lmatrix, 0, (t*64)&0x3fff, 0);
    rotransjection(two_d_buf, objs[id], matrix, tx, ty, tz);

    prod_matvec(rlight, lmatrix, light);
    prod_matvec(llight, matrix, rlight);

    clear_screen(b);
    draw_object(b, two_d_buf, matrix, objs[id], rlight);
}

void main_credits(void) {
    u16 palette[256];
    static const u8 palette_data[] = {
        0,   0,   0,   24,
        255, 192, 0,   7,
        255, 255, 255, 1,
        0,   0,   0,   24,
        192, 255, 0,   7,
        255, 255, 255, 1,
        0,   0,   0,   24,
        0,   255, 192, 7,
        255, 255, 255, 1,
        0,   0,   0,   24,
        0,   192, 255, 7,
        255, 255, 255, 1,
        0,   0,   0,   24,
        255, 0,   192, 7,
        255, 255, 255, 1,
        0,   0,   0,   24,
        192, 0,   255, 7,
        255, 255, 255, 1,
        0,   0,   255, 64,
        0,   0,   255, 0
    };
    u32 t = 0;

    palette_generation(palette_data, palette);

    REG_DISPCNT = MODE_4 | BG2_ON;
    u32 s_bb = (u32)MODE5_BB;

    u32 time = 0x600;
    while(time-->0) {
        BG_PALETTE[0] = 0;
        render((u16 *)s_bb, palette, t++);
        if (!(PAD_KEYS & 0x200))
            BG_PALETTE[0] = 0x3def;
        if (time < 0x100) {
            int vol = (time<4) ? 0 : (time * (1024/0x100));
            mmSetModuleVolume(vol);
        }
        mmFrame();
        VBlankIntrWait();
        s_bb ^= 0xA000;
        REG_DISPCNT ^= BACKBUFFER;
    }
}
