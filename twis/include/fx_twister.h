#ifndef FX_TWISTER_H
#define FX_TWISTER_H

#define FX_TWISTER_AMP 64
#define FX_TWISTER_HFX_TWISTER_AMP 64

typedef struct 
{
    u32 bb;
    u8 fc;
    u8 vamp;
    u16 flags;
    u32 theta;
    s16 theta_inc;
    u16 render_flat;
    s16 sync;
    s16 sync2;

    OBJATTR oam[128];
} Twister;

extern void fx_twister_init(void);
extern void fx_twister_deinit(void);
extern void fx_twister_exec(void);

extern void fx_twister_clearscreen(void* screen);
extern void fx_twister_render_flat(void);
extern void fx_twister_render_tex(void);
extern void fx_twister_line_flat(u16* d, u32 x0, u32 x1, u32 col);
extern void fx_twister_bg(void);

#endif

