#include <stdlib.h>
#include <string.h>
#include <gba.h>

#include "fxfr_pal1_bin.h"
#include "fxfr_pal2_bin.h"

#pragma GCC diagnostic ignored "-Wunused-function"

#define CX_ARRAYSIZE(a) (sizeof(a) / sizeof((a)[0]))
#define STRUCT(x) typedef struct x x; struct x
#define MEM_ALIGN(x, a) (void*)(((u32)(x) + (a) - (u32)1) & ~((a) - (u32)1))

#define VRAM_BUF1 (0x06000000)
#define VRAM_BUF2 (0x0600A000)
#define DCNT_PAGE (0x10)
#define EXTRALINECOUNT ((0xA000 - SCREEN_HEIGHT * SCREEN_WIDTH) / SCREEN_WIDTH)

// division approximations
#define DIV_3(x) ((x)*2730 >> 13)
#define DIV_60(x) ((x)*68 >> 12)
#define DIV_360(x) ((x)*91 >> 15)
#define REM_360(x) ((x) - DIV_360(x) * 360)
#define DIV_510(x) ((x) >> 9)
#define DIV_30600(x) ((x)*17 >> 19)
#define RGB8_CLAMP(r, g, b) ( (((r)>>3)&0x1F) | ((((g)>>3)&0x1F)<<5) | ((((b)>>3)&0x1F)<<10) )

STRUCT(CXRandom16)
{
	u32 x;
	u32 mul;
	u32 add;
};

static u32 s_frameCount;
static u32 s_bb;
static CXRandom16 s_rand;

static inline void CXRandom16_Setup(CXRandom16* context, u32 seed)
{
	context->x = seed;
    context->mul = 1566083941ul;
    context->add = 2531011;
}

static inline u16 CXRandom16_Next(CXRandom16* context)
{
    context->x = context->mul * context->x + context->add;
	return (u16)(context->x >> 16);
}

#if 0
// PRECOND: h >= -1 && (u32)s <= 0xFF && (u32)v <= 0xFF
IWRAM_CODE static u16 HSVToRGB(s32 h, s32 s, s32 v)
{
	u32 f, p;
    s32 x;

    if (s == 0 || h == -1)
        return (u16)RGB8(v, v, v);

    h = REM_360(h);
    x = DIV_60(h);
    f = (u32)(h - x * 60); // remainder of h / 60
    h = x;
    p = DIV_510((u32)(2 * v * (255 - s) + 255));
    if (h & 1)
    {
        u32 q = DIV_30600((u32)2 * v * (15300 - s * f) + 15300);
        switch (h)
        {
        case 1: return (u16)RGB8_CLAMP(q, v, p);
        case 3: return (u16)RGB8_CLAMP(p, q, v);
        case 5: return (u16)RGB8_CLAMP(v, p, q);
        }
    }
    else
    {
        u32 t = DIV_30600((u32)2 * v * (15300 - (s * (60 - f))) + 15300);
        switch (h)
        {
        case 0: return (u16)RGB8_CLAMP(v, t, p);
        case 2: return (u16)RGB8_CLAMP(p, v, t);
        case 4: return (u16)RGB8_CLAMP(t, p, v);
        }
    }
    return 0;
}

IWRAM_CODE static void GenPalette(void)
{
    u16* dst = BG_PALETTE;
    u32 x;
    for (x = 0; x < 128; ++x)
        *dst++ = HSVToRGB(DIV_3(x), 0xFF, x*2);
    for (; x < 256; ++x)
        *dst++ = HSVToRGB(DIV_3(x), 0xFF, 0xFF);
}

IWRAM_CODE static void ShowPalette(u32 offset)
{
    u8* dst = (u8*)s_bb;
    s32 y, x;
    for (y = 0; y < SCREEN_HEIGHT; ++y)
        for (x = 0; x < SCREEN_WIDTH; ++x)
            *dst++ = (u8)(x + offset);
}
#endif

IWRAM_CODE static void FadeToPalette(u16* p)
{
    u16* c = (u16*)BG_PALETTE;
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

IWRAM_CODE static void UpdateFire(void)
{
    u32 x, y, o;
    u16 *d, *s;

    // randomize bottom
    d = (u16*)s_bb + (SCREEN_HEIGHT+2) * SCREEN_WIDTH/2;
    for (y = 0; y < 2; ++y)
        for (x = 0; x < SCREEN_WIDTH/2; ++x)
            *d++ = CXRandom16_Next(&s_rand) | 0x1F1F;
    // smooth
    d = (u16*)s_bb;
    s = (u16*)(s_bb ^ 0xA000);
    for (o = 0, y = 0; y < SCREEN_HEIGHT+2; ++y)
        for (x = 0; x < SCREEN_WIDTH/2; ++x, ++o)
        {
            u32 v0, v1, v2, v3;
            v0 = s[o + SCREEN_WIDTH/2];
            v1 = s[o + SCREEN_WIDTH];
            v2 = s[o + SCREEN_WIDTH/2 + 1];
            v3 = s[o + SCREEN_WIDTH/2 - 1];
            u32 d0 = 255*((v0&0xFF)+(v1&0xFF)+(v1>>8)+(v3>>8)) >> 10;
            u32 d1 = 255*((v0>>8)+(v1>>8)+(v2&0xFF)+(v0&0xFF)) >> 10;
            d[o] = (u16)((d1<<8)|d0);
        }
}

#if 0
IWRAM_CODE static void VBlank(void)
{
    ++s_frameCount;
}
#endif

__attribute__ ((noreturn)) IWRAM_CODE int main(void)
{
    irqInit();
    //irqSet(IRQ_VBLANK, VBlank);
    irqEnable(IRQ_VBLANK);

    REG_DISPCNT = MODE_4 | BG2_ON;
    CXRandom16_Setup(&s_rand, 0x5BD1E995);
    //GenPalette();
    memcpy((void*)BG_PALETTE, fxfr_pal1_bin, fxfr_pal1_bin_size);
    s_bb = VRAM_BUF2;

    for (;;)
    {
        UpdateFire();
        VBlankIntrWait();
        if (++s_frameCount > 180)
            FadeToPalette((u16*)fxfr_pal2_bin);
        s_bb ^= 0xA000;
        REG_DISPCNT ^= DCNT_PAGE;
    }
}

