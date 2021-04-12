#ifndef FIXED_H
#define FIXED_H

#include "demo.h"
#include "int.h"
#include "fixed_const.h"

typedef s16 x16;
typedef s32 x32;
typedef s64 x64;
typedef s64 x64c;

// Fixed point 0.16
extern const u16 X32_atan16[17];
// Sine table [0, Pi/2[ ([0, 1024] indices) - 12 bits angle precision - 4.12 - no overlap minimal table, can be copied to IWRAM
extern const u16 X32_sin[1025];
// Sine/Cosine overlapping tables from 3d - 14 bits angle precision - 1.15
extern const s16 sin_table[0x4000]; 
extern const s16 cos_table[0x4000]; 
// Arc Sine table
extern const u16 X32_asin[1024];
// Arc Tangent table
extern const u16 X32_atan[129];
// Inverse table from 3d - 0.16
extern const u16 inverse_table[3000];

/*
 * Fixed point 4.12
 */

#define X16_SHIFT 12
#define X16_INTBITS 4
#define X16_DECBTTS 12
#define X16_BITS 16

#define X16_INTMASK 0xF000
#define X16_DECMASK 0x0FFF
#define X16_SIGNMASK 0x8000

#define X16_MAX 0x7FFF
#define X16_MIN 0x8000
#define X16_ZERO 0
#define X16_ONE 0x1000
#define X16_HALF 0x0800
#define X16_SQRT_1_2 0xB50 // 0.707
#define X16_SQRT_3 0x1BB6 // 1.732
#define X16_SQRT_2 0x16A1 // 1.414
#define X16_SQRT_1_3 0x093D // 0.577

#define X16_FromInt(v) ((v) << X16_SHIFT)
#define X16_ToInt(v) ((v) >> X16_SHIFT)
#define X16_FromX64c(v) ((x16)(((v) >> X64C_SHIFT - X16_SHIFT)))

static inline x16 X16_Mul(x16 a, x16 b)
{
    s32 r = (s32)a * (s32)b;
    r += X16_HALF;
    r >>= X16_SHIFT;
    return (x16)r;
}

static inline x16 X16_Div(x16 a, x16 b)
{
    s32 n = (s32)a << X16_SHIFT + 1;
    n = (n / b + 1) >> 1;
    return (x16)n;
}

static inline x16 X16_Rem(x16 a, x16 b)
{
    return (x16)(((s32)a << X16_SHIFT) % b);
}

#define X16_Ceil(a) (((a) + (1 << X16_SHIFT) - 1) & X16_INTMASK)
#define X16_Floor(a) ((a) & X16_INTMASK)
#define X16_Round(a) (((a) + X16_HALF) & X16_INTMASK)

static inline x16 X16_Abs(x16 a)
{
    return (x16)((a ^ (a >> X16_BITS - 1)) - (a >> X16_BITS - 1));
}

/*
 * Fixed point 52.12
 */

#define X64_SHIFT 12
#define X64_INTBITS 52
#define X64_DECBTTS 12
#define X64_BITS 64

#define X64_INTMASK 0xFFFFFFFFFFFFF000
#define X64_DECMASK 0x0000000000000FFF
#define X64_SIGNMASK 0x8000000000000000

#define X64_MAX 0x7FFFFFFFFFFFFFFF
#define X64_MIN 0x8000000000000000
#define X64_ZERO 0
#define X64_ONE 0x1000
#define X64_HALF 0x0800
#define X64_SQRT_1_2 0xB50 // 0.707
#define X64_SQRT_3 0x1BB6 // 1.732
#define X64_SQRT_2 0x64A1 // 1.414
#define X64_SQRT_1_3 0x093D // 0.577

#define X64_FromInt(v) ((v) << X64_SHIFT)
#define X64_ToInt(v) ((v) >> X64_SHIFT)
#define X64_FromX64c(v) ((v) >> X64C_SHIFT - X64_SHIFT)

extern x64 X64_Mul(x64 a, x64 b);
extern x64 X64_Mul32(x64 a, x32 b);
extern x64 X64_Div(x64 a, x64 b);
extern x64 X64_Rem(x64 a, x64 b);

#define X64_FMod(a, b) ((a) % (b))
#define X64_Ceil(a) (((a) + (1 << X64_SHIFT) - 1) & X64_INTMASK)
#define X64_Floor(a) ((a) & X64_INTMASK)
#define X64_Round(a) (((a) + X64_HALF) & X64_INTMASK)

static inline x64 X64_Abs(x64 a)
{
    return (x64)((a ^ (a >> X64_BITS - 1)) - (a >> X64_BITS - 1));
}

static inline s32 X64_HashCode(x64 v)
{
    return (s32)(v >> 32) ^ (s32)v;
}

/*
 * Fixed point 32.32
 */

#define X64C_SHIFT 32
#define X64C_INTBITS 32
#define X64C_DECBTTS 32
#define X64C_BITS 64

#define X64C_INTMASK 0xFFFFFFFF00000000
#define X64C_DECMASK 0x00000000FFFFFFFF
#define X64C_SIGNMASK 0x8000000000000000

#define X64C_FromInt(v) ((v) << X64C_SHIFT)
#define X64C_ToInt(v) ((v) >> X64C_SHIFT)
#define X64C_FromX32(v) ((x64c)(v) << X64C_SHIFT - X32_SHIFT)

extern x64c X64C_Mul(x64c a, x64c b);
extern x64c X64C_Mul32(x64c a, x32 b);
extern x64c X64C_Div(x64c a, x64c b);
extern x64c X64C_Rem(x64c a, x64c b);

#define X64C_FMod(a, b) ((a) % (b))
#define X64C_Ceil(a) (((a) + (1LL << X64C_SHIFT) - 1) & X64C_INTMASK)
#define X64C_Floor(a) ((a) & X64C_INTMASK)
#define X64C_Round(a) (((a) + X64C_HALF) & X64C_INTMASK)
#define X64C_Frac(a) ((a) & X64C_DECMASK)

static inline x64c X64C_Abs(x64c a)
{
    return (x64c)((a ^ (a >> X64C_BITS - 1)) - (a >> X64C_BITS - 1));
}

static inline s32 X64C_HashCode(x64c v)
{
    return (s32)(v >> 32) ^ (s32)v;
}

// Compute the sine of angle using a Taylor serie expansion
extern x64c X64C_SinTaylor(x32 angle);
// Compute the cosine of angle using a Taylor serie expansion
extern x64c X64C_CosTaylor(x32 angle);

/*
 * Fixed point 20.12
 */

#define X32_SHIFT 12
#define X32_INTBITS 20
#define X32_DECBITS 12
#define X32_BITS 32

#define X32_INTMASK 0xFFFFF000
#define X32_DECMASK 0x00000FFF
#define X32_SIGNMASK 0x80000000

#define X32_FromInt(v) ((v) << X32_SHIFT)
#define X32_ToInt(v) ((v) >> X32_SHIFT)
#define X32_FromX64c(v) ((x32)(((v) >> X64C_SHIFT - X32_SHIFT)))

static inline x32 X32_Mul(x32 a, x32 b)
{
    s64 r = (s64)a * (s64)b;
    r += X32_HALF;
    r >>= X32_SHIFT;
    return (x32)r;
}

static inline x32 X32_Div(x32 a, x32 b)
{
    s64 n = (s64)a << X32_SHIFT + 1;
    n = (n / b + 1) >> 1;
    return (x32)n;
}
// Uses 3d's inverse table
static inline x32 X32_Reciprocal(x32 a)
{
    if (a >= sizeof(inverse_table) / sizeof(*inverse_table))
        a = sizeof(inverse_table) / sizeof(*inverse_table) - 1;
    return inverse_table[a] >> 4; // 0.16 to 20.12
}
// Uses 3d's inverse table to divide
static inline x32 X32_DivIdx(x32 a, x32 b)
{
    return X32_Mul(a, X32_Reciprocal(b));
}

static inline x32 X32_Rem(x32 a, x32 b)
{
    return (x32)(((s64)a << X32_SHIFT) % b);
}

extern x32 X32_Pow(x32 a, s32 e);
extern x32 X32_Sqrt(x32 a);

// Get the sine of an a16 (u16 as angle) from a table.
// No interpolation, unprecise but fast.
// Angle range: 0 - 0xFFF
#define X32_SinIdx(index) X32_SinIdxFrom(index, X32_sin)
extern x32 X32_SinIdxFrom(s32 index, const u16* sin); // uses the cache table provided (ideally placed in IWRAM)
// Get the sine from 3d's sine table.
// Angle range: 0 - 0x3FFF
static inline x32 X32_SinIdx2(s32 index)
{
    return sin_table[(index & 0xFFFF) >> 2] >> 3; // convert 1.15 to 20.12
}

// Get the cosine of an a16 (u16 as angle) from a table.
// No interpolation, unprecise but fast.
#define X32_CosIdx(index) X32_CosIdxFrom(index, X32_sin)
static inline x32 X32_CosIdxFrom(s32 index, const u16* sin)
{
    // cos(x) = sin(x) + Pi/2
    return X32_SinIdxFrom(index + 0x4000, sin);
}
static inline x32 X32_CosIdx2(s32 index)
{
    return cos_table[(index & 0xFFFF) >> 2] >> 3; // convert 1.15 to 20.12
}

// Read the arc sine from a table.
extern u16 X32_ASinIdx(x32 v);

// Read the arc cosine from a table.
static inline u16 X32_ACosIdx(x32 v)
{
    // acos(x) = Pi/2 - asin(x)
    return (u16)(0x4000 - X32_ASinIdx(v));
}

// Read the arc tangent from a table.
extern u16 X32_ATanIdx(x32 v);
extern u16 X32_ATan2Idx(x32 y, x32 x);

// Convert to u16 units but with x32 precision.
static inline x32 X32_RadToA16(x32 a)
{
    return X32_Mul(a, X32_65536_2Pi);
}

// Convert the angle to u16 then read the value
// from a table.
static inline x32 X32_Sin(x32 a)
{
    return X32_SinIdx(X32_ToInt(X32_RadToA16(a)));
}

// Convert the angle to u16 then read the value
// from a table.
static inline x32 X32_Cos(x32 a)
{
    return X32_CosIdx(X32_ToInt(X32_RadToA16(a)));
}

// Get the acos from a table and convert it to
// radians.
static inline x32 X32_ACos(x32 v)
{
    return (x32)((s64)X32_ACosIdx(v) * X64C_2Pi_65536 + X64C_HALF >> X64C_SHIFT - X32_SHIFT);
}

// Get the asin from a table and convert it to
// radians.
static inline x32 X32_ASin(x32 v)
{
    return (x32)((s64)X32_ASinIdx(v) * X64C_2Pi_65536 + X64C_HALF >> X64C_SHIFT - X32_SHIFT);
}

// Get the atan from a table and convert it to
// radians.
static inline x32 X32_ATan(x32 v)
{
    return (x32)((s64)X32_ATanIdx(v) * X64C_2Pi_65536 + X64C_HALF >> X64C_SHIFT - X32_SHIFT);
}

// Get the atan from a table and convert it to
// radians.
static inline x32 X32_ATan2(x32 y, x32 x)
{
    return (x32)((s64)X32_ATan2Idx(y, x) * X64C_2Pi_65536 + X64C_HALF >> X64C_SHIFT - X32_SHIFT);
}

// Compute sine and cosine from an atan table.
extern void X32_SinCosFromATan(x32 a, x32* s, x32* c);
// Computes the tangent from an arc tangent table.
extern x32 X32_TanFromATan(x32 a);

static inline x32 X32_Abs(x32 a)
{
    return (x32)((a ^ (a >> X32_BITS - 1)) - (a >> X32_BITS - 1));
}

static inline x32 X32_Clamp(x32 x, x32 min, x32 max)
{
    if (x < min)
        x = min;
    if (x > max)
        x = max;
    return x;
}

static inline x32 X32_Lerp(x32 x, x32 y, x32 amount)
{
    return x + X32_Mul(y - x, amount);
}

static inline x32 X32_Max(x32 x, x32 y)
{
    return x >= y ? x : y;
}

static inline x32 X32_Min(x32 x, x32 y)
{
    return y >= x ? x : y;
}

static inline x32 X32_FMod(x32 a, x32 b)
{
    return a % b;
}

static inline x32 X32_Frac(x32 a)
{
    return a & X32_DECMASK;
}

#define X32_Ceil(a) (((a) + (1 << X32_SHIFT) - 1) & X32_INTMASK)
#define X32_Floor(a) ((a) & X32_INTMASK)
#define X32_Round(a) (((a) + X32_HALF) & X32_INTMASK)

static inline x32 X32_RoundToZero(x32 v)
{
    if (v < 0)
        v += (1 << X32_SHIFT) - 1;
    v &= X32_INTMASK;
    return v;
}

static inline s32 X32_HashCode(x32 v)
{
    return (s32)v;
}

/**************************************************************************
 * X32V2
 *************************************************************************/

typedef struct x32v2 x32v2;
struct x32v2
{
    union
    {
        struct { x32 x, y; };
        struct { x32 u, v; };
        x32 d[2];
    };
};

/**************************************************************************
 * X32V3
 *************************************************************************/

typedef struct x32v3 x32v3;
struct x32v3
{
    union
    {
        struct { x32 x, y, z; };
        struct { x32 u, v, w; };
        x32 d[3];
    };
};

extern x32v3 X32V3_zero;
extern x32v3 X32V3_one;
extern x32v3 X32V3_unitX;
extern x32v3 X32V3_unitY;
extern x32v3 X32V3_unitZ;

static inline void X32V3_Neg(x32v3* u)
{
    u->x = -u->x;
    u->y = -u->y;
    u->z = -u->z;
}

static inline void X32V3_RNeg(x32v3* d, x32v3* u)
{
    d->x = -u->x;
    d->y = -u->y;
    d->z = -u->z;
}

static inline void X32V3_Add(x32v3* u, x32v3* v)
{
    u->x += v->x;
    u->y += v->y;
    u->z += v->z;
}

static inline void X32V3_RAdd(x32v3* d, x32v3* u, x32v3* v)
{
    d->x = u->x + v->x;
    d->y = u->y + v->y;
    d->z = u->z + v->z;
}

static inline void X32V3_Sub(x32v3* u, x32v3* v)
{
    u->x -= v->x;
    u->y -= v->y;
    u->z -= v->z;
}

static inline void X32V3_RSub(x32v3* d, x32v3* u, x32v3* v)
{
    d->x = u->x - v->x;
    d->y = u->y - v->y;
    d->z = u->z - v->z;
}

extern void X32V3_CMul(x32v3* u, x32 scale);
extern void X32V3_RCMul(x32v3* d, x32v3* u, x32 scale);

static inline void X32V3_ICMul(x32v3* u, s32 scale)
{
    u->x *= scale;
    u->y *= scale;
    u->z *= scale;
}

static inline void X32V3_RICMul(x32v3* d, x32v3* u, s32 scale)
{
    d->x = u->x * scale;
    d->y = u->y * scale;
    d->z = u->z * scale;
}

extern void X32V3_Mul(x32v3* u, x32v3* v);
extern void X32V3_RMul(x32v3* d, x32v3* u, x32v3* v);
extern void X32V3_CDiv(x32v3* u, x32 scale);
extern void X32V3_RCDiv(x32v3* d, x32v3* u, x32 scale);

static inline void X32V3_ICDiv(x32v3* u, s32 scale)
{
    u->x /= scale;
    u->y /= scale;
    u->z /= scale;
}

static inline void X32V3_RICDiv(x32v3* d, x32v3* u, s32 scale)
{
    d->x = u->x / scale;
    d->y = u->y / scale;
    d->z = u->z / scale;
}

extern void X32V3_Div(x32v3* u, x32v3* v);
extern void X32V3_RDiv(x32v3* d, x32v3* u, x32v3* v);

static inline u32 X32V3_Equal(x32v3* u, x32v3* v)
{
    return u->x == v->x && u->y == v->y && u->z == v->z;
}

static inline void X32V3_Copy(x32v3* d, x32v3* s)
{
    d->x = s->x;
    d->y = s->y;
    d->z = s->z;
}

static inline s32 X32V3_HashCode(x32v3* u)
{
    return (u->x * 73856093) ^ (u->y * 19349663) ^ (u->z * 83492791);
}

// d must not be u or v
extern void X32V3_Cross(x32v3* d, x32v3* u, x32v3* v);
extern x32 X32V3_Dot(x32v3* u, x32v3* v);

static inline x32 X32V3_MagSquared(x32v3* u)
{
    return X32V3_Dot(u, u);
}

static inline x32 X32V3_Mag(x32v3* u)
{
    return X32_Sqrt(X32V3_Dot(u, u));
}

extern x32 X32V3_Dist(x32v3* u, x32v3* v);
extern x32 X32V3_DistSquared(x32v3* u, x32v3* v);
extern void X32V3_NormFast(x32v3* u);
extern void X32V3_RNormFast(x32v3* d, x32v3* u);
extern void X32V3_Norm(x32v3* u);
extern void X32V3_RNorm(x32v3* d, x32v3* u);

extern void X32V3_Clamp(x32v3* u, x32v3* min, x32v3* max);
extern void X32V3_RClamp(x32v3* d, x32v3* u, x32v3* min, x32v3* max);
extern void X32V3_Lerp(x32v3* u, x32v3* v, x32 amount);
extern void X32V3_RLerp(x32v3* d, x32v3* u, x32v3* v, x32 amount);
extern void X32V3_Max(x32v3* u, x32v3* v);
extern void X32V3_RMax(x32v3* d, x32v3* u, x32v3* v);
extern void X32V3_Min(x32v3* u, x32v3* v);
extern void X32V3_RMin(x32v3* d, x32v3* u, x32v3* v);

#endif

