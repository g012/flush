#include <stdlib.h>
#include <string.h>
#include <gba.h>
#include <maxmod.h>
#include "flush.h"
#pragma GCC diagnostic ignored "-Wunused-function"

#define PAD_KEYS (*(volatile u32*)0x04000130)
#define flush_VideoBuffer (unsigned short int *) 0x6000000
#define flush_Palette (unsigned short int *) 0x5000000

extern mm_modlayer mmLayerMain;

void main_fx_flush(void) {
    memcpy(flush_VideoBuffer,flush, sizeof(flush));
    memcpy(flush_Palette,flushPalette,sizeof(flushPalette));
    REG_DISPCNT = MODE_4 | OBJ_1D_MAP | BG2_ON | OBJ_ON;
//     u32 time = 400;
    while(mmLayerMain.position!=10)
    {
      BG_PALETTE[0] = 0;
      if (!(PAD_KEYS & 0x200))
	BG_PALETTE[0] = 0x3def;
	mmFrame();
        VBlankIntrWait();
    }
}
