#ifndef M7_H
#define M7_H

#include "demo.h"
#include "fixed.h"

/*
 *         |Y
 *         |
 *         |_______X
 *        /
 *      Z/
 */

// If enabled, caches the compact sin table in IWRAM.
// Computation is more complicated and less precise than
// the big table from ROM, but it reduces contention.
#define M7_CACHE_SIN

typedef struct
{
    x32v3 pos;      // [256, 32, 256]
    u16 rx, ry;     // [0, 0]
    s32 d;          // [256] distance to projection plane / FOV
    x32 near, far;  // [-24, -1024]
} M7Camera;

typedef struct
{
    x32v3 pos;
    x16 sx, sy;
    u16 a;
} M7Sprite;

typedef struct
{
    M7Camera cam;
    M7Sprite sprites[128];

    // internal
    u32 horizon; // backdrop scanline
    u32 linei; // current writable lines array
    BGAffineDest lines[2][SCREEN_HEIGHT + 1]; // BG2 affine settings for each line, for DMA, double buffered
    u16 fogBlendAlpha[2][SCREEN_HEIGHT + 1]; // REG_BLDALPHA values for each scanline to simulate fog
    union { OBJATTR objatt[128]; OBJAFFINE objaff[32]; }; // OAM cache
    u16 reciprocal[SCREEN_HEIGHT + 1]; // inverse_table first entries cache in IWRAM
#ifdef M7_CACHE_SIN
    u16 xsin[1025]; // compact sine table
#endif
} M7;
extern M7* g_m7;    // current m7 context - set it directly

extern void M7_Setup(M7* m7);
extern void M7_Start(void);
extern void M7_Stop(void); // should be called during VBlank
extern void M7_Flush(void); // compute cache
extern void M7_Swap(void); // send cache to hardware and swap cache buffers

#endif

