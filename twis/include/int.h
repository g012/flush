#ifndef INT_H
#define INT_H

#include "demo.h"

#define Bit_GetBitfieldSize(elemCount) (((elemCount) + 7) >> 3)
#define Bit_GetBitfieldEntry(array, index) ((array)[(index) >> 3] & (1 << ((index) & 7)))
#define Bit_SetBitfieldEntry(array, index) ((array)[(index) >> 3] |= (1 << ((index) & 7)))
#define Bit_ClearBitfieldEntry(array, index) ((array)[(index) >> 3] &= ~((1 << ((index) & 7))))

extern void Endian_Swap(u8* data, u32 dataSize);

#define U16_ToLittleEndian(v) (v)
#define S16_ToLittleEndian(v) (v)
#define U32_ToLittleEndian(v) (v)
#define S32_ToLittleEndian(v) (v)
#define U64_ToLittleEndian(v) (v)
#define S64_ToLittleEndian(v) (v)
#define Endian_ToLittle(data, dataSize)

#define U16_ToBigEndian(v) U16_EndianSwap(v)
#define S16_ToBigEndian(v) S16_EndianSwap(v)
#define U32_ToBigEndian(v) U32_EndianSwap(v)
#define S32_ToBigEndian(v) S32_EndianSwap(v)
#define U64_ToBigEndian(v) U64_EndianSwap(v)
#define S64_ToBigEndian(v) S64_EndianSwap(v)
#define Endian_ToBig(data, dataSize) Endian_Swap(data, dataSize)

#define U16_FromLittleEndian(v) (v)
#define S16_FromLittleEndian(v) (v)
#define U32_FromLittleEndian(v) (v)
#define S32_FromLittleEndian(v) (v)
#define U64_FromLittleEndian(v) (v)
#define S64_FromLittleEndian(v) (v)
#define Endian_FromLittle(data, dataSize)

#define U16_FromBigEndian(v) U16_EndianSwap(v)
#define S16_FromBigEndian(v) S16_EndianSwap(v)
#define U32_FromBigEndian(v) U32_EndianSwap(v)
#define S32_FromBigEndian(v) S32_EndianSwap(v)
#define U64_FromBigEndian(v) U64_EndianSwap(v)
#define S64_FromBigEndian(v) S64_EndianSwap(v)
#define Endian_FromBig(data, dataSize) Endian_Swap(data, dataSize)

/**************************************************************************
 * S32
 *************************************************************************/

#define S32_MAX 0x7FFFFFFF

static inline s32 S32_Abs(s32 a)
{ return (a ^ (a >> 31)) - (a >> 31); }

static inline s32 S32_CopySign(s32 x, s32 s)
{ return (x & 0x7FFFFFFF) | (s & 0x80000000); }

static inline s32 S32_Clamp(s32 x, s32 min, s32 max)
{
    if (x < min)
        x = min;
    if (x > max)
        x = max;
    return x;
}

static inline s32 S32_Max(s32 x, s32 y)
{ return x >= y ? x : y; }

static inline s32 S32_Min(s32 x, s32 y)
{ return y >= x ? x : y; }

// a ^ e
extern s32 S32_Pow(s32 a, s32 e);
// Log base 2 of x
// Return -1 if x is 0 (undefined)
extern s32 S32_Log2(s32 x);

static inline u32 S32_IsPow2(s32 x) { return x > 0 && (x & (~x + 1)) == x; }
extern s32 S32_LowPow(s32 x);
extern s32 S32_HighPow(s32 x);

/**************************************************************************
 * S32V2
 *************************************************************************/

typedef struct s32v2 s32v2;
struct s32v2
{
    union
    {
        struct { s32 x, y; };
        struct { s32 r, g; };
		struct { s32 num, den; }; // rational
        s32 d[2];
    };
};

/**************************************************************************
 * U32
 *************************************************************************/

#define U32_MAX 0xFFFFFFFF

static inline u32 U32_Max(u32 x, u32 y)
{ return x >= y ? x : y; }
static inline u32 U32_Min(u32 x, u32 y)
{ return y >= x ? x : y; }

static inline u32 U32_IsPow2(u32 x) { return x && (x & (~x + 1)) == x; }

extern u32 U32_Sqrt(u32 x);
extern u32 U32_CLZ(u32 x);
extern u32 U32_CTZ(u32 x);
extern u32 U32_CountOnes(u32 x);
extern u32 U32_RoundUpToPow2(u32 x);
// optimized to the matching instruction by all compilers
static inline u32 U32_Rol(u32 x, u8 s)
{ return (x << s) | (x >> (32 - s)); }
static inline u32 U32_Ror(u32 x, u8 s)
{ return (x >> s) | (x << (32 - s)); }

static inline u32 U32_EndianSwap(u32 x)
{
	asm volatile(
		"	rev		%0, %1"
		: "=r" (x)
		: "r" (x));
    return x;
}
static inline s32 S32_EndianSwap(s32 x)
{ return (s32)U32_EndianSwap((u32)(x)); }

/**************************************************************************
 * U32V2
 *************************************************************************/

typedef struct u32v2 u32v2;
struct u32v2
{
    union
    {
        struct { u32 x, y; };
        struct { u32 r, g; };
		struct { u32 num, den; }; // rational
        u32 d[2];
    };
};

/**************************************************************************
 * U32V3
 *************************************************************************/

typedef struct u32v3 u32v3;
struct u32v3
{
    union
    {
        struct { u32 x, y, z; };
        struct { u32 r, g, b; };
        u32 d[3];
    };
};

/**************************************************************************
 * S32V3
 *************************************************************************/

typedef struct s32v3 s32v3;
struct s32v3
{
    union
    {
        struct { s32 x, y, z; };
        struct { s32 r, g, b; };
        s32 d[3];
    };
};

/**************************************************************************
 * U32V4
 *************************************************************************/

typedef struct u32v4 u32v4;
struct u32v4
{
    union
    {
        struct { u32 x, y, z, w; };
        struct { u32 r, g, b, a; };
        u32 d[4];
    };
};

extern u32v4 U32V4_zero;
extern u32v4 U32V4_one;

extern u32 U32V4_IsEqual(u32v4* v1, u32v4* v2);

/**************************************************************************
 * U64
 *************************************************************************/

static inline u32 U64_CountOnes(u64 x)
{ return U32_CountOnes((u32)x) + U32_CountOnes((u32)(x >> 32)); }

extern u64 U64_Sqrt(u64 v);
extern u32 U64_CLZ(u64 x);
extern u32 U64_CTZ(u64 x);
extern u64 U64_RoundUpToPow2(u64 x);
static inline u64 U64_Rol(u64 x, u8 s)
{ return (x << s) | (x >> (64 - s)); }
static inline u64 U64_Ror(u64 x, u8 s)
{ return (x >> s) | (x << (64 - s)); }

static inline u64 U64_EndianSwap(u64 x)
{
	u32 lo = (u32)x, hi = (u32)(x >> 32);
	asm volatile("	rev		%0, %1" : "=r" (lo) : "r" (lo));
	asm volatile("	rev		%0, %1" : "=r" (hi) : "r" (hi));
	return (u64)hi + ((u64)lo << 32);
}
static inline s64 S64_EndianSwap(s64 x)
{ return (s64)U64_EndianSwap((u64)(x)); }

/**************************************************************************
 * S128
 *************************************************************************/

typedef struct s128 s128;
struct s128
{
    u64 lo;
    s64 hi;
};

static const s128 S128_zero = { 0, 0 };
static const s128 S128_max = { 0xFFFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF };
static const s128 S128_min = { 0, 0x8000000000000000 };

static inline void S128_FromS64(s128* v, s64 l)
{
    v->lo = (u64)l;
    v->hi = l < 0 ? -1 : 0;
}

static inline void S128_FromU64(s128* v, u64 l)
{
    v->lo = l;
    v->hi = 0;
}

#define S128_ToS64(v) ((s64)(v.lo))
#define S128_ToU64(v) (v.lo)

static inline void S128_Inc(s128* a)
{
    ++a->lo;
    if (a->lo == 0)
        ++a->hi;
}

static inline void S128_Add(s128* a, s128* b)
{
    u64 l = a->lo + b->lo;
    if (l < a->lo)
        ++a->hi;
    a->hi += b->hi;
    a->lo = l;
}

static inline void S128_RAdd(s128* r, s128* a, s128* b)
{
    r->lo = a->lo + b->lo;
    r->hi = a->hi + b->hi;
    if (r->lo < a->lo)
        ++r->hi;
}

static inline void S128_Dec(s128* a)
{
    if (a->lo == 0)
        --a->hi;
    --a->lo;
}

static inline void S128_Not(s128* a)
{
    a->lo = ~a->lo;
    a->hi = ~a->hi;
}

static inline void S128_RNot(s128* r, s128* a)
{
    r->lo = ~a->lo;
    r->hi = ~a->hi;
}

static inline void S128_And(s128* a, s128* b)
{
    a->lo &= b->lo;
    a->hi &= b->hi;
}

static inline void S128_RAnd(s128* r, s128* a, s128* b)
{
    r->lo = a->lo & b->lo;
    r->hi = a->hi & b->hi;
}

static inline void S128_Or(s128* a, s128* b)
{
    a->lo |= b->lo;
    a->hi |= b->hi;
}

static inline void S128_ROr(s128* r, s128* a, s128* b)
{
    r->lo = a->lo | b->lo;
    r->hi = a->hi | b->hi;
}

static inline void S128_Xor(s128* a, s128* b)
{
    a->lo ^= b->lo;
    a->hi ^= b->hi;
}

static inline void S128_RXor(s128* r, s128* a, s128* b)
{
    r->lo = a->lo ^ b->lo;
    r->hi = a->hi ^ b->hi;
}

extern void S128_RLShift(s128* r, s128* a, s32 n);
extern void S128_RRShift(s128* r, s128* a, s32 n);

static inline void S128_LShift(s128* a, s32 n)
{
    s128 t;
    S128_RLShift(&t, a, n);
    a->lo = t.lo, a->hi = t.hi;
}

static inline void S128_RShift(s128* a, s32 n)
{
    s128 t;
    S128_RRShift(&t, a, n);
    a->lo = t.lo, a->hi = t.hi;
}

static inline s32 S128_Compare(const s128* a, const s128* b)
{
    if (a->hi < b->hi)
        return -1;
    if (b->hi < a->hi)
        return 1;
    if (a->lo < b->lo)
        return -1;
    if (b->lo < a->lo)
        return 1;
    return 0;
}

static inline s32 S128_HashCode(s128* v)
{
    s64 x = v->hi ^ (s64)v->lo;
    return (s32)(x >> 32) ^ (s32)(x & 0xFFFFFFFF);
}

static inline void S128_Neg(s128* a)
{
    S128_Not(a);
    S128_Inc(a);
}

static inline void S128_RNeg(s128* r, s128* a)
{
    S128_RNot(r, a);
    S128_Inc(r);
}

static inline void S128_Sub(s128* a, s128* b)
{
    s128 t;
    S128_RNeg(&t, b);
    S128_Add(a, &t);
}

static inline void S128_RSub(s128* r, s128* a, s128* b)
{
    S128_RNeg(r, b);
    S128_Add(r, a);
}

extern void S128_RMul(s128* r, s128* a, s128* b);

static inline void S128_Mul(s128* a, s128* b)
{
    s128 t;
    S128_RMul(&t, a, b);
    a->lo = t.lo;
    a->hi = t.hi;
}

extern void S128_UnsignedDivMod(s128* dividend, s128* divisor,
        s128* quotient, s128* remainder);
extern void S128_DivMod(s128* dividend, s128* divisor,
        s128* quotient, s128* remainder);

static inline void S128_RDiv(s128* r, s128* a, s128* b)
{
    s128 rem;
    S128_DivMod(a, b, r, &rem);
}

static inline void S128_Div(s128* a, s128* b)
{
    s128 q, r;
    S128_DivMod(a, b, &q, &r);
    a->lo = q.lo, a->hi = q.hi;
}

static inline void S128_RMod(s128* r, s128* a, s128* b)
{
    s128 q;
    S128_DivMod(a, b, &q, r);
}

static inline void S128_Mod(s128* a, s128* b)
{
    s128 q, r;
    S128_DivMod(a, b, &q, &r);
	a->lo = r.lo, a->hi = r.hi;
}

/**************************************************************************
 * S16V2
 *************************************************************************/

typedef struct s16v2 s16v2;
struct s16v2
{
	union
	{
		struct { s16 x, y; };
		struct { s16 w, h; };
		s16 d[2];
	};
};

/**************************************************************************
 * U16
 *************************************************************************/

static inline u16 U16_EndianSwap(u16 x)
{
	asm volatile(
		"	rev16	%0, %1"
		: "=r" (x)
		: "r" (x));
    return x;
}
static inline s16 S16_EndianSwap(s16 x)
{ return (s16)U16_EndianSwap((u16)(x)); }

/**************************************************************************
 * U16V2
 *************************************************************************/

typedef struct u16v2 u16v2;
struct u16v2
{
	union
	{
		struct { u16 x, y; };
		struct { u16 w, h; };
		u16 d[2];
	};
};

/**************************************************************************
 * S32V4
 *************************************************************************/

typedef struct s32v4 s32v4;
struct s32v4
{
    union
    {
        struct { s32 x, y, z; };
        struct { s32 u, v, w; };
        s32 d[3];
    };
};

#endif
