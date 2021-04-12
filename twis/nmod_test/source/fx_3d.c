#include <stdlib.h>
#include <string.h>
#include <gba.h>

#include "3d.h"
#include "nmod.h"
#include "stardstm_mod_bin.h"

#pragma GCC diagnostic ignored "-Wunused-function"

#define PAD_KEYS (*(volatile u32*)0x04000130)
#define MAX_VERTICES 3100

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

void main_3d(void) {
    static const u8 palette_data[] = {
        0,   0,   0,   24,
        255, 192, 0,   7,
        255, 255, 255, 1,
        0,   0,   255, 224,
        0,   0,   255, 0
    };
    u32 t = 0;
    s16 *two_d_buf = malloc(MAX_VERTICES*3*2);

    palette_generation(palette_data, (u16*)0x5000000);

    REG_DISPCNT = MODE_4 | BG2_ON;
    u32 s_bb = (u32)MODE5_BB;

    for(;;)
    {
        BG_PALETTE[0] = 0;
        render((u16 *)s_bb, torus, two_d_buf, t++);
        if (!(PAD_KEYS & 0x200))
            BG_PALETTE[0] = 0x3def;
        VBlankIntrWait();
        s_bb ^= 0xA000;
        REG_DISPCNT ^= BACKBUFFER;
    }

    free(two_d_buf);
}

int main(void)
{
    irqInit();
    irqSet(IRQ_TIMER1, NMOD_Timer1iRQ);
    irqEnable(IRQ_VBLANK|IRQ_TIMER1);
    NMOD_SetMasterVol(64,0);
    NMOD_SetMasterVol(64,1);
    NMOD_SetMasterVol(64,2);
    NMOD_SetMasterVol(64,3);
    NMOD_Play((u32)stardstm_mod_bin);

    main_3d();
    return 0;
}
