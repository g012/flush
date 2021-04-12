#include "bg.h"

void EnableBackground(background *bg)
{
	u16 temp;

	bg->tileData = (u16*)CharBaseBlock(bg->charBaseBlock);
	bg->mapData = (u16*)ScreenBaseBlock(bg->screenBaseBlock);
	temp = bg->size | (bg->charBaseBlock<<BG_CHAR_SHIFT) | (bg->screenBaseBlock<<BG_SCREEN_SHIFT)
		| bg->colorMode | bg->mosaic | bg->wraparound | bg->priority;

	switch(bg->number)
	{
	case 0:
		{
			REG_BG0CNT = temp;
			REG_DISPCNT |= BG0_ENABLE;
		}break;
	case 1:
		{
			REG_BG1CNT = temp;
			REG_DISPCNT |= BG1_ENABLE;
		}break;
	case 2:
		{
			REG_BG2CNT = temp;
			REG_DISPCNT |= BG2_ENABLE;
		}break;
	case 3:
		{
			REG_BG3CNT = temp;
			REG_DISPCNT |= BG3_ENABLE;
		}break;

	default:break;

	}
}

void UpdateTextBackground(background *bg)
{
	switch(bg->number)
	{
	case 0:
		REG_BG0HOFS = bg->x_scroll;
		REG_BG0VOFS = bg->y_scroll;
		break;
	case 1:
		REG_BG1HOFS = bg->x_scroll;
		REG_BG1VOFS = bg->y_scroll;
		break;
	case 2:
		REG_BG2HOFS = bg->x_scroll;
		REG_BG2VOFS = bg->y_scroll;
    break;
	case 3:
	  REG_BG3HOFS = bg->x_scroll;
	  REG_BG3VOFS = bg->y_scroll;
    break;
	default: break;
	}
}

