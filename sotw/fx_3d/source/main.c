#include <stdlib.h>
#include <string.h>
#include <gba.h>

#include "3d.h"

#pragma GCC diagnostic ignored "-Wunused-function"

#define PAD_KEYS (*(volatile u32*)0x04000130)
#define MAX_VERTICES 300

extern const s16 torus[];

static void render(u16 *b, const s16 *obj, s16* two_d_buf, u32 t) {
    s32 matrix[9];
    static const s16 light[3] = {-18918,18918,18918};
    s16 tx=0,ty=0,tz=-500,rx=(16*t)&0x3fff,ry=(16*t)&0x3fff,rz=(16*t)&0x3fff;
    clear_screen(b);
    make_matrix(matrix, rx, ry, rz);
    rotransjection(two_d_buf, obj, matrix, tx, ty, tz);
    draw_object(b, two_d_buf, matrix, obj, light);
}

__attribute__ ((noreturn)) int main(void) {
    static const u8 palette_data[] = {
        0,   0,   0,   24,
        255, 192, 0,   7,
        255, 255, 255, 1,
        0,   0,   255, 224,
        0,   0,   255, 0
    };
    u32 t = 0;
    s16 *two_d_buf = malloc(MAX_VERTICES*3*2);

    irqInit();
    irqEnable(IRQ_VBLANK);

    palette_generation(palette_data, BG_PALETTE);

    REG_DISPCNT = MODE_4 | BG2_ON;
    u32 s_bb = (u32)MODE5_BB;

    for (;;) {
        BG_PALETTE[0] = 0;
        render((u16 *)s_bb, torus, two_d_buf, t++);
        if (!(PAD_KEYS & 0x200))
            BG_PALETTE[0] = 0x3def;
        VBlankIntrWait();
        s_bb ^= 0xA000;
        REG_DISPCNT ^= BACKBUFFER;
    }
}
