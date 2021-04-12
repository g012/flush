#include <stdlib.h>
#include <string.h>
#include <gba.h>

#include <maxmod.h>

#include "3d.h"

#define PAD_KEYS (*(volatile u32*)0x04000130)
#define MAX_VERTICES 400


extern mm_modlayer mmLayerMain;
extern const s16 sotw[];
extern const u8 sotw_palette_data[];

extern const u16 running_wurst_palette[16];
extern const u8 running_wurst[12288];
extern const u16 sotw_size;

static void render(u16 *b, const s16 *obj, s16* two_d_buf, u32 t) {
    s32 matrix[9];
    static const s16 light[3] = {-18918,18918,18918};
    s16 tx,ty,tz,rx,ry,rz;
    if (t < 600) {
        tx=300-t;
        ty=13;
        tz=-250,
        rx=0;
        ry=0;
        rz=0;
    } else if (t < 600+128) {
        t -= 600;
        tx = -300+300*t/128;
        ty = 13-13*t/128;
        tz = -250-180*t/128;
        rx = 0x1000*t/128;
        ry = 4*t/128;
        rz = 0;
    } else {
        tx = 0;
        ty = 0;
        tz = -430;
        rx = 0x1000;
        ry = 4;
        rz = 0;
    }
    clear_screen(b);
    make_matrix(matrix, rx, ry, rz);
    rotransjection(two_d_buf, obj, matrix, tx, ty, tz);
    draw_object(b, two_d_buf, matrix, obj, light);
}

static void init_sprites(void) {
    memcpy(SPRITE_PALETTE, running_wurst_palette, sizeof(running_wurst_palette));
    memcpy(BITMAP_OBJ_BASE_ADR, running_wurst, 12288);
    OAM[0].attr0 = ATTR0_COLOR_16|ATTR0_NORMAL|ATTR0_TALL|OBJ_Y(100);
    OAM[0].attr1 = ATTR1_SIZE_64|OBJ_X(104);
    OAM[0].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(512);
}

static int next_sprite(int sprite_id, u32 t) {
    static int delay = 0;
    if (delay == 0) {
        ++sprite_id;
        if (sprite_id==12)
            sprite_id = 0;
        OAM[0].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(512+sprite_id*32);
        delay = 4;
    }
    OAM[0].attr1 = ATTR1_SIZE_64|OBJ_X((t*240*(0x10000/600))>>16);
    --delay;
    return sprite_id;
}

void main_title(void) {
    u32 t = 0;
    int sprite_id = 0;
    s16 *two_d_buf = malloc(MAX_VERTICES*3*2);
    s16 *obj_buf = malloc(sotw_size);
    memcpy(obj_buf, sotw, sotw_size);

    palette_generation(sotw_palette_data, BG_PALETTE);

    init_sprites();

    REG_DISPCNT = MODE_4 | OBJ_1D_MAP | BG2_ON | OBJ_ON;
    u32 s_bb = (u32)MODE5_BB;

    //     u32 time = 400;
    while(mmLayerMain.position!=20)
    {
        BG_PALETTE[0] = 0;
        render((u16 *)s_bb, obj_buf, two_d_buf, t++);
        sprite_id = next_sprite(sprite_id,t);
        if (!(PAD_KEYS & 0x200))
            BG_PALETTE[0] = 0x3def;
        mmFrame();
        VBlankIntrWait();
        s_bb ^= 0xA000;
        REG_DISPCNT ^= BACKBUFFER;
    }
    free(obj_buf);
    free(two_d_buf);
}
