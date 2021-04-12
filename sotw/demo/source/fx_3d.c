#include <stdlib.h>
#include <string.h>
#include <gba.h>

#include <maxmod.h>

#include "interdit1_sprite_bin.h"
#include "interdit0_sprite_bin.h"
#include "interdit0_pal_bin.h"
#include "3d.h"

#pragma GCC diagnostic ignored "-Wunused-function"

#define PAD_KEYS (*(volatile u32*)0x04000130)
#define MAX_VERTICES 3100

extern mm_modlayer mmLayerMain;

extern const s16 torus[];

static void UpdateSprites(int t)
{
    u32 y = 80;
    u32 x = 120;
    if ((t & 0x3f) < 0x20)
        x += 256;
    OAM[0].attr0 = ATTR0_COLOR_16|ATTR0_SQUARE|OBJ_Y(y-64);
    OAM[0].attr1 = OBJ_SHAPE(0)|OBJ_SIZE(3)|OBJ_X(x-64);
    OAM[0].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(0x200);
    OAM[1].attr0 = ATTR0_COLOR_16|ATTR0_SQUARE|OBJ_Y(y-64);
    OAM[1].attr1 = OBJ_SHAPE(0)|OBJ_SIZE(3)|OBJ_X(x)|ATTR1_FLIP_X|ATTR1_FLIP_Y;
    OAM[1].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(0x240);
    OAM[3].attr0 = ATTR0_COLOR_16|ATTR0_SQUARE|OBJ_Y(y);
    OAM[3].attr1 = OBJ_SHAPE(0)|OBJ_SIZE(3)|OBJ_X(x-64);
    OAM[3].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(0x240);
    OAM[2].attr0 = ATTR0_COLOR_16|ATTR0_SQUARE|OBJ_Y(y);
    OAM[2].attr1 = OBJ_SHAPE(0)|OBJ_SIZE(3)|OBJ_X(x)|ATTR1_FLIP_X|ATTR1_FLIP_Y;
    OAM[2].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(0x200);
}
static void LoadSprites(void)
{
    memcpy((u8*)SPRITE_PALETTE, interdit0_pal_bin, 16);
    memcpy(BITMAP_OBJ_BASE_ADR, interdit0_sprite_bin, interdit0_sprite_bin_size);
    memcpy((u8*)BITMAP_OBJ_BASE_ADR+64*32, interdit1_sprite_bin, interdit1_sprite_bin_size);
    UpdateSprites(0);
}

static void render(u16 *b, const s16 *obj, s16* two_d_buf, u32 t) {
    s32 matrix[9];
    static const s16 light[3] = {-18918,18918,18918};
    s16 tx=0,ty=0,tz=-500,rx=(16*t)&0x3fff,ry=(16*t)&0x3fff,rz=(16*t)&0x3fff;
    clear_screen(b);
    make_matrix(matrix, rx, ry, rz);
    rotransjection(two_d_buf, obj, matrix, tx, ty, tz);
    draw_object(b, two_d_buf, matrix, obj, light);
}

void main_3d(void) {
    static const u8 palette_data[] = {
        0,   0,   0,   24,
        255, 192, 0,   7,
        255, 255, 255, 1,
        0,   0,   255, 224,
        0,   0,   255, 0
    };
    u32 t = 0;
    s16 *two_d_buf = malloc(MAX_VERTICES*3*2);

    palette_generation(palette_data, (u16*)0x5000000);
    LoadSprites();

    //REG_DISPCNT = MODE_4 | BG2_ON;
    REG_DISPCNT = MODE_4 | OBJ_1D_MAP | BG2_ON | OBJ_ON;
    u32 s_bb = (u32)MODE5_BB;

//     u32 time = 400;
    while(mmLayerMain.position!=7)
    {
        BG_PALETTE[0] = 0;
        render((u16 *)s_bb, torus, two_d_buf, t++);
        if (!(PAD_KEYS & 0x200))
            BG_PALETTE[0] = 0x3def;
        mmFrame();
        VBlankIntrWait();
        UpdateSprites(t);
        s_bb ^= 0xA000;
        REG_DISPCNT ^= BACKBUFFER;
    }

    free(two_d_buf);

    memset(BITMAP_OBJ_BASE_ADR, 0, 2*interdit0_sprite_bin_size);
    memset(OAM, 0, (u8*)&OAM[4] - (u8*)&OAM[0]);
}
