#include "demo.h"

#include "bg01.h"
#include "fg01.h"
#include "dirt01.h"

#include "fixed.h"
#include "sin256.h"
#include "twister_pal.h"
#include "twister_tex_pal.h"
#include "fx_twister.h"

void fx_twister_init(void)
{
    Twister* t;
    g_fx_data = t = iwalloc(sizeof(*t));
    t->bb = VRAM_BUF2;
    t->fc = 0;
    // when changing this, need to change the rounding of light / line length (64: &0x80>>8, 32: &0x40>>7, ...)
    t->vamp = 128;
    t->theta = 0;
    t->theta_inc = 0x100;
    t->render_flat = 1;
    t->sync = 0;
    t->sync2 = 0;

    LoadOverlay(OVERLAY_TWISTER);

    // sprite background
    memcpy32(SPRITE_PALETTE, bg01Pal, bg01PalLen);
    memcpy32(CHAR_BASE_BLOCK(5), bg01Tiles, bg01TilesLen);
    OBJATTR bgt = { ATTR0_SQUARE | ATTR0_COLOR_256 | OBJ_Y(60), ATTR1_SIZE_64 | OBJ_X(60), ATTR2_PRIORITY(3) | OBJ_CHAR(512) }; 
    OBJATTR* oam = t->oam;
    oam_disable(oam, 128);
    s32 x, y, i;
    for (y = 0, i = 0; y < 160+64; y += 64)
    {
        bgt.attr0 &= ~0xFF; bgt.attr0 |= OBJ_Y(y);
        //bgt.attr1 ^= ATTR1_FLIP_Y;
        //if (y & 0x40) bgt.attr1 ^= ATTR1_FLIP_X;
        for (x = 0; x < 240+64*4; x += 64, ++i)
        {
            bgt.attr1 &= ~0x1FF; bgt.attr1 |= OBJ_X(x - 32);
            //bgt.attr1 ^= ATTR1_FLIP_X;
            //if (x & 0x40) bgt.attr1 ^= ATTR1_FLIP_Y;
            oam[i] = bgt;
        }
    }
#if 0
    // sprite foreground
    memcpy32((u8*)CHAR_BASE_BLOCK(5) + bg01TilesLen, fg01Tiles, fg01TilesLen);
    obj_setpriority(&bgt, 0);
    obj_setchar(&bgt, 512 + bg01TilesLen*2 / 64);
    obj_setsize(&bgt, ATTR1_SIZE_32);
    oam[i++] = *obj_setpos(&bgt, 0, 0);
    oam[i++] = *obj_setflipx(obj_setx(&bgt, 240-32), 1);
    oam[i++] = *obj_setflipy(obj_sety(&bgt, 160-32), 1);
    oam[i++] = *obj_setflipx(obj_setx(&bgt, 0), 0);
#endif
    // noise fx
    memcpy32((u8*)CHAR_BASE_BLOCK(5) + bg01TilesLen/* + fg01TilesLen*/, dirt01Tiles, dirt01TilesLen);
    obj_setpriority(&bgt, 0);
    obj_setshape(&bgt, ATTR0_TALL);
    obj_setsize(&bgt, ATTR1_SIZE_32);
    obj_setflipxy(&bgt, 0, 0);
    u32 ochar0 = 512 + 2 * (16 * 4);
    u32 ochar;
    for (y = 0; y < 5; ++y)
    {
        obj_sety(&bgt, y * 32);
        if (y > 2) { obj_setflipy(&bgt, 1); ochar = (5 - y) * 8*2*7; }
        else ochar = 8*2*7 * y;
        s32 xdir = 1;
        for (x = 0; x < 15; ++x, ++i, ochar += xdir*8*2)
        {
            if (x == 8) xdir = 0; if (x == 9) xdir = -1;
            obj_setflipx(&bgt, x > 8);
            obj_setx(&bgt, x * 16);
            obj_setchar(&bgt, ochar + ochar0);
            oam[i] = bgt;
        }
    }
    // blend
    REG_BLDCNT = 0x0450; // blend OBJ with BG/backdrop, but not other objs
    REG_BLDALPHA = 0x1005; // weights

    //memcpy32((void*)BG_PALETTE, twister_tex_pal_bin, twister_tex_pal_bin_size);
    memcpy32(BG_PALETTE, twister_pal, twister_pal_size);
    
    // clear right half of screens since it's not cleared during the effect
    fx_twister_clearscreen((u8*)t->bb + SCREEN_WIDTH/2);
    fx_twister_clearscreen((u8*)(t->bb ^ VRAM_BUFSWITCH) + SCREEN_WIDTH/2);

    REG_BG2CNT = BG_PRIORITY(2);
    REG_DISPCNT = MODE_4 | BG2_ON | OBJ_ON | OBJ_1D_MAP;
}

void fx_twister_deinit(void)
{
    iwfree(g_fx_data);
    oam_disable(OAM, 128);
    REG_BLDCNT = 0;
}

