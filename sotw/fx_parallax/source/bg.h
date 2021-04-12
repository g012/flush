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
	s16 x_speed,y_speed;
	s32 DX,DY;
	s16 PA,PB,PC,PD;
	u16 priority;
} background;

extern void InitializeBackground(background *bg, u8 bgNumber, u8 charBaseBlock,
                         u8 screenBaseBlock, u8 colorMode, u16 bgSize,
                         u8 mosaic, u8 priority, s16 x_scroll, s16 y_scroll,
                         s16 x_speed, s16 y_speed);
extern void EnableBackground(background *bg);
extern void UpdateTextBackground(background *bg);

#endif
