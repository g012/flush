#include <stdlib.h>
#include <string.h>
#include <gba.h>

#include <maxmod.h>
extern mm_modlayer mmLayerMain;

#include "fx_fire2.h"
#include "3d.h"
#include "burning_wurst0_sprite_bin.h"
#include "burning_wurst0_pal_bin.h"
#include "burning_wurst1_sprite_bin.h"
#include "burning_wurst1_pal_bin.h"
#include "burning_wurst2_sprite_bin.h"
#include "burning_wurst2_pal_bin.h"
#include "burning_wurst3_sprite_bin.h"
#include "burning_wurst3_pal_bin.h"
#include "burning_wurst4_sprite_bin.h"
#include "burning_wurst4_pal_bin.h"

#pragma GCC diagnostic ignored "-Wunused-function"

#define VRAM_BUF1 (0x06000000)

typedef struct FRSprite
{
    const void* pal;
    const void* sprite;
} FRSprite;

static const FRSprite s_sprites[] =
{
    { burning_wurst0_pal_bin, burning_wurst0_sprite_bin },
    { burning_wurst1_pal_bin, burning_wurst1_sprite_bin },
    { burning_wurst2_pal_bin, burning_wurst2_sprite_bin },
    { burning_wurst3_pal_bin, burning_wurst3_sprite_bin },
    { burning_wurst4_pal_bin, burning_wurst4_sprite_bin },
};

static void FR_LoadSprite(u32 frame)
{
    memcpy(SPRITE_PALETTE, s_sprites[frame].pal, 32);
    memcpy(BITMAP_OBJ_BASE_ADR, s_sprites[frame].sprite, 128*64/2);
}

static void FR_UpdateSprites(u32 x, u32 y)
{
    OAM[0].attr0 = ATTR0_COLOR_16|ATTR0_SQUARE|OBJ_Y(y);
    OAM[0].attr1 = OBJ_SHAPE(0)|OBJ_SIZE(3)|OBJ_X(x-64);
    OAM[0].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(0x200);
    OAM[1].attr0 = ATTR0_COLOR_16|ATTR0_SQUARE|OBJ_Y(y);
    OAM[1].attr1 = OBJ_SHAPE(0)|OBJ_SIZE(3)|OBJ_X(x);
    OAM[1].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(0x240);
}

static void FR_Cleanup(void)
{
    memset(BITMAP_OBJ_BASE_ADR, 0, 128*64/2);
}

void main_fire2(u32 time) {
    u8 screen_buf[128*81];
    static const u8 palette_data[] = {
        0,   0,   0,   64,
        128, 0,   0,   64,
        255, 128, 0,   64,
        255, 255, 0,   64,
        0,   0,   255, 0
    };
    u32 seed = 0x42000000;
    const u32 targety = 40;
    u32 wursty = 0;

    palette_generation(palette_data, (u16*)0x5000000);
    FR_LoadSprite(0);

    REG_DISPCNT = MODE_4 | OBJ_1D_MAP | BG2_ON | OBJ_ON;
    REG_BG2PA = 0x80;
    REG_BG2PB = 0;
    REG_BG2PC = 0;
    REG_BG2PD = 0x80;

    u32 bb = VRAM_BUF1;
    u32 frame = 0;
    s32 dir = 1;
    u32 speed = 4;
    u32 ftime = 0;

    //     u32 time = 400;
    u32 beat = 0;
    while(mmLayerMain.position!=29)
    {
        FR_UpdateSprites(120, wursty);
        seed = render_fire((u16 *)bb, seed, screen_buf);
        mmFrame();
        u32 incbeat = mmLayerMain.row == 0 || mmLayerMain.row == 12 || mmLayerMain.row == 24 || mmLayerMain.row == 36;
        beat += incbeat;
        VBlankIntrWait();
        if (wursty >= targety)
        {
            if (++ftime >= speed)
            {
                frame += dir, ftime = 0;
                if (frame == 4 || frame == 0) dir = -dir;
                FR_LoadSprite(frame);
            }
        }
        else
            ++wursty;
        //s_bb ^= 0xA000;
        //REG_DISPCNT ^= BACKBUFFER;
    }

    REG_BG2PA = 0x100;
    REG_BG2PD = 0x100;

    FR_Cleanup();
}
