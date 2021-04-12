#ifndef __BG_H_
#define __BG_H_

#include <gba.h>
#include <gba_types.h>
///BGCNT defines ///

#define BG_MOSAIC_ENABLE		0x40
#define BG_COLOR_256			0x80
#define BG_COLOR_16			0x0

#define CharBaseBlock(n)		(((n)*0x4000)+0x6000000)
#define ScreenBaseBlock(n)		(((n)*0x800)+0x6000000)

#define BG_CHAR_SHIFT			2
#define BG_SCREEN_SHIFT			8


typedef struct {
	u16 *tileData;
	u16 *mapData;
	u8 mosaic;
	u8 colorMode;
	u8 number;
	u16 size;
	u8 charBaseBlock;
	u8 screenBaseBlock;
	u8 wraparound;
	s16 x_scroll,y_scroll;
	s32 DX,DY;
	s16 PA,PB,PC,PD;
	u16 priority;
} background;

extern void EnableBackground(background *bg);
extern void UpdateTextBackground(background *bg);

#endif
