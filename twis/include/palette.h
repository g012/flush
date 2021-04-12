#ifndef PALETTE_H
#define PALETTE_H

#include <gba_types.h>

// weight range: [0, 32]
extern void palette_blend(u16* from, u16* to, u16* dst, u32 colcount, u32 weight);
extern void palette_fade(u16* src, u16 to, u16* dst, u32 colcount, u32 weight);

#endif

