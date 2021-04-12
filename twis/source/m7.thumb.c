#include "m7.h"

extern void M7_HBlank(void);

M7* g_m7 = 0;

void M7_Setup(M7* m7)
{
    m7->horizon = 60;
    m7->cam.pos.x = X32_FromInt(0x100);
    m7->cam.pos.y = X32_FromInt(0x20); 
    m7->cam.pos.z = X32_FromInt(0x100);
    m7->cam.rx = 0;
    m7->cam.ry = 0x2000;
    m7->cam.d = 256;
    m7->cam.near = -24;
    m7->cam.far = -1024;
    m7->linei = 0;
    memset32(m7->lines, 0, sizeof(m7->lines));
    memset32(m7->fogBlendAlpha, 0, sizeof(m7->fogBlendAlpha));
    memset32(m7->objatt, ATTR0_DISABLED, sizeof(m7->objatt));
    memcpy16(m7->reciprocal, inverse_table, sizeof(m7->reciprocal));
#ifdef M7_CACHE_SIN
    memcpy16(m7->xsin, X32_sin, sizeof(m7->xsin));
#endif
}

void M7_Start(void)
{
    REG_BLDCNT = 0x3B44; // BG2 above with any layer under, alpha blend mode
    REG_BLDALPHA = 0x0010; // BG2 full
}

void M7_Stop(void)
{
    // stop DMA 0
    // must occur during VBlank to avoid DMA lock up
    // (see Programming Manual section 12.4)
    if (REG_VCOUNT < 160) VBlankIntrWait();
    REG_DMA0CNT = 0; 

    // restore default BG2 transform
    REG_BG2PA = 0x0100;
    REG_BG2PB = 0;
    REG_BG2PC = 0;
    REG_BG2PD = 0x0100;
    REG_BG2X = 0;
    REG_BG2Y = 0;

    // stop fog
    REG_BLDCNT = 0;

    // hide all sprites
    memset32(OAM, ATTR0_DISABLED, 0x400);
}

