#include <stdlib.h>
#include <string.h>
#include <gba.h>

#include <maxmod.h>

#include "soundbank.h"
#include "soundbank_bin.h"

// gamepak rom/sram access timings
#define REG_WAITCNT (*((vu32*)0x4000204))
// undocumented register for EWRAM wait cycle count control
#define REG_INTERNALMEMORYCONTROL (*((vu32*)0x4000800))

//void main_scroll(void);
void main_logo_atari(void);
void main_fire(void);
void main_fire2(u32 duration);
void main_title(void);
void main_fx_parallax(void);
void main_3d(void);
void main_fx_troat(void);
void main_fx_parc(void);
void main_fx_entrance(void);
void main_fx_flush(void);
void main_credits(void);
void main_greets(void);
void main_fx_plasma(u32 duration);

void main(void)
{
    // overclock rom 0100-0110-1101-1011 : SRAM 8 - WS0 2,1 - WS1 2,1 - WS2 2,1 - PHI off - Prefetch on
    // default is WS0 4,2, fast commercial games put WS0 3,1
    // Supercard can only do 4,2, better cards at least 3,1
    //REG_WAITCNT = 0x46CB; // fast commercial games: 0x4317

    // overclock ewram (GBA and GBA SP only - crashes GBA Micro, not available on DS)
    // REG_INTERNALMEMORYCONTROL = (REG_INTERNALMEMORYCONTROL & 0x00FFFFFF) | (0x0E000000);

    irqInit();
    irqSet(IRQ_VBLANK, mmVBlank);
    irqEnable(IRQ_VBLANK);

    mmInitDefault((mm_addr) soundbank_bin, 8);
    mmStart( MOD_FLUSH, MM_PLAY_LOOP );

    // for (;;) {
        //main_scroll();
        main_logo_atari();
		main_3d();
        main_fx_flush();
        main_fx_parc();
        main_title();
        main_fx_parallax();
        main_fx_entrance();
        main_fire2(620);
        main_fx_troat();
        main_fx_plasma(960);
        main_credits();
        main_greets();
    // }
}
