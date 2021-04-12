#include "gbalib.h"

void gfxLoad16(u16 *src, u16 *dst, int nb8) {
  int x,y;
  int xx,yy;
  u16 *sd;
  for(y=0; y<nb8; y++) {
    for(x=0; x<2; x++) {
      sd = (u16 *)src + (y*16*8/2) + (x*8/2);
      for(yy=0;yy<8;yy++) {
        for(xx=0;xx<4;xx++) {
          *dst++ = *(sd + (yy*16/2) + xx);
        }
      }
    }
  }
}

