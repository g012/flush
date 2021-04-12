#include <stdlib.h>
#include <string.h>
#include <gba.h>

#include "fx_fire.h"

#pragma GCC diagnostic ignored "-Wunused-function"

__attribute__ ((noreturn)) int main(void) {
    u8 screen_buf[128*81];
    static const u8 palette_data[] = {
        0,   0,   0,   64,
        128, 0,   0,   64,
        255, 128, 0,   64,
        255, 255, 0,   64,
        0,   0,   255, 0
    };
    u32 seed = 0x42000000;

    irqInit();
    irqEnable(IRQ_VBLANK);

    palette_generation(palette_data, (u16*)0x5000000);

    REG_DISPCNT = MODE_4 | BG2_ON;
    REG_BG2PA = 0x80;
    REG_BG2PB = 0;
    REG_BG2PC = 0;
    REG_BG2PD = 0x80;

    u32 s_bb = (u32)MODE5_BB;

    for (;;) {
        seed = render_fire((u16 *)s_bb, seed, screen_buf);
        VBlankIntrWait();
        s_bb ^= 0xA000;
        REG_DISPCNT ^= BACKBUFFER;
    }

    REG_BG2PA = 0x100;
    REG_BG2PD = 0x100;
}
