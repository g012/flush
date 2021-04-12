#include <stdlib.h>
#include <string.h>
#include <gba.h>
#include <maxmod.h>
extern mm_modlayer mmLayerMain;

#include "fxpl_dist_bin.h"
#include "fxpl_pal1_bin.h"
#include "fxpl_pal2_bin.h"
#include "fxpl_pal3_bin.h"
#include "fxpl_pal4_bin.h"
#include "fxtn_sin_bin.h"
#include "flying_wurst_pal_bin.h"
#include "flying_wurst_sprite_bin.h"
#include "plasma_wurst_pal_bin.h"
#include "plasma_wurst_sprite_bin.h"
#include "traject_bin.h"
#include "plasma_bin.h"

#pragma GCC diagnostic ignored "-Wunused-function"

#define VRAM_BUF1 (0x06000000)
#define VRAM_BUF2 (0x0600A000)
#define DCNT_PAGE (0x10)

static void MEM_Copy16(void* dst, const void* src, u32 sz)
{
    u32 i;
    u16* d = dst;
    const u16* s = src;
    for (i = 0; i < sz/2; ++i)
        *d++ = *s++;
}

static void FadeToPalette(u16* c, u16* p)
{
    u32 i;
    for (i = 0; i < 256; ++i)
    {
        u32 cc = *c;
        u32 r = cc & 0x1F;
        u32 g = (cc >> 5) & 0x1F;
        u32 b = (cc >> 10) & 0x1F;
        u32 pc = *p++;
        u32 pr = pc & 0x1F;
        u32 pg = (pc >> 5) & 0x1F;
        u32 pb = (pc >> 10) & 0x1F;
        if (pr > r) ++r; else if (pr < r) --r;
        if (pg > g) ++g; else if (pg < g) --g;
        if (pb > b) ++b; else if (pb < b) --b;
        *c++ = (u16)(r + (g << 5) + (b << 10));
    }
}

static void PL_Init(vu16* d, u16* pal)
{
#if 0
    u32 x, y;
    u8* sin = (u8*)&fxtn_sin_bin[0];
    u8* dist = (u8*)&fxpl_dist_bin[0];
    memcpy((void*)BG_PALETTE, pal, fxpl_pal1_bin_size);
    for (y = 0; y < SCREEN_HEIGHT; ++y)
    {
        for (x = 0; x < SCREEN_WIDTH; ++x)
        {
            u32 d0 = (u8)(((u32)0
                + sin[(x << 2) & 0xFF]
                + sin[(y << 1) & 0xFF]
                + sin[((x+y) << 3) & 0xFF]
                + (dist[x + y * SCREEN_WIDTH] << 5)
            ) >> 2);
            ++x;
            u32 d1 = (u8)(((u32)0
                + sin[(x << 2) & 0xFF]
                + sin[(y << 1) & 0xFF]
                + sin[((x+y) << 3) & 0xFF]
                + (dist[x + y * SCREEN_WIDTH] << 5)
            ) >> 2);
            *d++ = (u16)((d1<<8)|d0);
        }
        if ((y & 0x07) == 0) {
            mmFrame();
            VBlankIntrWait();
        }
    }
#else
    memcpy((void*)BG_PALETTE, pal, fxpl_pal1_bin_size);
    memcpy(d, plasma_bin, plasma_bin_size);
#endif
}

static void PL_Update(u16* pal)
{
    static u8 palof = 0;
    ++palof;
    MEM_Copy16((u16*)BG_PALETTE, &pal[256 - palof], 2*palof);
    MEM_Copy16((u16*)BG_PALETTE + palof, pal, 2*(256 - palof));
}

static void PL_LoadSprites(const void* data, u32 datasz, const void* pal, u32 palsz)
{
    memcpy(SPRITE_PALETTE, pal, palsz);
    memcpy(BITMAP_OBJ_BASE_ADR, data, datasz);
}

static void PL_UpdateSprites(u32 x, u32 y, u32 zoom)
{
    OAM[0].attr0 = ATTR0_COLOR_16|ATTR0_SQUARE|OBJ_Y(y-64);
    OAM[0].attr1 = OBJ_SHAPE(0)|OBJ_SIZE(3)|OBJ_X(x-64);
    OAM[0].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(0x200);
    OAM[1].attr0 = ATTR0_COLOR_16|ATTR0_SQUARE|OBJ_Y(y-64);
    OAM[1].attr1 = OBJ_SHAPE(0)|OBJ_SIZE(3)|OBJ_X(x);
    OAM[1].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(0x240);
    OAM[2].attr0 = ATTR0_COLOR_16|ATTR0_SQUARE|OBJ_Y(y);
    OAM[2].attr1 = OBJ_SHAPE(0)|OBJ_SIZE(3)|OBJ_X(x-64);
    OAM[2].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(0x280);
    OAM[3].attr0 = ATTR0_COLOR_16|ATTR0_SQUARE|OBJ_Y(y);
    OAM[3].attr1 = OBJ_SHAPE(0)|OBJ_SIZE(3)|OBJ_X(x);
    OAM[3].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(0x2C0);
}

static void PL_Cleanup(void)
{
    memset(BITMAP_OBJ_BASE_ADR, 0, plasma_wurst_sprite_bin_size);
}

void main_fx_plasma(u32 duration)
{
    u16* palettes[] =
    {
        (u16*)fxpl_pal1_bin,
        (u16*)fxpl_pal2_bin,
        (u16*)fxpl_pal3_bin,
        (u16*)fxpl_pal4_bin,
    };
    u32 pali = 0;

    u16 pal[256];
    MEM_Copy16(pal, fxpl_pal1_bin, fxpl_pal1_bin_size);

    REG_DISPCNT = MODE_4 | OBJ_1D_MAP | BG2_ON | OBJ_ON;
    u32 bb = VRAM_BUF1;
    PL_Cleanup();
    PL_Init((vu16*)bb, pal);
    mmFrame();
    VBlankIntrWait();

    static const u32 beatPal[] =
    {
        3, 3,
        4, 2,
        5, 1,
        6, 0,
        7, 1,
        8, 2,
        9, 1,
        10, 3,
        11, 1,
        12, 2,
        20, 0,
        25, 3,
        26, 1,
        28, 2,
        36, 0,
        38, 3,
        39, 0,
        40, 3,
        41, 0,
        42, 2,
        43, 0,
        44, 1,
        45, 0,
        46, 2,
        48, 3,
        49, 0,
        50, 1,
        51, 0,
        52, 2,
        53, 0,
        54, 3,
        55, 2,
    };
    const u32 beatSprite = 24;

    u32 wi = 0, wx, wy, switched = 0, speed = 4;
    wx = traject_bin[wi], wy = traject_bin[wi+1];
    u32 beat = 0;
    u32 beatPali = 0;
    u32 runningTime;
    for (runningTime = 0; runningTime < duration; ++runningTime)
    {
        if (beat >= beatSprite)
        {
            if (wi < traject_bin_size)
            {
                wx = traject_bin[wi++], wy = traject_bin[wi++], wi += speed;
                if (wi > traject_bin_size/2 && speed == 4)
                    speed = 2;
                if (wi > 7*traject_bin_size/8 && speed == 3)
                    speed = 1;
            }
            else if (!switched)
                switched = 1, PL_LoadSprites(plasma_wurst_sprite_bin, plasma_wurst_sprite_bin_size, plasma_wurst_pal_bin, plasma_wurst_pal_bin_size);
        }
        PL_UpdateSprites(wx, wy, 1);
        PL_Update(pal);
        FadeToPalette(pal, palettes[pali]);
        mmFrame();
        u32 incbeat = mmLayerMain.row == 0 || mmLayerMain.row == 12 || mmLayerMain.row == 24 || mmLayerMain.row == 36;
        beat += incbeat;
        if (beatPali < sizeof(beatPal) / sizeof(beatPal[0]) && beatPal[beatPali] <= beat)
            pali = beatPal[++beatPali], ++beatPali;
        if (beat == beatSprite)
            PL_LoadSprites(flying_wurst_sprite_bin, flying_wurst_sprite_bin_size, flying_wurst_pal_bin, flying_wurst_pal_bin_size);
        VBlankIntrWait();
    }

    PL_Cleanup();
}
