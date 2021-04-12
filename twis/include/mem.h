#ifndef MEM_H
#define MEM_H

#include <gba.h>

extern void memcpy16(void* dst, const void* src, u32 size);
extern void memcpy16_count(void* dst, const void* src, u32 count);
extern void memcpy32(void* dst, const void* src, u32 size);
extern void memcpy32_count(void* dst, const void* src, u32 count);
extern void memset16(void* dst, u32 val, u32 size);
extern void memset16_count(void* dst, u32 val, u32 count);
extern void memset32(void* dst, u32 val, u32 size);
extern void memset32_count(void* dst, u32 val, u32 count);

static inline void dmaCopy32(const void * source, void * dest, u32 size) {
	DMA_Copy(3, source, dest, DMA32 | size>>2);
}
// make it easier to replace a memcpy by a DMA copy
#define dmacpy16(dst, src, sz) dmaCopy(src, dst, sz)
#define dmacpy32(dst, src, sz) dmaCopy32(src, dst, sz)

static inline void dmaset16(void* dst, vu32 val, u32 size)
{
	REG_DMA3SAD = (u32)&val;
	REG_DMA3DAD = (u32)dst;
	REG_DMA3CNT = DMA_ENABLE | DMA16 | DMA_SRC_FIXED | size>>1;
}
static inline void dmaset32(void* dst, vu32 val, u32 size)
{
	REG_DMA3SAD = (u32)&val;
	REG_DMA3DAD = (u32)dst;
	REG_DMA3CNT = DMA_ENABLE | DMA32 | DMA_SRC_FIXED | size>>2;
}

static inline void oam_disable(void* dst, u32 c) // c max: 128
{ u32 i, *d = dst; for (i = 0; i < c; ++i) *d++ = ATTR0_DISABLED, *d++ = 0; }
static inline OBJATTR* obj_setx(OBJATTR* o, s32 x)
{ o->attr1 &= ~0x1FF; o->attr1 |= OBJ_X(x); return o; }
static inline OBJATTR* obj_sety(OBJATTR* o, s32 y)
{ o->attr0 &= ~0xFF; o->attr0 |= OBJ_Y(y); return o; }
static inline OBJATTR* obj_setpos(OBJATTR* o, s32 x, s32 y)
{ obj_sety(o, y); obj_setx(o, x); return o; }
static inline OBJATTR* obj_setpriority(OBJATTR* o, s32 p)
{ o->attr2 &= ~0xC00; o->attr2 |= ATTR2_PRIORITY(p); return o; }
static inline OBJATTR* obj_setchar(OBJATTR* o, s32 c)
{ o->attr2 &= ~0x3FF; o->attr2 |= OBJ_CHAR(c); return o; }
static inline OBJATTR* obj_setshape(OBJATTR* o, s32 s)
{ o->attr0 &= ~0xC000; o->attr0 |= s; return o; }
static inline OBJATTR* obj_setsize(OBJATTR* o, s32 s)
{ o->attr1 &= ~0xC000; o->attr1 |= s; return o; }
static inline OBJATTR* obj_setflipx(OBJATTR* o, s32 f)
{ if (f) o->attr1 |= ATTR1_FLIP_X; else o->attr1 &= ~ATTR1_FLIP_X; return o; }
static inline OBJATTR* obj_setflipy(OBJATTR* o, s32 f)
{ if (f) o->attr1 |= ATTR1_FLIP_Y; else o->attr1 &= ~ATTR1_FLIP_Y; return o; }
static inline OBJATTR* obj_setflipxy(OBJATTR* o, s32 fx, s32 fy)
{ fx |= fy << 1; o->attr1 &= ~(ATTR1_FLIP_X | ATTR1_FLIP_Y); o->attr1 |= fx; return o; }

#endif

