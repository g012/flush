#include <stdlib.h>
#include <string.h>
#include <gba.h>
#include <maxmod.h>
// 
extern mm_modlayer mmLayerMain;

#include "troat.h"
#include "traject.h"
#pragma GCC diagnostic ignored "-Wunused-function"

#define PAD_KEYS (*(volatile u32*)0x04000130)
unsigned short int * troat_VideoBuffer = (unsigned short int *) 0x6000000;
unsigned short int * troat_Palette = (unsigned short int *) 0x5000000;
unsigned short int * troat_FrontBuffer = (unsigned short int *) 0x6000000;
unsigned short int * troat_BackBuffer = (unsigned short int *) 0x600A000;

void troat_FlipBuffer(){
  if(REG_DISPCNT & 0x10){
    REG_DISPCNT &= ~0x10;
    troat_VideoBuffer=troat_BackBuffer;
  }else{
    REG_DISPCNT |= 0x10;
    troat_VideoBuffer=troat_FrontBuffer;
  }
}

#include "wurst.c.h"
static void init_sprites(void) {
    memcpy(SPRITE_PALETTE,wurst_palette, sizeof(wurst_palette));
    memcpy(BITMAP_OBJ_BASE_ADR, wurst, sizeof(wurst));
    OAM[0].attr0 = ATTR0_COLOR_16|ATTR0_WIDE|OBJ_Y(-70);
    OAM[0].attr1 = OBJ_SHAPE(1)|OBJ_SIZE(3)|OBJ_X(100);
    OAM[0].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(512);
}


static void next_sprite(pos_x,pos_y,zoom) {
   OAM[0].attr0 = ATTR0_COLOR_16|ATTR0_NORMAL|ATTR0_WIDE|OBJ_Y(pos_y)|ATTR0_ROTSCALE;
   OAM[0].attr1 = ATTR1_SIZE_64|OBJ_X(pos_x+30)|ATTR1_ROTDATA(0);
   OAM[0].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(512);
   OAM[0].dummy=(256+zoom)/1;
   OAM[3].dummy=(256+zoom)/1;
}

void main_fx_troat(void) {
    int pos_x,pos_y,speed,MAX_TRAJ,pos_traj,zoom;
    pos_x=1;
    speed=5;
    pos_traj=0;
    zoom=0;
    MAX_TRAJ=sizeof(line);

    troat_FlipBuffer();
    memcpy(troat_VideoBuffer,troat,sizeof(troat));
    memcpy(troat_Palette,troatPalette,sizeof(troatPalette));
   troat_FlipBuffer();
    memcpy(troat_VideoBuffer,troat,sizeof(troat));
    //dmaCopy((void*)troat, (void*)troat_VideoBuffer , 38400);

    init_sprites();

    REG_DISPCNT = MODE_4 | OBJ_1D_MAP | BG2_ON | OBJ_ON;
    u32 s_bb = (u32)MODE5_BB;
  
    
      u32 time = 400;
    while(time-->0){
        BG_PALETTE[0] = 0;
        if (!(PAD_KEYS & 0x200))
            BG_PALETTE[0] = 0x3def;
	mmFrame();
        VBlankIntrWait();
	speed--;
 	if(speed==0){
	  pos_x=line[pos_traj];
	  if(pos_traj+25<MAX_TRAJ){
	    pos_traj++;
	    pos_y=line[pos_traj];
	    pos_traj++;
	    if(zoom!=256)zoom=zoom+3;
	  }else{
	    zoom=zoom+46;
	  }
	  next_sprite(pos_x,pos_y,zoom);
	  speed=2;
	}
        s_bb ^= 0xA000;
        REG_DISPCNT ^= BACKBUFFER;
    }
}
