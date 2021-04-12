#include <stdlib.h>
#include <string.h>
#include <gba.h>

#include "flush.h"
#pragma GCC diagnostic ignored "-Wunused-function"

#define PAD_KEYS (*(volatile u32*)0x04000130)
unsigned short int * flush_VideoBuffer = (unsigned short int *) 0x6000000;
unsigned short int * flush_Palette = (unsigned short int *) 0x5000000;
unsigned short int * flush_FrontBuffer = (unsigned short int *) 0x6000000;
unsigned short int * flush_BackBuffer = (unsigned short int *) 0x600A000;

void flush_FlipBuffer(){
  if(REG_DISPCNT & 0x10){
    REG_DISPCNT &= ~0x10;
    flush_VideoBuffer=flush_BackBuffer;
  }else{
    REG_DISPCNT |= 0x10;
    flush_VideoBuffer=flush_FrontBuffer;
  }
}



__attribute__ ((noreturn)) int main(void) {
    irqInit();
    irqEnable(IRQ_VBLANK);
    flush_FlipBuffer();
    dmaCopy((void*)flush, (void*)flush_VideoBuffer , 38400);
    dmaCopy((void*)flushPalette, (void*)flush_Palette , 512);
    flush_FlipBuffer();
    dmaCopy((void*)flush, (void*)flush_VideoBuffer , 38400);


    REG_DISPCNT = MODE_4 | OBJ_1D_MAP | BG2_ON | OBJ_ON;
    u32 s_bb = (u32)MODE5_BB;

    for (;;) {
        BG_PALETTE[0] = 0;
        if (!(PAD_KEYS & 0x200))
            BG_PALETTE[0] = 0x3def;
        VBlankIntrWait();

        s_bb ^= 0xA000;
        REG_DISPCNT ^= BACKBUFFER;
    }
}
