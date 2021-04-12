#include "fixed.h"

#define X32_SqrtShift ((32 + X32_SHIFT) / 2 - X32_SHIFT) // 10
#define X32_SqrtHalf (1 << X32_SqrtShift - 1)
#define X32_One_K16 0x9B7 // 1/1.6468 as 0.12

x32 X32_Pow(x32 a, s32 e)
{
    s32 b = (a ^ (a >> 31)) - (a >> 31); // abs(a)
    u32 negate = b != a && (e & 1);
    a = X32_ONE;

    while (e > 0)
    {
        if (e & 1)
        {
            a *= b;
            a += X32_HALF;
            a >>= X32_SHIFT;
        }
        b *= b;		// b^(2a) = (b^2)^a
        b += X32_HALF;
        b >>= X32_SHIFT;
        e >>= 1;
    }

    if (negate)
        a = -a;

    return a;
}

x32 X32_Sqrt(x32 a)
{
	u64 s;

    // Expand precision to 12 + 32 = 44 bits
    // sqrt operation reduces precision to 22 bits
    s = U64_Sqrt((u64)a << 32);
    // Round
    s += X32_SqrtHalf;
    // Remove the extra 10 bits: 22 - 10 = 12
    s >>= X32_SqrtShift;
    // Store it back
    a = (x32)s;

    return a;
}

x32 X32_SinIdxFrom(s32 index, const u16* sin)
{
    index &= 0xFFFF;
    if (index < 0x4000)
        return sin[index >> 4];
    if (index < 0x8000)
        return sin[0x8000 - index >> 4];
    if (index < 0xC000)
        return -(x32)sin[index - 0x8000 >> 4];
    return -(x32)sin[(-index & 0xFFFF) >> 4];
}

u16 X32_ASinIdx(x32 v)
{
    u16 index;

    if (v < 0)
    {
        // asin(-x) = -asin(x)
        return (u16)(-(s32)X32_ASinIdx(-v));
    }

    // [0, 1] -> [0, 1023]
    index = v * 1023 + X32_HALF >> X32_SHIFT;

    return X32_asin[index];
}

u16 X32_ATanIdx(x32 v)
{
    if (v >= 0)
    {
        if (v > X32_ONE)
        {
            // atan(x) = Pi/2 - atan(1/x) for x > 1
            return (u16)(0x4000 - (s32)X32_atan[X32_Div(X32_ONE, v) >> 5]);
        }
        else if (v < X32_ONE)
        {
            // restrict index to [0, 127]
            return X32_atan[v >> 5];
        }
        else
        {
            // atan(1) = Pi/4
            return 0x2000;
        }
    }
    else
    {
        if (v < -X32_ONE)
        {
            // atan(x) = -atan(-x)
            return (u16)(-0x4000 + (s32)X32_atan[X32_Div(X32_ONE, -v) >> 5]);
        }
        else if (v > -X32_ONE)
        {
            return (u16)(-(s32)X32_atan[-v >> 5]);
        }
        else
        {
            return 0xE000;
        }
    }
}

u16 X32_ATan2Idx(x32 y, x32 x)
{
    x32 a, b;
    s32 c;
    s32 sgn;

    if (y > 0)
    {
        if (x > 0)
        {
            if (x > y)
            {
                a = y;
                b = x;
                c = 0;
                sgn = 1;
            }
            else if (x < y)
            {
                a = x;
                b = y;
                c = 0x4000;
                sgn = -1;
            }
            else
            {
                return 0x2000;
            }
        }
        else if (x < 0)
        {
            x = -x;
            if (x < y)
            {
                a = x;
                b = y;
                c = 0x4000;
                sgn = 1;
            }
            else if (x > y)
            {
                a = y;
                b = x;
                c = 0x8000;
                sgn = -1;
            }
            else
            {
                return 0x6000;
            }
        }
        else
        {
            return 0x4000;
        }
    }
    else if (y < 0)
    {
        y = -y;
        if (x < 0)
        {
            x = -x;
            if (x > y)
            {
                a = y;
                b = x;
                c = -0x8000;
                sgn = 1;
            }
            else if (x < y)
            {
                a = x;
                b = y;
                c = -0x4000;
                sgn = -1;
            }
            else
            {
                return 0xA000;
            }
        }
        else if (x > 0)
        {
            if (x < y)
            {
                a = x;
                b = y;
                c = -0x4000;
                sgn = 1;
            }
            else if (x > y)
            {
                a = y;
                b = x;
                c = 0;
                sgn = -1;
            }
            else
            {
                return 0xE000;
            }
        }
        else
        {
            return 0xC000;
        }
    }
    else
    {
        if (x >= 0)
        {
            return 0;
        }
        else
        {
            return 0x8000;
        }
    }

    if (b == 0)
        return 0;

    // [0, 1] to [0, 128] (since a >= b)
    // if a == b, result is 1 and we need the 128th value
    return (u16)(c + sgn * (s32)X32_atan[X32_Div(a, b) >> 5]);
}

void X32_SinCosFromATan(x32 a, x32* ds, x32* dc)
{
    s32 x, r, z, w, newz, s;
    s32 quadrant, i, shift;

    *ds = 0;
    *dc = X32_ONE;

    if (a == 0)
        return;

    // modulo 2Pi
    x = a % X32_2Pi;

    r = 1;
    if (x < 0)
    {
        x = -x;
        r = -r;
    }

    if (x < X32_Pi_2)
        quadrant = 0;
    else if (x < X32_Pi)
    {
        quadrant = 1;
        x = X32_Pi - x;
    }
    else if (x < X32_3Pi_2)
    {
        quadrant = 2;
        x -= X32_Pi;
    }
    else
    {
        quadrant = 3;
        x = X32_2Pi - x;
    }

    z = X32_One_K16;
    w = 0;
    // Compute sin and cos with domain 0 < x < Pi/2
    // Repeat this loop for the number of bits of precision required.
    // w will converge the sine of the angle while z will converge to
    // the cosine of the angle as x approaches 0.
    for (i = 0; i < X32_DECBITS + 1; ++i)
    {
        // As the loop iterates, decrease the Q factor used in algorithm
        shift = X32_DECBITS - i;
        // If x goes negative, reverse the sign
        s = x < 0 ? -1 : 1;
        // Converge on cosine value using previous sine and cosine values
        newz = z - ((s * (1 << shift) * w) >> X32_SHIFT);
        // Converge on sine value using previous sine and cosine values
        w = w + ((s * (1 << shift) * z) >> X32_SHIFT);
        // Store new cosine value
        z = newz;
        // Converge x to 0 using sign bit and arctan table
        x = x - (s * (X32_atan16[i] + 8 >> 4)); // 0.16 to 0.12
    }

    // Clamp Sin and Cos to between -1 and 1
    // (precision issues can cause small overruns)
    if (w > X32_ONE)
        w = X32_ONE;
    else if (w < -X32_ONE)
        w = -X32_ONE;
    if (z > X32_ONE)
        z = X32_ONE;
    else if (z < -X32_ONE)
        z = -X32_ONE;

    // Now that we have sine and cosine for one quadrant, map back to
    // the proper quadrant. r is used to compensate for negative input
    // values.  Cosine computes the same values for negative and positive angles
    // so it does not need the r value adjustment.
    switch (quadrant)
    {
        case 0:
            *ds = r * w;
            *dc = z;
            break;
        case 1:
            *ds = r * w;
            *dc = -z;
            break;
        case 2:
            *ds = r * -w;
            *dc = -z;
            break;
        case 3:
            *ds = r * -w;
            *dc = z;
            break;
    }
}

x32 X32_TanFromATan(x32 a)
{
    s32 x, z, w, newz, s, quadrant;
    s32 i, shift;

    x = (s32)a;
    if (x < 0)
    {
        x = -x;
        quadrant = -1;
    }
    else
        quadrant = 1;

    // Modulo Pi
    x = x % X32_Pi;

    if (x > X32_Pi_2)
    {
        quadrant = -quadrant;
        x = X32_Pi_2 - (x - X32_Pi_2);
    }

    z = X32_One_K16;
    w = 0;
    // Compute sin and cos with domain 0 < x < Pi/2
    for (i = 0; i < (X32_DECBITS + 1); ++i)
    {
        shift = X32_DECBITS - i;
        s = x < 0 ? -1 : 1;
        newz = z - ((s * (1 << shift) * w) >> X32_SHIFT);
        w = w + ((s * (1 << shift) * z) >> X32_SHIFT);
        z = newz;
        x = x - (s * (X32_atan16[i] + 8 >> 4)); // 0.16 to 0.12
    }

    // Compute Tangent by dividing sin by cos (w by z) and adjusting the
    // sign based on quadrant
    a = quadrant * (w << X32_SHIFT) / z;
    return a;
}



x64 X64_Mul(x64 a, x64 b)
{
    u64 a0 = (u64)a & 0xFFFFFFFF;
    u64 a1 = (u64)(a >> 32) & 0xFFFFFFFF;
    u64 b0 = (u64)b & 0xFFFFFFFF;
    u64 b1 = (u64)(b >> 32) & 0xFFFFFFFF;

    s128 r = { 0, a1 * b1 };
    s128 t = { a1 * b0, 0 };
    s128 p = { a0 * b1, 0 };
    S128_Add(&t, &p);
    S128_LShift(&t, 32);
    S128_Add(&r, &t);
    p.lo = a0 * b0;
    S128_Add(&r, &p);
    p.lo = 1 << X64_SHIFT * 2 - 1;
    S128_Add(&r, &p);
    S128_RShift(&r, X64_SHIFT);

    return r.lo;
}

x64 X64_Mul32(x64 a, x32 b)
{
    u64 a0 = (u64)a & 0xFFFFFFFF;
    u64 a1 = (u64)(a >> 32) & 0xFFFFFFFF;
    u64 b0 = (u64)b & 0xFFFFFFFF;

    s128 r = { a1 * b0, 0 };
    s128 t = { a0 * b0, 0 };
    S128_LShift(&r, 32 + X32_SHIFT);
    S128_Add(&r, &t);
    t.lo = 1 << X32_SHIFT - 1;
    S128_Add(&r, &t);
    S128_RShift(&r, X32_SHIFT);

    return r.lo;
}

x64 X64_Div(x64 a, x64 b)
{
    s128 n = { a, 0 };
    s128 t = { b, 0 };
    S128_LShift(&n, X64_SHIFT + 1);
    S128_Div(&n, &t);
    S128_Inc(&n);
    S128_RShift(&n, 1);
    return n.lo;
}

x64 X64_Rem(x64 a, x64 b)
{
    s128 n = { a, 0 };
    s128 t = { b, 0 };
    S128_LShift(&n, X64_SHIFT);
    S128_Mod(&n, &t);
    return n.lo;
}



#define X64C_4_Pi	0x0145F306DD          // 4 / PI
#define X64C_SIN1	0x3373259426          // PI / 4
#define X64C_SIN2	0x0346799334          // ((PI / 4) ^ 3) / 6
#define X64C_SIN3	0x0132467588          // ((PI / 4) ^ 2) / 20
#define X64C_SIN4	0x0063079804          // ((PI / 4) ^ 2) / 42
#define X64C_SIN5	0x0036796552          // ((PI / 4) ^ 2) / 72
#define X64C_COS1	0x1324675879          // ((PI / 4) ^ 2) / 2
#define X64C_COS2	0x0220779313          // ((PI / 4) ^ 2) / 12
#define X64C_COS3	0x0088311725          // ((PI / 4) ^ 2) / 30
#define X64C_COS4	0x0047309853          // ((PI / 4) ^ 2) / 56

x64c X64C_Mul(x64c a, x64c b)
{
    u64 a0 = (u64)a & 0xFFFFFFFF;
    u64 a1 = (u64)(a >> 32) & 0xFFFFFFFF;
    u64 b0 = (u64)b & 0xFFFFFFFF;
    u64 b1 = (u64)(b >> 32) & 0xFFFFFFFF;

    s128 r = { 0, a1 * b1 };
    s128 t = { a1 * b0, 0 };
    s128 p = { a0 * b1, 0 };
    S128_Add(&t, &p);
    S128_LShift(&t, 32);
    S128_Add(&r, &t);
    p.lo = a0 * b0;
    S128_Add(&r, &p);
    p.lo = 1LL << X64C_SHIFT * 2 - 1;
    S128_Add(&r, &p);
    S128_RShift(&r, X64C_SHIFT);

    return r.lo;
}

x64c X64C_Mul32(x64c a, x32 b)
{
    u64 a0 = (u64)a & 0xFFFFFFFF;
    u64 a1 = (u64)(a >> 32) & 0xFFFFFFFF;
    u64 b0 = (u64)b & 0xFFFFFFFF;

    s128 r = { a1 * b0, 0 };
    s128 t = { a0 * b0, 0 };
    S128_LShift(&r, 32 + X32_SHIFT);
    S128_Add(&r, &t);
    t.lo = 1 << X32_SHIFT - 1;
    S128_Add(&r, &t);
    S128_RShift(&r, X32_SHIFT);

    return r.lo;
}

x64c X64C_Div(x64c a, x64c b)
{
    s128 n = { a, 0 };
    s128 t = { b, 0 };
    S128_LShift(&n, X64C_SHIFT + 1);
    S128_Div(&n, &t);
    S128_Inc(&n);
    S128_RShift(&n, 1);
    return n.lo;
}

x64c X64C_Rem(x64c a, x64c b)
{
    s128 n = { a, 0 };
    s128 t = { b, 0 };
    S128_LShift(&n, X64C_SHIFT);
    S128_Mod(&n, &t);
    return n.lo;
}

/*
 * Taylor serie expansion of sine.
 * worst case: ~0.000000025 (sin(1.25pi), cos(1.75pi))
 * average   : 0.000000001
 *
 * |(sin(dx) - SinFx64c(x) / 4294967296.0) / sin(dx)|
 *     < 0.00004 in the worst case(around cos(pi/2))
 *
 *   y: Angle rad in radians
 *   Return: rad - (rad^3)/3! + (rad^5)/5! - (rad^7)/7! + (rad^9)/9!
 */
static u64 X64C_SinTaylorSub(u64 y)
{
    u64 yy;
    u64 tmp;

    if (y == X64C_ONE)
        return X64C_Sqrt_1_2;

    yy = y * y >> X64C_SHIFT;
    tmp = X64C_ONE - (X64C_SIN5 * yy >> X64C_SHIFT);
    tmp = X64C_ONE - ((X64C_SIN4 * yy >> X64C_SHIFT) * tmp >> X64C_SHIFT);
    tmp = X64C_ONE - ((X64C_SIN3 * yy >> X64C_SHIFT) * tmp >> X64C_SHIFT);
    tmp = X64C_SIN1 - ((X64C_SIN2 * yy >> X64C_SHIFT) * tmp >> X64C_SHIFT);

    return tmp * y >> X64C_SHIFT;
}

 /*
  * Taylor serie expansion of cosine.
  *   y: Angle rad in radians
  *   Return: 1 - (rad^2)/2! + (rad^4)/4! - (rad^6)/6! + (rad^8)/8!
  */
static u64 X64C_CosTaylorSub(u64 y)
{
    u64 yy;
    u64 tmp;

    if (y == X64C_ONE)
        return X64C_Sqrt_1_2;

    yy = y * y >> X64C_SHIFT;
    tmp = X64C_ONE - (X64C_COS4 * yy >> X64C_SHIFT);
    tmp = X64C_ONE - ((X64C_COS3 * yy >> X64C_SHIFT) * tmp >> X64C_SHIFT);
    tmp = X64C_ONE - ((X64C_COS2 * yy >> X64C_SHIFT) * tmp >> X64C_SHIFT);
    tmp = X64C_ONE - ((X64C_COS1 * yy >> X64C_SHIFT) * tmp >> X64C_SHIFT);

    return tmp;
}

x64c X64C_SinTaylor(x32 angle)
{
    x64c y, r;
    u32 n;

    if (angle < 0)
        return -X64C_SinTaylor(-angle);

    y = X64C_4_Pi * angle >> 12;
    n = (u32)(y >> X64C_SHIFT);
    y &= 0xFFFFFFFF;

    if (n & 1)
        y = X64C_ONE - y;

    if ((n + 1) & 2)
        r = X64C_CosTaylorSub((u64)y);
    else
        r = X64C_SinTaylorSub((u64)y);

    if ((n & 7) > 3)
        r = -r;

    return r;
}

x64c X64C_CosTaylor(x32 angle)
{
    x64c y, r;
    u32 n;

    if (angle < 0)
        return X64C_CosTaylor(-angle);

    y = X64C_4_Pi * angle >> 12;
    n = (u32)(y >> X64C_SHIFT);
    y &= 0xFFFFFFFF;

    if (n & 1)
        y = X64C_ONE - y;

    if ((n + 1) & 2)
        r = X64C_SinTaylorSub((u64)y);
    else
        r = X64C_CosTaylorSub((u64)y);

    if (((n + 2) & 7) > 3)
        r = -r;

    return r;
}

/**************************************************************************
 * X32V3
 *************************************************************************/

x32v3 X32V3_zero = { 0, 0, 0 };
x32v3 X32V3_one = { X32_ONE, X32_ONE, X32_ONE };
x32v3 X32V3_unitX = { X32_ONE, 0, 0 };
x32v3 X32V3_unitY = { 0, X32_ONE, 0 };
x32v3 X32V3_unitZ = { 0, 0, X32_ONE };

void X32V3_CMul(x32v3* u, x32 scale)
{
    u->x = X32_Mul(u->x, scale);
    u->y = X32_Mul(u->y, scale);
    u->z = X32_Mul(u->z, scale);
}

void X32V3_RCMul(x32v3* d, x32v3* u, x32 scale)
{
    d->x = X32_Mul(u->x, scale);
    d->y = X32_Mul(u->y, scale);
    d->z = X32_Mul(u->z, scale);
}

void X32V3_Mul(x32v3* u, x32v3* v)
{
    u->x = X32_Mul(u->x, v->x);
    u->y = X32_Mul(u->y, v->y);
    u->z = X32_Mul(u->z, v->z);
}

void X32V3_RMul(x32v3* d, x32v3* u, x32v3* v)
{
    d->x = X32_Mul(u->x, v->x);
    d->y = X32_Mul(u->y, v->y);
    d->z = X32_Mul(u->z, v->z);
}

void X32V3_CDiv(x32v3* u, x32 scale)
{
    u->x = X32_Div(u->x, scale);
    u->y = X32_Div(u->y, scale);
    u->z = X32_Div(u->z, scale);
}

void X32V3_RCDiv(x32v3* d, x32v3* u, x32 scale)
{
    d->x = X32_Div(u->x, scale);
    d->y = X32_Div(u->y, scale);
    d->z = X32_Div(u->z, scale);
}

void X32V3_Div(x32v3* u, x32v3* v)
{
    u->x = X32_Div(u->x, v->x);
    u->y = X32_Div(u->y, v->y);
    u->z = X32_Div(u->z, v->z);
}

void X32V3_RDiv(x32v3* d, x32v3* u, x32v3* v)
{
    d->x = X32_Div(u->x, v->x);
    d->y = X32_Div(u->y, v->y);
    d->z = X32_Div(u->z, v->z);
}

void X32V3_Cross(x32v3* d, x32v3* u, x32v3* v)
{
    d->x = u->y * v->z - v->y * u->z;
    d->y = u->z * v->x - v->z * u->x;
    d->z = u->x * v->y - v->x * u->y;
}

x32 X32V3_Dot(x32v3* u, x32v3* v)
{
    return
        X32_Mul(u->x, v->x) +
        X32_Mul(u->y, v->y) +
        X32_Mul(u->z, v->z)
    ;
}

x32 X32V3_Dist(x32v3* u, x32v3* v)
{
    x32v3 t;
    X32V3_RSub(&t, u, v);
    return X32V3_Mag(&t);
}

x32 X32V3_DistSquared(x32v3* u, x32v3* v)
{
    x32v3 t;
    X32V3_RSub(&t, u, v);
    return X32V3_MagSquared(&t);
}

void X32V3_NormFast(x32v3* u)
{
    x32 il = X32_Div(X32_ONE, X32V3_Mag(u));
    u->x = X32_Mul(u->x, il);
    u->y = X32_Mul(u->y, il);
    u->z = X32_Mul(u->z, il);
}

void X32V3_RNormFast(x32v3* d, x32v3* u)
{
    x32 il = X32_Div(X32_ONE, X32V3_Mag(u));
    d->x = X32_Mul(u->x, il);
    d->y = X32_Mul(u->y, il);
    d->z = X32_Mul(u->z, il);
}

void X32V3_Norm(x32v3* u)
{
    x32 l = X32V3_Mag(u);
    u->x = X32_Div(u->x, l);
    u->y = X32_Div(u->y, l);
    u->z = X32_Div(u->z, l);
}

void X32V3_RNorm(x32v3* d, x32v3* u)
{
    x32 l = X32V3_Mag(u);
    d->x = X32_Div(u->x, l);
    d->y = X32_Div(u->y, l);
    d->z = X32_Div(u->z, l);
}

void X32V3_Clamp(x32v3* u, x32v3* min, x32v3* max)
{
    u->x = X32_Clamp(u->x, min->x, max->x);
    u->y = X32_Clamp(u->y, min->y, max->y);
    u->z = X32_Clamp(u->z, min->z, max->z);
}

void X32V3_RClamp(x32v3* d, x32v3* u, x32v3* min, x32v3* max)
{
    d->x = X32_Clamp(u->x, min->x, max->x);
    d->y = X32_Clamp(u->y, min->y, max->y);
    d->z = X32_Clamp(u->z, min->z, max->z);
}

void X32V3_Lerp(x32v3* u, x32v3* v, x32 amount)
{
    u->x = X32_Lerp(u->x, v->x, amount);
    u->y = X32_Lerp(u->y, v->y, amount);
    u->z = X32_Lerp(u->z, v->z, amount);
}

void X32V3_RLerp(x32v3* d, x32v3* u, x32v3* v, x32 amount)
{
    d->x = X32_Lerp(u->x, v->x, amount);
    d->y = X32_Lerp(u->y, v->y, amount);
    d->z = X32_Lerp(u->z, v->z, amount);
}

void X32V3_Max(x32v3* u, x32v3* v)
{
    u->x = X32_Max(u->x, v->x);
    u->y = X32_Max(u->y, v->y);
    u->z = X32_Max(u->z, v->z);
}

void X32V3_RMax(x32v3* d, x32v3* u, x32v3* v)
{
    d->x = X32_Max(u->x, v->x);
    d->y = X32_Max(u->y, v->y);
    d->z = X32_Max(u->z, v->z);
}

void X32V3_Min(x32v3* u, x32v3* v)
{
    u->x = X32_Min(u->x, v->x);
    u->y = X32_Min(u->y, v->y);
    u->z = X32_Min(u->z, v->z);
}

void X32V3_RMin(x32v3* d, x32v3* u, x32v3* v)
{
    d->x = X32_Min(u->x, v->x);
    d->y = X32_Min(u->y, v->y);
    d->z = X32_Min(u->z, v->z);
}
