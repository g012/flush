#include <stdio.h>
#include "demo.h"

extern char __iwram_overlay_start[];
extern char __load_start_iwram0[];
extern char __load_stop_iwram0[];
extern char __load_start_iwram1[];
extern char __load_stop_iwram1[];

IWRAM_O0_CODE void Overlay0()
{
	printf("%s\n", __func__);
}

IWRAM_O1_CODE void Overlay1()
{
	printf("%s\n", __func__);
}

void t_overlay_init(void)
{
    consoleInit(0, 4, 0, 0, 0, 15);
    SetMode(MODE_0 | BG0_ON);
    BG_COLORS[0]=RGB8(58,110,165);
	BG_COLORS[241]=RGB5(31,31,31);
    printf("@Overlay0: %p\n@Overlay1: %p\n", Overlay0, Overlay1);
    Overlay0(); // copied by crt0
	dmaCopy(__load_start_iwram1, __iwram_overlay_start, (u32)__load_stop_iwram1 - (u32)__load_start_iwram1);
	Overlay1();
	dmaCopy(__load_start_iwram0, __iwram_overlay_start, (u32)__load_stop_iwram0 - (u32)__load_start_iwram0);
	Overlay0();
}

void t_overlay_deinit(void)
{
}

void t_overlay_exec(void)
{
	VBlankIntrWait();
}

