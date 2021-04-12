#include <stdlib.h>
#include <string.h>
#include <gba.h>

#include "3d.h"

#pragma GCC diagnostic ignored "-Wunused-function"

#define PAD_KEYS (*(volatile u32*)0x04000130)
#define MAX_VERTICES 3100

extern const s16 sotw[];
extern const u8 sotw_palette_data[];

extern const u16 running_wurst_palette[16];
extern const u8 running_wurst[12288];

static void render(u16 *b, const s16 *obj, s16* two_d_buf, u32 t) {
    s32 matrix[9];
    static const s16 light[3] = {-18918,18918,18918};
    s16 tx,ty,tz,rx,ry,rz;
    if (t < 600) {
        tx=300-t;
        ty=13;
        tz=-230,
        rx=0;
        ry=0;
        rz=0;
    } else if (t < 600+128) {
        t -= 600;
        tx = -300+300*t/128;
        ty = 13-13*t/128;
        tz = -230-170*t/128;
        rx = 0x1000*t/128;
        ry = 0x100*t/128;
        rz = 0;
    } else {
        tx = 0;
        ty = 0;
        tz = -400;
        rx = 0x1000;
        ry = 0x100;
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

__attribute__ ((noreturn)) int main(void) {
    u32 t = 0;
    int sprite_id = 0;
    s16 *two_d_buf = malloc(MAX_VERTICES*3*2);

    irqInit();
    irqEnable(IRQ_VBLANK);

    palette_generation(sotw_palette_data, BG_PALETTE);

    init_sprites();

    REG_DISPCNT = MODE_4 | OBJ_1D_MAP | BG2_ON | OBJ_ON;
    u32 s_bb = (u32)MODE5_BB;

    for (;;) {
        BG_PALETTE[0] = 0;
        render((u16 *)s_bb, sotw, two_d_buf, t++);
        sprite_id = next_sprite(sprite_id,t);
        if (!(PAD_KEYS & 0x200))
            BG_PALETTE[0] = 0x3def;
        VBlankIntrWait();
        s_bb ^= 0xA000;
        REG_DISPCNT ^= BACKBUFFER;
    }
}
