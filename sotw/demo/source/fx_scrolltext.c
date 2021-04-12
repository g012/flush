#include <gba.h>
#include <gba_dma.h>
#include <gba_sprites.h>

#include <maxmod.h>

#include "gbalib.h"

//GFX
#include "bg.h"
#include "euroascii8x8.h"
#define MAX_BACKGROUND 4

#include "fonts_squire.h"


#define MULTIBOOT int __gba_multiboot;
MULTIBOOT

background bg[MAX_BACKGROUND];

void PlotText(char*, u32, u32);

int main(void);



SpriteEntry sprite[128];

void CopyOAM(void) {
    u16 loop;
    u16 *ptrOAM = (u16 *) OAM;
    u16 *ptrSprite = (u16 *)(OBJATTR *)sprite;

    for (loop = 0 ; loop < 128 * 4 ; loop++) {
        ptrOAM[loop] = ptrSprite[loop];
    }
}

void FillSpritesPal(void) {
    int loop;

    for (loop = 0 ; loop < 256 ; loop++) {
        OBJ_COLORS[loop] = fontspal[loop];
    }
}

void InitSprites(void) {
    int loop;

    for (loop = 0 ; loop < 128 ; loop++) {
        sprite[loop].attribute[0] = 160 | ATTR0_DISABLED;
        sprite[loop].attribute[1] = 240;
    }
}

#define MAX_CHARS_RANGE 29

void convert2Index(char *s, int m, const char *chars_range, int n) {
    u16 loop, loop2;

    for (loop = 0 ; loop < m ; loop++) {
        for (loop2 = 0 ; loop2 < n ; loop2++) {
            if (s[loop] == chars_range[loop2]) {
                s[loop] = (char) loop2;
                break;
            }
        }
    }
}





void PlotText(char* TextIn, u32 PosX, u32 PosY) {

  u32 t=0;
  u16 i=PosY * 32 + PosX;
  while (1) {
    bg[0].mapData[i + t] = euroascii8x8Map[(u16)TextIn[t]] ; //Put the index into the map
    if (TextIn[t++] == 0) return; //We reached the end of the string
  }
}



void main_scroll(void) {
  s16 x = 100;
  s16 y = 60;
  u16 loop, decal = 0, offx = 0, lng;
  u16 *OAMData = (u16 *)OBJ_BASE_ADR;
  u16 s, e;
  char msg[] = "COUCOU LA COMPAGNIE ! ESPERONS QUE LE SCROLL EST PLAISANT HAHAHAHHA1H1AHAHAHHAIAIHAI                                       ";
  char chars_range[MAX_CHARS_RANGE+1] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ?!. ";

  REG_DISPCNT = MODE_0 | BG2_ENABLE | OBJ_ENABLE | OBJ_1D_MAP;

  InitSprites();

  lng = sizeof(msg) / sizeof(msg[0]);
  FillSpritesPal();
  convert2Index(msg, lng, chars_range, MAX_CHARS_RANGE + 1);

  (void)x;
  (void)e;
  y = 100;

  //aAbcdefghijklmn DCB "ABCDEFGHIJKLMNOPQRSTUVWXYZ?!. ",0
  s = 0;
  e = MAX_CHARS_RANGE + 1; // for having the bitmap fonts
  for (loop = s ; loop < (sizeof(fontsspr) / sizeof(fontsspr[0])) ; loop++) {
        OAMData[loop] = fontsspr[loop]; // print sprites
  }

  bg[0].number = 2;
  bg[0].charBaseBlock = 0;
  bg[0].screenBaseBlock = 10;
  bg[0].colorMode = BG_COLOR_256;
  bg[0].size = TEXTBG_SIZE_256x256;
  bg[0].mosaic = 0;
  bg[0].priority = 2;
  bg[0].x_scroll = 0;
  bg[0].y_scroll = 0;

  EnableBackground(&bg[0]);
  UpdateTextBackground(&bg[0]);

  dmaCopy(euroascii8x8Tiles, bg[0].tileData , euroascii8x8TilesLen /2);
  dmaCopy(euroascii8x8Pal, BG_COLORS, euroascii8x8PalLen /2);

  BG_COLORS[15]=RGB8(255,0,255);

  PlotText("BAC@ !$mMoO01234aaaaaaaaaaaaaa",0,0);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,1);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,2);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,3);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,4);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,5);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,6);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,7);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,8);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,9);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,10);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,11);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,12);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,13);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,14);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,15);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,16);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,17);
  PlotText("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAa",0,18);
  PlotText("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",0,19);


  u32 time = 400;
  while(time-->0)
   {
     mmFrame();
     VBlankIntrWait();
     CopyOAM();
     for (loop = 0 ; loop < 18 ; loop++) {
      sprite[loop].attribute[0] = ((ATTR0_COLOR_16 | ATTR0_SQUARE | ATTR0_NORMAL) & ~255) | (y & 255);
      sprite[loop].attribute[1] = (ATTR1_SIZE_16 & ~511) | (((loop * 16) - offx) & 511);
      sprite[loop].attribute[2] = msg[loop + decal] * 8 / 2;
    }

    offx++;

        if (offx > 16) {
            offx = 0;
            decal++;
            if (decal > lng) {
                decal=0;
            }
        }
  }
}
