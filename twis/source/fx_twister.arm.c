#include "demo.h"
#include "mem.h"
#include "twister_pal.h"
#include "twister_tex_pal.h"
#include "sin256.h"
#include "twister_div.h"
#include "twister_tex.h"
#include "fx_twister.h"

// iwram code can't be marked static, or it won't be placed properly
IWRAM_O2_CODE void fx_twister_line_flat(u16* d, u32 x0, u32 x1, u32 col)
{
    u16 col2;
    u16 *start, *end;
    u16 t;
    col += (x1 >= x0 ? x1 - x0 : x0 - x1) + 0x80 >> 8; // line length must not exceed col, with current values 64
    col &= 0xFF;
    col2 = (u16)((col << 8) | col);
    x0 = x0 + 0x80 >> 8;
    x1 = x1 + 0x80 >> 8;
    start = d + x0/2;
    end = d + x1/2;
    if (x1 & 1) t = *end, t |= col, *end = t;
    if (x0 & 1) t = *start, t |= col << 8, *start++ = t;
    while (start < end) *start++ = col2;
}

IWRAM_O2_CODE void fx_twister_line_tex(u16* d, u32 x0, u32 x1, u32 uv)
{
    u32 v, u, uinc, l;
    u16 *start, *end;
    u16 t;
    l = (x1 >= x0 ? x1 - x0 : x0 - x1) + 0x80 >> 8;
    v = uv & ~0xFF;
    u = (uv & 0xFF) << 8;
    v += 256 * 256 * ((l + 4 >> 3) & 7); // TODO inc col index instead, and make one image with 32 colors with 8 ramps, and fit said texture in EWRAM
    uinc = ((u16*)twister_div)[(l-1) & 0x3F]; 
    if (!(l & 1))
        u += uinc >> 1;
    x0 = x0 + 0x80 >> 8;
    x1 = x1 + 0x80 >> 8;
    start = d + x0/2;
    end = d + x1/2;
    if (x0 & 1)
    {
        t = *start;
        t |= twister_tex[((u+0x80)>>8)|v] << 8;
        *start++ = t;
        u += uinc;
    }
    while (start < end)
    {
        u32 c = twister_tex[((u+0x80)>>8)|v];
        u += uinc;
        c |= (u32)twister_tex[((u+0x80)>>8)|v] << 8;
        u += uinc;
        *start++ = (u16)c;
    }
    if (x1 & 1)
    {
        t = *end;
        t |= twister_tex[((u+0x80)>>8)|v];
        *end = t;
    }
}

IWRAM_O2_CODE void fx_twister_render_tex(void)
{
    Twister* t = g_fx_data;
    u32 vamp = t->vamp;
    u32 theta = t->theta;
    u32 o = (SCREEN_WIDTH/2 - FX_TWISTER_AMP) * sin256[t->fc];
    u32 y, x;
    u32 col1 = 0x00; // 64 steps, same as amp value, so lighting works
    u32 col2 = 0x40;
    u32 col3 = 0x80;
    u32 col4 = 0xC0;
    u16* d;
    u32 uv;

    ++vamp;
    vamp &= 0xFF;
    t->vamp = (u8)vamp;
    vamp = 2 * (sin256[vamp] - 0x80);
    fx_twister_clearscreen((void*)t->bb);
    d = (u16*)t->bb;
    uv = sin256[theta >> 8] << 8;
    for (y = 0; y < SCREEN_HEIGHT; ++y, d += SCREEN_WIDTH/2, uv += 0x100)
    {
        u32 iamp = vamp * sin256[(y * FX_TWISTER_HFX_TWISTER_AMP >> 8) & 0xFF] + theta >> 8;
        // 4 vertices
        u32 x1 = (FX_TWISTER_AMP * sin256[(iamp + 0x00) & 0xFF]) + o;
        u32 x2 = (FX_TWISTER_AMP * sin256[(iamp + 0x40) & 0xFF]) + o;
        u32 x3 = (FX_TWISTER_AMP * sin256[(iamp + 0x80) & 0xFF]) + o;
        u32 x4 = (FX_TWISTER_AMP * sin256[(iamp + 0xC0) & 0xFF]) + o;
        // z-sort
        if (x1 < x2) fx_twister_line_tex(d, x1, x2, uv | 0x00);
        if (x2 < x3) fx_twister_line_tex(d, x2, x3, uv | 0x40);
        if (x3 < x4) fx_twister_line_tex(d, x3, x4, uv | 0x80);
        if (x4 < x1) fx_twister_line_tex(d, x4, x1, uv | 0xC0);
    }
    theta += t->theta_inc;
    if (theta >= 0x10000 || (s32)theta <= -0x12000) theta -= t->theta_inc << 1, t->theta_inc = -t->theta_inc;
    t->theta = theta;
}

IWRAM_O2_CODE void fx_twister_render_flat(void)
{
    Twister* t = g_fx_data;
    u32 vamp = t->vamp;
    u32 theta = t->theta;
    u32 o = (SCREEN_WIDTH/2 - FX_TWISTER_AMP) * sin256[t->fc];
    u32 y, x;
    u32 col1 = 0x00; // 64 steps, same as amp value, so lighting works
    u32 col2 = 0x40;
    u32 col3 = 0x80;
    u32 col4 = 0xC0;
    u16* d;
    u32 uv;

    ++vamp;
    vamp &= 0xFF;
    t->vamp = (u8)vamp;
    vamp = 2 * (sin256[vamp] - 0x80);
    fx_twister_clearscreen((void*)t->bb);
    d = (u16*)t->bb;
    uv = sin256[theta >> 8] << 8;
    for (y = 0; y < SCREEN_HEIGHT; ++y, d += SCREEN_WIDTH/2, uv += 0x100)
    {
        u32 iamp = vamp * sin256[(y * FX_TWISTER_HFX_TWISTER_AMP >> 8) & 0xFF] + theta >> 8;
        // 4 vertices
        u32 x1 = (FX_TWISTER_AMP * sin256[(iamp + 0x00) & 0xFF]) + o;
        u32 x2 = (FX_TWISTER_AMP * sin256[(iamp + 0x40) & 0xFF]) + o;
        u32 x3 = (FX_TWISTER_AMP * sin256[(iamp + 0x80) & 0xFF]) + o;
        u32 x4 = (FX_TWISTER_AMP * sin256[(iamp + 0xC0) & 0xFF]) + o;
        // z-sort
        if (x1 < x2) fx_twister_line_flat(d, x1, x2, col1);
        if (x2 < x3) fx_twister_line_flat(d, x2, x3, col2);
        if (x3 < x4) fx_twister_line_flat(d, x3, x4, col3);
        if (x4 < x1) fx_twister_line_flat(d, x4, x1, col4);
    }
    theta += t->theta_inc;
    if (theta >= 0x10000 || (s32)theta <= -0x12000) theta -= t->theta_inc << 1, t->theta_inc = -t->theta_inc;
    t->theta = theta;
}

IWRAM_O2_CODE void fx_twister_bg(void)
{
    Twister* t = g_fx_data;
    s32 bg_xo = (0x80 - sin256[t->fc]);
    s32 bg_yo = -2 * (sin256[t->fc] - 0x80);
    if (t->fc & 0x80) bg_xo = -bg_xo;
    if (t->fc & 0x100) bg_yo = -bg_yo;
    OBJATTR* oam = t->oam;
    OBJATTR bgt = oam[0];
    for (s32 y = 0, i = 0; y < 160+64; y += 64)
    {
        bgt.attr0 &= ~0xFF; bgt.attr0 |= OBJ_Y(y + bg_yo);
        for (s32 x = 0; x < 240+64*4; x += 64, ++i)
        {
            bgt.attr1 &= ~0x1FF; bgt.attr1 |= OBJ_X(x + bg_xo - 32);
            oam[i] = bgt;
        }
    }
}

static inline void oam_setdisable(void* dst, u32 c) // c max: 128
{ u32 i, *d = dst; for (i = 0; i < c; ++i) *d++ |= ATTR0_DISABLED; }
static inline void oam_setenable(void* dst, u32 c) // c max: 128
{ u32 i, *d = dst; for (i = 0; i < c; ++i) *d++ &= ~ATTR0_DISABLED; }
IWRAM_O2_CODE void fx_twister_exec(void)
{
    Twister* t = g_fx_data;
    u32 flushPalette = 0;
    
    if (t->sync > 2)
    {
        ++t->fc;
        fx_twister_bg();
    }
    if (t->sync < 9 && (sync & SYNC_BEAT)) t->theta_inc ^= 0x200;
    else t->theta_inc = 0x140;
    if (sync)
    {
        //if (t->sync2 ^= 1) oam_setenable(t->oam+32, 128-32);
        //else oam_setdisable(t->oam + 32, 128 - 32);
    }
    if (sync & SYNC_AFTER)
    {
        if (++t->sync > 7)
        {
            t->render_flat ^= 1;
            flushPalette = 1;
        }
    }
    if (t->render_flat) fx_twister_render_flat();
    else fx_twister_render_tex();

	VBlankIntrWait();
    if (flushPalette)
        dmacpy32((void*)BG_PALETTE, t->render_flat ? twister_pal : twister_tex_pal, 512);
    dmacpy32(OAM, t->oam, sizeof(t->oam));
    t->bb ^= VRAM_BUFSWITCH;
    REG_DISPCNT ^= DCNT_PAGE;
}

