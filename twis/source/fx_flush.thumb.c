#include <stdlib.h>
#include <string.h>
#include "flush.h"

#define flush_VideoBuffer (unsigned short int *) 0x6000000
#define flush_Palette (unsigned short int *) 0x5000000

void fx_flush_init() 
{
    memcpy(flush_VideoBuffer,flush, sizeof(flush));
    memcpy(flush_Palette,flushPalette,sizeof(flushPalette));
    REG_DISPCNT = MODE_4 | OBJ_1D_MAP | BG2_ON | OBJ_ON;
    REG_BG2PA = 0x100;
    REG_BG2PB = 0;
    REG_BG2PC = 0;
    REG_BG2PD = 0x100;
}

void fx_flush_deinit()
{
}

void fx_flush_exec()
{
	VBlankIntrWait();
}
