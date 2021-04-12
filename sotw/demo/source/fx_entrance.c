#include <stdlib.h>
#include <string.h>
#include <gba.h>
#include <maxmod.h>

#include "entrance.h"

#pragma GCC diagnostic ignored "-Wunused-function"

#define PAD_KEYS (*(volatile u32*)0x04000130)
unsigned short int * entrance_VideoBuffer = (unsigned short int *) 0x6000000;
unsigned short int * entrance_Palette = (unsigned short int *) 0x5000000;
unsigned short int * entrance_FrontBuffer = (unsigned short int *) 0x6000000;
unsigned short int * entrance_BackBuffer = (unsigned short int *) 0x600A000;
extern mm_modlayer mmLayerMain;
extern const u16 walking_wurst_palette[16];
extern const u8 walking_wurst[12288];

extern const u16 wurst_hand_open_palette[16];
extern const u8 wurst_hand_open[1024];

extern const u16 wurst_hand_closed_palette[16];
extern const u8 wurst_hand_closed[1024];

static void init_sprites(void) {
  memcpy(SPRITE_PALETTE, walking_wurst_palette, sizeof(walking_wurst_palette));
  memcpy(BITMAP_OBJ_BASE_ADR, walking_wurst, 12288);
  OAM[0].attr0 = ATTR0_COLOR_16|ATTR0_NORMAL|ATTR0_TALL|OBJ_Y(110);
  OAM[0].attr1 = ATTR1_SIZE_64|OBJ_X(1);
  OAM[0].attr2 = ATTR2_PALETTE(0)|ATTR2_PRIORITY(0)|OBJ_CHAR(512);
  memcpy(SPRITE_PALETTE+16, wurst_hand_open_palette, sizeof(wurst_hand_open_palette));
  memcpy(BITMAP_OBJ_BASE_ADR+sizeof(walking_wurst), wurst_hand_open, sizeof(wurst_hand_open));
  
  
  OAM[1].attr0 = ATTR0_COLOR_16|ATTR0_NORMAL|OBJ_WIDE|OBJ_Y(110);
  OAM[1].attr1 = ATTR1_SIZE_64|OBJ_X(300);
  OAM[1].attr2 = ATTR2_PALETTE(1)|ATTR2_PRIORITY(0)|OBJ_CHAR(512+12*32);
  
  memcpy(SPRITE_PALETTE+32, wurst_hand_closed_palette, sizeof(wurst_hand_closed_palette));
  memcpy(BITMAP_OBJ_BASE_ADR+sizeof(walking_wurst)+sizeof(wurst_hand_open), wurst_hand_closed, sizeof(wurst_hand_closed));
  
  
  OAM[2].attr0 = ATTR0_COLOR_16|ATTR0_NORMAL|OBJ_WIDE|OBJ_Y(110);
  OAM[2].attr1 = ATTR1_SIZE_64|OBJ_X(300);
  OAM[2].attr2 = ATTR2_PALETTE(2)|ATTR2_PRIORITY(0)|OBJ_CHAR(512+13*32);
  
  
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
void show_main(pos_x,nbsprite){
  OAM[nbsprite].attr0 = ATTR0_COLOR_16|ATTR0_NORMAL|OBJ_WIDE|OBJ_Y(110);
  OAM[nbsprite].attr1 = ATTR1_SIZE_64|OBJ_X(pos_x);
  OAM[nbsprite].attr2 = ATTR2_PALETTE(nbsprite)|ATTR2_PRIORITY(0)|OBJ_CHAR(512+(11+nbsprite)*32);
}


void main_fx_entrance(void) {
  int sprite_id = 0,pos_x,speed,pos_x_main,direc;
  pos_x_main=200;
  direc=0;
  pos_x=1;
  speed=5;

  REG_DISPCNT = MODE_4 | OBJ_1D_MAP | BG2_ON | OBJ_ON;
  
  dmaCopy((void*)entrance, (void*)entrance_VideoBuffer , 38400);
  dmaCopy((void*)entrancePalette, (void*)entrance_Palette , 512);
  init_sprites();

  
       u32 time = 420;
  while(--time > 0)//mmLayerMain.position!=26)
  {
    BG_PALETTE[0] = 0;
    if (!(PAD_KEYS & 0x200))
      BG_PALETTE[0] = 0x3def;
    mmFrame();
    VBlankIntrWait();
    if(direc==0){
      sprite_id = next_sprite(sprite_id,pos_x);
      speed--;
      if(speed==0){
	pos_x++;
	speed=2;
      }
      if((pos_x>=180) && (pos_x<200))
      {
	show_main(pos_x_main,1);
	pos_x_main--;
      }
      
      if(pos_x_main == pos_x){
	direc=1;
      }
    }
    if(direc==1)
    {
      show_main(pos_x_main,2);
      sprite_id = next_sprite(sprite_id,300);
      show_main(300,1);
      pos_x_main++;
      if(pos_x_main>=300)
	pos_x_main=290;
    }
  }
  memset(BITMAP_OBJ_BASE_ADR, 0,0x4000) ;
}
