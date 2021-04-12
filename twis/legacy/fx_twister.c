#include <stdlib.h>
#include <string.h>
#include "demo.h"
#include "3d.h"
#include "sin256_bin.h"
#include "twister_pal_bin.h"
#include "twister_div_bin.h"
#include "twister_tex_bin.h"
#include "twister_tex_pal_bin.h"
#include "fx_twister.h"

#define USE_TEX

typedef struct 
{
    u32 bb;
    u32 fc;
    u32 amp;
    u32 hamp;
    u32 vamp;
    u32 theta;
    u32 theta_inc;
} Twister;

#define fx_twister_line_flat fx_twister_line_flat_C
extern void fx_twister_line_flat_S(u16* d, u32 x0, u32 x1, u32 col);
IWRAM_CODE void fx_twister_line_flat_C(u16* d, u32 x0, u32 x1, u32 col)
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

#define fx_twister_line_tex fx_twister_line_tex_C
extern void fx_twister_line_tex_S(u16* d, u32 x0, u32 x1, u32 uv);
IWRAM_CODE void fx_twister_line_tex_C(u16* d, u32 x0, u32 x1, u32 uv)
{
    u32 v, u, uinc, l;
    u16 *start, *end;
    u16 t;
    l = (x1 >= x0 ? x1 - x0 : x0 - x1) + 0x80 >> 8;
    v = uv & ~0xFF;
    u = (uv & 0xFF) << 8;
    v += 256 * 256 * ((l + 4 >> 3) & 7); // TODO inc col index instead, and make one image with 32 colors with 8 ramps, and fit said texture in EWRAM
    uinc = ((u16*)twister_div_bin)[(l-1) & 0x3F]; 
    if (!(l & 1))
        u += uinc >> 1;
    x0 = x0 + 0x80 >> 8;
    x1 = x1 + 0x80 >> 8;
    start = d + x0/2;
    end = d + x1/2;
    if (x0 & 1)
    {
        t = *start;
        t |= twister_tex_bin[((u+0x80)>>8)|v] << 8;
        *start++ = t;
        u += uinc;
    }
    while (start < end)
    {
        u32 c = twister_tex_bin[((u+0x80)>>8)|v];
        u += uinc;
        c |= (u32)twister_tex_bin[((u+0x80)>>8)|v] << 8;
        u += uinc;
        *start++ = (u16)c;
    }
    if (x1 & 1)
    {
        t = *end;
        t |= twister_tex_bin[((u+0x80)>>8)|v];
        *end = t;
    }
}

#ifdef USE_TEX
#  define fx_twister_line(d, uv, x1, x2, col) fx_twister_line_tex(d, x1, x2, uv)
#else
#  define fx_twister_line(d, uv, x1, x2, col) fx_twister_line_flat(d, x1, x2, col)
#endif

extern void fx_twister_clearscreen(void* screen);
IWRAM_CODE void fx_twister_render(void) // iwram code can't be marked static, or it won't be placed properly
{
    Twister* t = g_fx_data;
    u32 amp = t->amp;
    u32 vamp = t->vamp;
    u32 hamp = t->hamp;
    u32 theta = t->theta;
    u32 o = (SCREEN_WIDTH/2 - amp) * sin256_bin[t->fc++ & 0xFF];
    u32 y, x;
    u32 col1 = 0x00; // 64 steps, same as amp value, so lighting works
    u32 col2 = 0x40;
    u32 col3 = 0x80;
    u32 col4 = 0xC0;

    //register u16* d asm("r0");
    //register u32 uv asm("r3");
    u16* d;
    u32 uv;

    ++vamp;
    vamp &= 0xFF;
    t->vamp = vamp;
    vamp = 2 * (sin256_bin[vamp] - 0x80);
    fx_twister_clearscreen((void*)t->bb);
    d = (u16*)t->bb;
    uv = sin256_bin[theta >> 8] << 8;
#if 0//def USE_TEX
    asm volatile(

        "   mov     r6,#0                   \n"
        "1:                                 \n"
        "   mul     r1,r6,%[hamp]           \n"
        "   lsr     r1,r1,#8                \n"
        "   and     r1,r1,#0xFF             \n"
        "   ldrb    r1,[%[sin],r1]          \n"
        "   mul     r5,r1,%[vamp]           \n"
        "   add     r5,r5,%[theta]          \n"
        "   lsr     r5,r5,#8                \n"

        "   and     r5,r5,#0xFF             \n"
        "   ldrb    r4,[%[sin],r5]          \n"
        "   mul     r1,r4,%[amp]            \n"
        "   add     r1,r1,%[o]              \n"
        "   add     r5,r5,#0x40             \n"
        "   and     r5,r5,#0xFF             \n"
        "   ldrb    r4,[%[sin],r5]          \n"
        "   mul     r2,r4,%[amp]            \n"
        "   add     r2,r2,%[o]              \n"
        "   add     r5,r5,#0x40             \n"
        "   and     r5,r5,#0xFF             \n"
        "   cmp     r1,r2                   \n"
        "   bpl     2f                      \n"
        "   stmfd   sp!,{r0-r3}             \n"
        "   bl      fx_twister_line_tex_S   \n"
        "   ldmfd   sp!,{r0-r3}             \n"
        "2: stmfd   sp!,{r1}                \n"
        "   mov     r1,r2                   \n"
        "   ldrb    r4,[%[sin],r5]          \n"
        "   mul     r2,r4,%[amp]            \n"
        "   add     r2,r2,%[o]              \n"
        "   add     r5,r5,#0x40             \n"
        "   and     r5,r5,#0xFF             \n"
        "   cmp     r1,r2                   \n"
        "   bpl     3f                      \n"
        "   stmfd   sp!,{r0-r3}             \n"
        "   bl      fx_twister_line_tex_S   \n"
        "   ldmfd   sp!,{r0-r3}             \n"
        "3: mov     r1,r2                   \n"
        "   ldrb    r4,[%[sin],r5]          \n"
        "   mul     r2,r4,%[amp]            \n"
        "   add     r2,r2,%[o]              \n"
        "   add     r5,r5,#0x40             \n"
        "   and     r5,r5,#0xFF             \n"
        "   cmp     r1,r2                   \n"
        "   bpl     4f                      \n"
        "   stmfd   sp!,{r0-r3}             \n"
        "   bl      fx_twister_line_tex_S   \n"
        "   ldmfd   sp!,{r0-r3}             \n"
        "4: mov     r1,r2                   \n"
        "   ldmfd   sp!,{r2}                \n"
        "   cmp     r1,r2                   \n"
        "   bpl     5f                      \n"
        "   stmfd   sp!,{r0-r3}             \n"
        "   bl      fx_twister_line_tex_S   \n"
        "   ldmfd   sp!,{r0-r3}             \n"

        "5: add     r3,r3,#0x100            \n"
        "   add     r0,r0,#240              \n"
        "   adds    r6,r6,#1                \n"
        "   cmp     r6,#160                 \n"
        "   bmi     1b                      \n"

        : "=r"(uv)
        : "r"(d), "0"(uv), [sin]"r"(&sin256_bin), [amp]"r"(amp), [hamp]"r"(hamp), [vamp]"r"(vamp), [theta]"r"(theta), [o]"r"(o)
        : "cc", "r1", "r2", "r4", "r5", "r6"
    );
#else
    for (y = 0; y < SCREEN_HEIGHT; ++y, d += SCREEN_WIDTH/2, uv += 0x100)
    {
        u32 iamp = vamp * sin256_bin[(y * hamp >> 8) & 0xFF] + theta >> 8;
        // 4 vertices
        u32 x1 = (amp * sin256_bin[(iamp + 0x00) & 0xFF]) + o;
        u32 x2 = (amp * sin256_bin[(iamp + 0x40) & 0xFF]) + o;
        u32 x3 = (amp * sin256_bin[(iamp + 0x80) & 0xFF]) + o;
        u32 x4 = (amp * sin256_bin[(iamp + 0xC0) & 0xFF]) + o;
        // z-sort
        if (x1 < x2) fx_twister_line(d, uv | 0x00, x1, x2, col1);
        if (x2 < x3) fx_twister_line(d, uv | 0x40, x2, x3, col2);
        if (x3 < x4) fx_twister_line(d, uv | 0x80, x3, x4, col3);
        if (x4 < x1) fx_twister_line(d, uv | 0xC0, x4, x1, col4);
    }
#endif
    theta += t->theta_inc;
    if (theta >= 0x10000 || (s32)theta <= -0x12000) theta -= t->theta_inc << 1, t->theta_inc = -t->theta_inc;
    t->theta = theta;
}

void fx_twister_init(void)
{
    Twister* t;
    g_fx_data = t = malloc(sizeof(*t));
    t->bb = VRAM_BUF2;
    t->fc = 0;
    // when changing this, need to change the rounding of light / line length (64: &0x80>>8, 32: &0x40>>7, ...)
    t->amp = 64;
    t->hamp = 64;
    t->vamp = 128;
    t->theta = 0;
    t->theta_inc = 0x100;

#ifdef USE_TEX
    memcpy((void*)BG_PALETTE, twister_tex_pal_bin, twister_tex_pal_bin_size);
#else
    memcpy((void*)BG_PALETTE, twister_pal_bin, twister_pal_bin_size);
#endif
    
    REG_DISPCNT = MODE_4 | BG2_ON;
}

void fx_twister_deinit(void)
{
    free(g_fx_data);
}

void fx_twister_exec(void)
{
    Twister* t = g_fx_data;

    fx_twister_render();

	VBlankIntrWait();
    t->bb ^= VRAM_BUFSWITCH;
    REG_DISPCNT ^= DCNT_PAGE;
}
