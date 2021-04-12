#include "demo.h"
#include "3d.h"

extern u32 render_fire(u16 *screen, u32 seed, u8 *screen_buf);

#define VRAM_BUF1 (0x06000000)
typedef struct
{
    u8 *screen_buf;
    u32 seed;
} Fire;
static const u8 palette_data[] = {
	0,   0,   0,   64,
	128, 0,   0,   64,
	255, 128, 0,   64,
	255, 255, 0,   64,
	0,   0,   255, 0
};

void fx_fire_init(void)
{
    Fire* f;
    g_fx_data = f = iwalloc(sizeof(*f) + 128*81 * sizeof(u8));
    f->screen_buf = (u8*)f + sizeof(*f);
    f->seed = 0x42000000;
    LoadOverlay(OVERLAY_FIRE);
    palette_generation(palette_data, (u16*)0x5000000);
    REG_DISPCNT = MODE_4 | OBJ_1D_MAP | BG2_ON | OBJ_ON;
    REG_BG2PA = 0x80;
    REG_BG2PB = 0;
    REG_BG2PC = 0;
}

void fx_fire_deinit(void)
{
	iwfree(g_fx_data);
}

void fx_fire_exec(void)
{
    Fire* f = g_fx_data;
    u32 bb = VRAM_BUF1;
	VBlankIntrWait();
	f->seed = render_fire((u16 *)bb, f->seed, f->screen_buf);
}
