#include <stdlib.h>
#include <string.h>
#include <gba.h>
#include "fxtn_a_bin.h"
#include "fxtn_d_bin.h"
#include "fxtn_sin_bin.h"
#include "fxtn_tex_bin.h"
#include "fxtn_pal_bin.h"

#pragma GCC diagnostic ignored "-Wunused-function"

#define VRAM_BUF1 (0x06000000)
#define VRAM_BUF2 (0x0600A000)
#define DCNT_PAGE (0x10)

#define REG_INTERNALMEMORYCONTROL (*((vu32*)0x4000800))

#define TN_Update TN_Update_C

static u32 s_xo, s_yo;
static u32 s_xs, s_ys;
static u16* s_d;
static u16* s_a;
static u8* s_tex;

IWRAM_CODE static void TN_Update_S(vu16* d)
{
    u32 xo = s_xo;
    u32 yo = s_yo;
    u32 xs = fxtn_sin_bin[s_xs & 0xFF] * 240 >> 8;
    u32 ys = fxtn_sin_bin[s_ys & 0xFF] * 160 >> 8;
    u32 ol = xs + SCREEN_WIDTH*2 * ys;
    asm volatile(

        "   mov     r3, #160                     \n"
        "1: mov     r4, #120                     \n"

        "2: ldrb    r0, [%[t_d], %[ol]]          \n"
        "   add     r0, r0, %[xo]                \n"
        "   and     r0, r0, #0xFF                \n"
        "   ldrb    r1, [%[t_a], %[ol]]          \n"
        "   add     r1, r1, %[yo]                \n"
        "   and     r1, r1, #0xFF                \n"
        "   add     r0, r0, r1, asl #8           \n"
        "   ldrb    r2, [%[t_tex], r0]           \n"
        "   add     %[ol], %[ol], #1             \n"

        "   ldrb    r0, [%[t_d], %[ol]]          \n"
        "   add     r0, r0, %[xo]                \n"
        "   and     r0, r0, #0xFF                \n"
        "   ldrb    r1, [%[t_a], %[ol]]          \n"
        "   add     r1, r1, %[yo]                \n"
        "   and     r1, r1, #0xFF                \n"
        "   add     r0, r0, r1, asl #8           \n"
        "   ldrb    r0, [%[t_tex], r0]           \n"
        "   add     %[ol], %[ol], #1             \n"

        "   add     r0, r2, r0, asl #8           \n"
        "   strh    r0, [%[d]], #2               \n"

        "   subS    r4, r4, #1                   \n"
        "   bne     2b                           \n"
        "   add     %[ol], %[ol], #240           \n"
        "   subS    r3, r3, #1                   \n"
        "   bne     1b                           \n"

        : [ol]"=&r"(ol), [d]"+r"(d)
        : [xo]"r"(xo), [yo]"r"(yo), [t_tex]"r"(&fxtn_tex_bin), [t_a]"r"(&fxtn_a_bin), [t_d]"r"(&fxtn_d_bin)
        : "cc", "r0", "r1", "r2", "r3", "r4"
    );
    s_xo += 8;
    s_yo += 2;
    s_xs += 1;
    s_ys += 2;
}

IWRAM_CODE static void TN_Update_C(vu16* d)
{
    u32 x, y, o;
    u32 xo = s_xo;
    u32 yo = s_yo;
    u32 xs = fxtn_sin_bin[s_xs & 0xFF] * 240 >> 8;
    u32 ys = fxtn_sin_bin[s_ys & 0xFF] * 160 >> 8;
    u32 ol = (xs + SCREEN_WIDTH*2 * ys) >> 1;
    for (o = 0, y = 0; y < SCREEN_HEIGHT; ++y, ol += SCREEN_WIDTH/2)
        for (x = 0; x < SCREEN_WIDTH/2; ++x, ++o, ++ol)
        {
            u32 dist = s_d[ol];
            u32 angl = s_a[ol];
            u32 d0 = s_tex[ (((dist&0xFF) + xo) & 0xFF) + ((((angl&0xFF) + yo) & 0xFF) << 8) ];
            u32 d1 = s_tex[ (((dist>>8) + xo) & 0xFF) + ((((angl>>8) + yo) & 0xFF) << 8) ];
            d[o] = (u16)((d1<<8)|d0);
        }
    s_xo += 8;
    s_yo += 2;
    s_xs += 1;
    s_ys += 2;
}

__attribute__ ((noreturn)) IWRAM_CODE int main(void)
{
    u32 bb = VRAM_BUF2;

    // overclock ewram
    REG_INTERNALMEMORYCONTROL = (REG_INTERNALMEMORYCONTROL & 0x00FFFFFF) | (0x0E000000);

    s_d = malloc(fxtn_d_bin_size);
    memcpy(s_d, fxtn_d_bin, fxtn_d_bin_size);
    s_a = (u16*)fxtn_a_bin; // not enough place to put them all in ewram
    s_tex = malloc(fxtn_tex_bin_size);
    memcpy(s_tex, fxtn_tex_bin, fxtn_tex_bin_size);

    irqInit();
    irqEnable(IRQ_VBLANK);

    REG_DISPCNT = MODE_4 | BG2_ON;
    memcpy((void*)BG_PALETTE, fxtn_pal_bin, fxtn_pal_bin_size);

    for (;;)
    {
        TN_Update((vu16*)bb);
        VBlankIntrWait();
        bb ^= 0xA000;
        REG_DISPCNT ^= DCNT_PAGE;
    }
}
