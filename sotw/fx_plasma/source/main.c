#include <stdlib.h>
#include <string.h>
#include <gba.h>

#include "fxpl_dist_bin.h"
#include "fxpl_pal1_bin.h"
#include "fxpl_pal2_bin.h"
#include "fxpl_pal3_bin.h"
#include "fxpl_pal4_bin.h"
#include "fxtn_sin_bin.h"
#include "plasma_bin.h"

#pragma GCC diagnostic ignored "-Wunused-function"

#define VRAM_BUF1 (0x06000000)
#define VRAM_BUF2 (0x0600A000)
#define DCNT_PAGE (0x10)

static u32 s_frameCount;
static u32 s_bb;
static u16* s_pal;

static void MEM_Copy16(void* dst, const void* src, u32 sz)
{
    u32 i;
    u16* d = dst;
    const u16* s = src;
    for (i = 0; i < sz/2; ++i)
        *d++ = *s++;
}

IWRAM_CODE static void FadeToPalette(u16* p)
{
    u16* c = s_pal;
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

#define BAKE
IWRAM_CODE static void PL_Init(void)
{
#ifndef BAKE
    u32 x, y;
    u8* sin = (u8*)&fxtn_sin_bin[0];
    u8* dist = (u8*)&fxpl_dist_bin[0];
#endif
    u16* d = (u16*)s_bb;
    memcpy((void*)BG_PALETTE, s_pal, fxpl_pal1_bin_size);
#ifndef BAKE
    for (y = 0; y < SCREEN_HEIGHT; ++y)
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
#else
    memcpy(d, plasma_bin, plasma_bin_size);
#endif
}

IWRAM_CODE static void PL_Update(void)
{
    static u8 palof = 0;
    ++palof;
    MEM_Copy16((u16*)BG_PALETTE, &s_pal[256 - palof], 2*palof);
    MEM_Copy16((u16*)BG_PALETTE + palof, s_pal, 2*(256 - palof));
    // !! memcpy is buggy with addresses not multiple of 4 !!
    //memcpy((u16*)BG_PALETTE, &pal[256 - palof], 2*palof);
    //memcpy((u16*)BG_PALETTE + palof, pal, 2*(256 - palof));
}

__attribute__ ((noreturn)) IWRAM_CODE int main(void)
{
    u16* palettes[] =
    {
        (u16*)fxpl_pal1_bin,
        (u16*)fxpl_pal2_bin,
        (u16*)fxpl_pal3_bin,
        (u16*)fxpl_pal4_bin,
    };
    u32 pali = 0;
    u32 time = 0;

    s_pal = malloc(256*2);
    MEM_Copy16(s_pal, fxpl_pal1_bin, fxpl_pal1_bin_size);

    irqInit();
    irqEnable(IRQ_VBLANK);

    REG_DISPCNT = MODE_4 | BG2_ON;
    s_bb = VRAM_BUF1;
    PL_Init();

    for (;;)
    {
        PL_Update();
        VBlankIntrWait();
        ++s_frameCount;
        if (++time >= 360)
        {
            time = 0;
            if (++pali >= sizeof(palettes) / sizeof(*palettes))
                pali = 0;
        }
        FadeToPalette(palettes[pali]);
        //s_bb ^= 0xA000;
        //REG_DISPCNT ^= DCNT_PAGE;
    }
}

