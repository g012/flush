#include "m7.h"

#ifdef M7_CACHE_SIN
#  define M7_Sin(a) X32_SinIdxFrom(a, m7->xsin)
#  define M7_Cos(a) X32_CosIdxFrom(a, m7->xsin)
#else
#  define M7_Sin(a) X32_SinIdx2(a)
#  define M7_Cos(a) X32_CosIdx2(a)
#endif

IWRAM_O1_CODE void M7_Flush(void)
{
    M7* m7 = g_m7;
    BGAffineDest* line = m7->lines[m7->linei];
    u16* fog_blda = m7->fogBlendAlpha[m7->linei];
    u16* reciprocal = m7->reciprocal;
    s32 d = m7->cam.d;
    s32 cam_posy8 = m7->cam.pos.y >> 4;
    x32 cam_posx = m7->cam.pos.x, cam_posz = m7->cam.pos.z;
    s32 cos_cam_ry8, sin_cam_ry8;
    u32 horizon = m7->horizon;
    u32 i;

    // precompute next frame BG2 affine data for each scanline
    sin_cam_ry8 = M7_Sin(m7->cam.ry) >> 4;
    cos_cam_ry8 = M7_Cos(m7->cam.ry) >> 4;
    line += horizon;
    fog_blda += horizon;
    for (i = horizon + 1; i <= SCREEN_HEIGHT; ++i, ++line, ++fog_blda) // last line value unused so not computed
    {
        x32 lam, lcf, lsf, lxr, lyr;

        lam = cam_posy8 * (s32)reciprocal[i] >> 12;
        lcf = lam * cos_cam_ry8 >> 8;
        lsf = lam * sin_cam_ry8 >> 8;

        line->pa = lcf >> 4; // BGiPA/B/C/D are signed 8.8 fixed point registers
        line->pc = lsf >> 4;

        lxr = SCREEN_WIDTH/2 * (lcf >> 4) << 4; // truncated
        lyr = d * lsf;
        line->x = cam_posx - lxr + lyr >> 4; // BGiX/Y are signed 20.8 fixed point registers

        lxr = SCREEN_WIDTH/2 * (lsf >> 4) << 4;
        lyr = d * lcf;
        line->y = cam_posz - lxr - lyr >> 4;

        u32 ey = lam*6 >> 12;
        if (ey > 0x10) ey = 0x10;
        *fog_blda = (u16)(0x10-ey | ey << 8);
    }
}

IWRAM_O1_CODE void M7_Swap(void)
{
    M7* m7 = g_m7;
    BGAffineDest* line = m7->lines[m7->linei];
    u16* fog_blda = m7->fogBlendAlpha[m7->linei];
    m7->linei ^= 1;

    // set OAM from precomputed cache
    dmacpy32(OAM, m7->objatt, sizeof(m7->objatt));
    
    // set DMA0 to flush precomputed BG2 affine data on each HBlank
    REG_DMA0CNT = 0;
    REG_DMA0SAD = (u32)&line[1];
    REG_DMA0DAD = (u32)&REG_BG2PA;
    REG_DMA0CNT = DMA_ENABLE | DMA32 | DMA_HBLANK | DMA_REPEAT | DMA_DST_RELOAD | sizeof(*line) >> 2;
    // set DMA3 to flush precomputed alpha blend
    REG_DMA3CNT = 0;
    REG_DMA3SAD = (u32)&fog_blda[1];
    REG_DMA3DAD = (u32)&REG_BLDALPHA;
    REG_DMA3CNT = DMA_ENABLE | DMA16 | DMA_HBLANK | DMA_REPEAT | DMA_DST_RELOAD | sizeof(*fog_blda) >> 1;
    // set first line (HBlank happens AFTER each scanline, so the last one is basically useless)
    REG_BG2PA = line->pa;
    REG_BG2PC = line->pc;
    REG_BG2X = line->x;
    REG_BG2Y = line->y;
    REG_BLDALPHA = fog_blda[0];
}

