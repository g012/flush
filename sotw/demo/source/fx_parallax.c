#include <gba.h>
#include <gba_dma.h>
#include <gba_sprites.h>
#include <gba_systemcalls.h>
#include <string.h>

#include <maxmod.h>

#include "gbalib.h"

//GFX
#include "bg.h"

//BACKGROUND Landscape
#include "background.h"

//CLOUD BOTTOM
#include "cloud_bottom.h"

// CLOUD TOP
#include "cloud_top.h"

// MOUNTAIN BACK
#include "mountain_back.h"

#define MAX_BACKGROUND 4


extern const u16 running_wurst_palette[8];
extern const u8 running_wurst[12288];
extern mm_modlayer mmLayerMain;
static void init_sprites(void) {
    CpuFastSet(running_wurst_palette, SPRITE_PALETTE,
            (COPY16 | sizeof(running_wurst_palette) >> 1));

    CpuFastSet(running_wurst, BITMAP_OBJ_BASE_ADR, COPY32 | (12288 >> 2));
    OAM[0].attr0 = ATTR0_COLOR_16|ATTR0_NORMAL|ATTR0_TALL|OBJ_Y(100);
    OAM[0].attr1 = ATTR1_SIZE_64|OBJ_X(104);
    OAM[0].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(512);
}

static int next_sprite(sprite_id) {
    static int delay = 0;
    if (delay == 0) {
        ++sprite_id;
        if (sprite_id==12)
            sprite_id = 0;
        OAM[0].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(512+sprite_id*32);
        delay = 4;
    }
    --delay;
    return sprite_id;
}

static void PR_Cleanup(void)
{
    memset(BITMAP_OBJ_BASE_ADR, 0, 12288 >> 2);
}

static void MoveBackground(background *bg, s16 x, s16 y, s16 x_speed, s16 y_speed)
{
    bg->x_scroll = x + x_speed;
    bg->y_scroll = y + y_speed;
}

static void cleanVRAM()
{
    u32 i;
    vu32 *p = (vu32 *) VRAM;

    for (i = ((95 * 1024) >> 2) ; (VRAM + i) > VRAM ; i-=4) {
        *(p+i)     = 0;
    }
}



void main_fx_parallax(void) {
    int sprite_id = 0;
    u8 i;
    background bg[MAX_BACKGROUND];
    memset(bg,0,sizeof(bg));

    REG_DISPCNT = MODE_0 |
                  OBJ_ENABLE |
                    OBJ_1D_MAP;


    cleanVRAM();

    init_sprites();


    //InitializeBackground(number, charBaseBlock, screenBaseBlock8, colorMode, size,
    //                     mosaic, priority, x_scroll, y_scrol, x_speed, y_speed)

    // BG 0 - landscape
   InitializeBackground(&bg[0], 0, 0, 4, BG_COLOR_16, TEXTBG_SIZE_512x256,
                         0, 2, 0, 0, 6, 0);

    // BG 1 - cloud bottom
    InitializeBackground(&bg[1], 1, 1, 10, BG_COLOR_16, TEXTBG_SIZE_512x256,
                         0, 1, 0, 0, 4, 0);

    // BG 2 - cloud top
    InitializeBackground(&bg[2], 2, 2, 19, BG_COLOR_16, TEXTBG_SIZE_512x256,
                         0, 1, 0, 0, 2, 0);

    // BG 3 - mountain back
    InitializeBackground(&bg[3], 3, 3, 30, BG_COLOR_16, TEXTBG_SIZE_512x256,
                        0, 0, 0, 0, 5, 0);


    // copy BG 0 - landscape palette - palette index 0 ou 0x00
    CpuFastSet(backgroundPal,
              BG_PALETTE,
              COPY32 | (backgroundPalLen >> 2));

    // copy BG 1 - cloud bottom palette - palette index 1 ou 0x10
    CpuFastSet(cloud_bottomPal,
              BG_PALETTE + 16,
              COPY32 | (cloud_bottomPalLen >> 2));

    // BG 2 - cloud top palette - palette index 2 ou 0x20
    CpuFastSet(cloud_topPal,
              BG_PALETTE + 32,
              COPY32 | (cloud_topPalLen >> 2));

    // BG 3 - mountain back palette - palette index 3 ou 0x30
    CpuFastSet(mountain_backPal,
              BG_PALETTE + 48,
              COPY32 | (mountain_backPalLen >> 2));



    // copy datas BG 0 - landscape
    CpuFastSet(backgroundTiles,
              CHAR_BASE_ADR(bg[0].charBaseBlock),
              COPY32 | (backgroundTilesLen >> 2));

    CpuFastSet(backgroundMap,
              SCREEN_BASE_BLOCK(bg[0].screenBaseBlock),
              COPY32 | (backgroundMapLen >> 2));

    // copy datas BG 1 - cloud bottom
    CpuFastSet(cloud_bottomTiles,
              CHAR_BASE_ADR(bg[1].charBaseBlock),
              COPY32 | (cloud_bottomTilesLen >> 2));

    CpuFastSet(cloud_bottomMap,
              SCREEN_BASE_BLOCK(bg[1].screenBaseBlock),
              COPY32 | (cloud_bottomMapLen >> 2));

    // copy datas BG 2 - cloud top
    CpuFastSet(cloud_topTiles,
              CHAR_BASE_ADR(bg[2].charBaseBlock),
              COPY32 | (cloud_topTilesLen >> 2));

    CpuFastSet(cloud_topMap,
              SCREEN_BASE_BLOCK(bg[2].screenBaseBlock),
              (COPY32 | cloud_topMapLen >> 2));

    // copy datas BG 3 - mountain back
    CpuFastSet(mountain_backTiles,
              CHAR_BASE_ADR(bg[3].charBaseBlock),
              COPY32 | (mountain_backTilesLen >> 2));

    CpuFastSet(mountain_backMap,
              SCREEN_BASE_BLOCK(bg[3].screenBaseBlock),
              (COPY32 | mountain_backMapLen >> 2));

    for (i = 0; i < MAX_BACKGROUND ; i++)
        EnableBackground(&bg[i]);

    //     u32 time = 400;
    while(mmLayerMain.position!=24)
    {
        mmFrame();

        VBlankIntrWait();

        sprite_id = next_sprite(sprite_id);

        for (i = 0 ; i < MAX_BACKGROUND ; i++) {
            background *b = &bg[i];
            UpdateTextBackground(b);
            MoveBackground(b,
                           b->x_scroll,
                           b->y_scroll,
                           b->x_speed,
                           b->y_speed);
        }

        if (bg[0].x_scroll > 512)
            bg[0].x_scroll = 0;

        if (bg[1].x_scroll > 512)
            bg[1].x_scroll = 0;

        if (bg[2].x_scroll > 512)
            bg[2].x_scroll = 0;

        if (bg[3].x_scroll > 512)
            bg[3].x_scroll = 0;
    }

    PR_Cleanup();
}
