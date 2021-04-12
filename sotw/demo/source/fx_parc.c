#include <stdlib.h>
#include <string.h>
#include <gba.h>
#include <maxmod.h>
// 
extern mm_modlayer mmLayerMain;

#include "parc_expo.h"
#pragma GCC diagnostic ignored "-Wunused-function"
extern mm_modlayer mmLayerMain;


#define PAD_KEYS (*(volatile u32*)0x04000130)
unsigned short int * fx_parc_VideoBuffer = (unsigned short int *) 0x6000000;
unsigned short int * fx_parc_Palette = (unsigned short int *) 0x5000000;
unsigned short int * fx_parc_FrontBuffer = (unsigned short int *) 0x6000000;
unsigned short int * fx_parc_BackBuffer = (unsigned short int *) 0x600A000;

void fx_parc_FlipBuffer(){
  if(REG_DISPCNT & 0x10){
    REG_DISPCNT &= ~0x10;
    fx_parc_VideoBuffer=fx_parc_BackBuffer;
  }else{
    REG_DISPCNT |= 0x10;
    fx_parc_VideoBuffer=fx_parc_FrontBuffer;
  }
}

extern const u16 walking_wurst_palette[16];
extern const u8 walking_wurst[12288];

static void init_sprites(void) {
    memcpy(SPRITE_PALETTE, walking_wurst_palette, sizeof(walking_wurst_palette));
    memcpy(BITMAP_OBJ_BASE_ADR, walking_wurst, 12288);
    OAM[0].attr0 = ATTR0_COLOR_16|ATTR0_NORMAL|ATTR0_TALL|OBJ_Y(110);
    OAM[0].attr1 = ATTR1_SIZE_64|OBJ_X(1);
    OAM[0].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(512);
}

static int next_sprite(sprite_id,pos_x) {
    static int delay = 0;
    if (delay == 0) {
        ++sprite_id;
        if (sprite_id==12)
            sprite_id = 0;
	OAM[0].attr1 = ATTR1_SIZE_64|OBJ_X(pos_x);
        OAM[0].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(512+sprite_id*32);
        delay = 10;
    }
    --delay;
    return sprite_id;
}

void main_fx_parc(void) {
    int sprite_id = 0,pos_x,speed;
    pos_x=1;
    speed=5;


    fx_parc_FlipBuffer();
    dmaCopy((void*)fx_parc_splash, (void*)fx_parc_VideoBuffer , 38400);
    dmaCopy((void*)fx_parc_splashPalette, (void*)fx_parc_Palette , 512);
    fx_parc_FlipBuffer();
    dmaCopy((void*)fx_parc_splash, (void*)fx_parc_VideoBuffer , 38400);

    init_sprites();

    REG_DISPCNT = MODE_4 | OBJ_1D_MAP | BG2_ON | OBJ_ON;
    u32 s_bb = (u32)MODE5_BB;

    //     u32 time = 400;
    while(mmLayerMain.position!=14)
    {
        BG_PALETTE[0] = 0;
        if (!(PAD_KEYS & 0x200))
            BG_PALETTE[0] = 0x3def;
	
	mmFrame();
        VBlankIntrWait();
        sprite_id = next_sprite(sprite_id,pos_x);
	speed--;
	if(speed==0){
	  pos_x++;
	  speed=3;
	}
        s_bb ^= 0xA000;
        REG_DISPCNT ^= BACKBUFFER;
    }
}
