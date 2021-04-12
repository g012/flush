#include "m7.h"
#include "cemetery_bg.h"
#include "cemetery_fg.h"
#include "cemetery_floor.h"
#include "cemetery_obj.h"
#include "cemetery_pal.h"

typedef struct 
{
    M7 m7;
} Cemetery;

void cemetery_init(void)
{
    u32 i, v;
    u8* p;
    Cemetery* c;

    // let's make sure no one breaks our scene creating a huge overlay
    LoadOverlayAndExtendIHeap(OVERLAY_M7);
    g_fx_data = c = iwalloc(sizeof(*c));

    M7_Setup(g_m7 = &c->m7);
    c->m7.horizon = 56;

    // BG palette
    LZ77UnCompVram((void*)cemetery_palPal, BG_PALETTE);
    // OBJ palette
    LZ77UnCompVram((void*)cemetery_palPal, SPRITE_PALETTE);

    // background (wrapping part color is used for fog)
    LZ77UnCompVram((void*)cemetery_bgTiles, CHAR_BASE_BLOCK(2));
    LZ77UnCompVram((void*)cemetery_bgMap, SCREEN_BASE_BLOCK(23));
    REG_BG0CNT = CHAR_BASE(2) | SCREEN_BASE(23) | BG_PRIORITY(2) | BG_256_COLOR | BG_WID_32 | BG_HT_32;
    REG_BG0HOFS = c->m7.cam.ry >> 7; //256 - 240;
    REG_BG0VOFS = 256 - c->m7.horizon;

    // foreground
    LZ77UnCompVram((void*)cemetery_fgTiles, CHAR_BASE_BLOCK(1));
    LZ77UnCompVram((void*)cemetery_fgMap, SCREEN_BASE_BLOCK(15));
    REG_BG1CNT = CHAR_BASE(1) | SCREEN_BASE(15) | BG_PRIORITY(0) | BG_256_COLOR | BG_WID_32 | BG_HT_32;
    REG_BG1HOFS = (256 - 240) / 2;
    REG_BG1VOFS = 256 - 160;

    // floor
    LZ77UnCompVram((void*)cemetery_floorTiles, CHAR_BASE_BLOCK(0));
    // make sure the first pixel of top left tile is transparent, to see the background through it
    *((u32*)SCREEN_BASE_BLOCK(4)) = 0x02020201; // tile 1 is same as tile 2 but with top left pixel at index 0
    // fill the map with tile 2
    memset32((u8*)SCREEN_BASE_BLOCK(4) + 4, 0x02020202, 64*64 - 4);
    REG_BG2CNT = CHAR_BASE(0) | SCREEN_BASE( 4) | BG_PRIORITY(1) | BG_256_COLOR | ROTBG_SIZE_64 | BG_WRAP;

    // tombs
    LZ77UnCompVram((void*)cemetery_objTiles, CHAR_BASE_BLOCK(4));

	REG_DISPCNT= MODE_1 | BG0_ENABLE | BG1_ENABLE | BG2_ENABLE | OBJ_ENABLE;
    M7_Start();
}

void cemetery_deinit(void)
{
    M7_Stop();
    ResetIHeap();
}

void cemetery_exec(void)
{
    Cemetery* c = g_fx_data;

    M7_Flush();
	VBlankIntrWait();
    M7_Swap();

    // rotate background with camera
    REG_BG0HOFS = c->m7.cam.ry >> 7;
}

