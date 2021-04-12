#include "int.h"

void Endian_Swap(u8* data, u32 dataSize)
{
	u32 i; u8 b;
	for (--dataSize, i = 0; i < dataSize; ++i, --dataSize)
		b = data[i], data[i] = data[dataSize], data[dataSize] = b;
}

/**************************************************************************
 * S32
 *************************************************************************/

s32 S32_Pow(s32 a, s32 e)
{
    s32 b = (a ^ (a >> 31)) - (a >> 31); // abs(a)
    u32 negate = b != a && (e & 1);
    a = 1;

    while (e > 0)
    {
        if (e & 1)
            a *= b;
        b *= b;		// b^(2a) = (b^2)^a
        e >>= 1;
    }

    if (negate)
        a = -a;

    return a;
}

s32 S32_Log2(s32 x)
{
	s32 y = x & (x - 1);

	y |= -y;
	y >>= sizeof(s32) * 8 - 1;
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);
    x |= (x >> 16);

	return U32_CountOnes((u32)x) - 1 - y;
}

s32 S32_LowPow(s32 x)
{
	s32 p = 0;
	while ((2 << p) <= x)
		++p;
	return p;
}

s32 S32_HighPow(s32 x)
{
	s32 p = 0;
	while ((1 << p) < x)
		++p;
	return p;
}

/**************************************************************************
 * U32
 *************************************************************************/

u32 U32_Sqrt(u32 x)
{
    u32 op, res, one;

    op = x;
    res = 0;

    // "one" starts at the highest power of four <= than the argument.
    one = (u32)1 << sizeof(u32)*8 - 2;  // second-to-top bit set
    while (one > op)
        one >>= 2;

    while (one)
    {
        if (op >= res + one)
        {
            op = op - (res + one);
            res = res +  2 * one;
        }
        res >>= 1;
        one >>= 2;
    }

    return res;
}

u32 U32_CLZ(u32 x)
{
    u32 y;
    u32 n = 32;

    // Use binary search to find the location where 0's end.
    y = x >> 16;
    if (y != 0)
    {
        n -= 16;
        x = y;
    }
    y = x >> 8;
    if (y != 0)
    {
        n -= 8;
        x = y;
    }
    y = x >> 4;
    if (y != 0)
    {
        n -= 4;
        x = y;
    }
    y = x >> 2;
    if (y != 0)
    {
        n -= 2;
        x = y;
    }
    y = x >> 1;
    if (y != 0)
    {
        n -= 2;
    } // x == 0b10 or 0b11 -> n -= 2
    else
    {
        n -= x;
    } // x == 0b00 or 0b01 -> n -= x

    return n;
}

u32 U32_CTZ(u32 x)
{
	u32 c = U32_CLZ(x & (u32)(-((s32)x)));
	return x ? 31 - c : c;
}

// On some platforms, including ARM, shift and arithmetic operations can be done simultaneously.
u32 U32_CountOnes(u32 x)
{
    // Rather than counting 32 bits directly, first store the number of 1's for every 2 bits in the same location as those 2 bits.
    // In other words, every 2 bits are converted such that 00 -> 00, 01 -> 01, 10 -> 01, and 11 -> 10.
    // When x -> x', for a 2-bit value we have x' = x - (x >> 1).
    x -= ((x >> 1) & 0x55555555);
    // When counting in 4-bit units, add the number of 1's stored in the upper and lower 2 bits, and then store this as the number of 1's in that original 4-bit location.
    x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
    // Do the same for 8-bit units.
    // However, the maximum result for each digit is 8, and this fits in 4 bits, it is not necessary to mask ahead of time.
    x += (x >> 4);
    // Mask unnecessary parts in preparation for the next operations.
    x &= 0x0F0F0F0F;
    // Get the sum of the upper 8 bits and lower 8 bits in 16-bit units.
    x += (x >> 8);
    // Do the same for 32-bit units.
    x += (x >> 16);
    // The lower 8-bit value is the result.
    return x;
}

u32 U32_RoundUpToPow2(u32 x)
{
	--x;
	x |= x >> 1;
	x |= x >> 2;
	x |= x >> 4;
	x |= x >> 8;
	x |= x >> 16;
	return ++x;
}

/**************************************************************************
 * U32V4
 *************************************************************************/

u32v4 U32V4_zero = { 0, 0, 0, 0 };
u32v4 U32V4_one = { 1, 1, 1, 1 };

u32 U32V4_IsEqual(u32v4* v1, u32v4* v2)
{
	return v1->x == v2->x
		&& v1->y == v2->y
		&& v1->z == v2->z
		&& v1->w == v2->w
		;
}

/**************************************************************************
 * U64
 *************************************************************************/

u64 U64_Sqrt(u64 x)
{
    u64 op, res, one;

    op = x;
    res = 0;

    // "one" starts at the highest power of four <= than the argument.
    one = (u64)1 << sizeof(u64) * 8 - 2;  // second-to-top bit set
    while (one > op)
        one >>= 2;

    while (one)
    {
        if (op >= res + one)
        {
            op = op - (res + one);
            res = res + 2 * one;
        }
        res >>= 1;
        one >>= 2;
    }

    return res;
}

u32 U64_CLZ(u64 x)
{
	u32 msb = (u32)(x >> 32);
	if (msb)
		return U32_CLZ(msb);
	else
	{
		u32 lsb = (u32)x;
		if (lsb) // some implementations do not allow for all 0
			return 32 + U32_CLZ(lsb);
	}
	return 64;
}

u32 U64_CTZ(u64 x)
{
	u32 lsb = (u32)x;
	if (lsb)
		return U32_CTZ(lsb);
	else
	{
		u32 msb = (u32)(x >> 32);
		if (msb) // some implementations do not allow for all 0
			return 32 + U32_CTZ(msb);
	}
	return 64;
}

u64 U64_RoundUpToPow2(u64 x)
{
	--x;
	x |= x >> 1;
	x |= x >> 2;
	x |= x >> 4;
	x |= x >> 8;
	x |= x >> 16;
	x |= x >> 32;
	return ++x;
}

/**************************************************************************
 * S128
 *************************************************************************/

void S128_RLShift(s128* r, s128* a, s32 n)
{
    r->lo = a->lo, r->hi = a->hi;
    if (n <= 0)
        return;
    if (n > 127)
    {
        r->lo = 0, r->hi = 0;
        return;
    }
    if (n > 63)
    {
        n -= 64;
        r->hi = (s64)r->lo;
        r->lo = 0;
    }
    if (n > 0)
    {
        // Get the high N bits of the low part
        // into the low part of a temporary value.
        u64 bits = r->lo >> (64 - n);
        // Shift the low part
        r->lo <<= n;
        // Shift the high part and OR-in the lower bits.
        r->hi = (r->hi << n) | (s64)bits;
    }
}

void S128_RRShift(s128* r, s128* a, s32 n)
{
    r->lo = a->lo, r->hi = a->hi;
    if (n <= 0)
        return;
    if (n > 127)
        return;
    if (n > 63)
    {
        n -= 64;
        r->lo = (u64)r->hi;
        r->hi = r->hi >= 0 ? 0 : -1;
    }
    if (n > 0)
    {
        u64 bits = (u64)(r->hi << (64 - n));
        r->hi >>= n;
        r->lo = (r->lo >> n) | bits;
    }
}

void S128_RMul(s128* r, s128* x, s128* y)
{
    u64 t;
    s128 hd, hc, hb, ha, gd, gc, gb, fd, fc, ed;

    // Get the individual values
    u32 a = (u32)(x->hi >> 32);
    u32 b = (u32)(x->hi & 0xFFFFFFFF);
    u32 c = (u32)(x->lo >> 32);
    u32 d = (u32)(x->lo & 0xFFFFFFFF);
    u64 e = (u64)(y->hi >> 32);
    u64 f = (u64)(y->hi & 0xFFFFFFFF);
    u64 g = (u64)(y->lo >> 32);
    u64 h = (u64)(y->lo & 0xFFFFFFFF);

    // Compute the partial products
    // hd
    hd.lo = h * d, hd.hi = 0;
    // hc << 32
    hc.lo = h * c, hc.hi = 0;
    S128_LShift(&hc, 32);
    // hb << 64
    hb.lo = 0, hb.hi = (s64)(h * b);
    // ha << 96
    t = h * a;
    ha.lo = 0, ha.hi = (s64)(t << 32);
    // gd << 32
    gd.lo = g * d, gd.hi = 0;
    S128_LShift(&gd, 32);
    // gc << 64
    gc.lo = 0, gc.hi = (s64)(g * c);
    // gb << 96
    t = g * b;
    gb.lo = 0, gb.hi = (s64)(t << 32);
    // fd << 64
    fd.lo = 0, fd.hi = (s64)(f * d);
    // fc << 96
    t = f * c;
    fc.lo = 0, fc.hi = (s64)(t << 32);
    // ed << 96
    t = e * d;
    ed.lo = 0, ed.hi = (s64)(t << 32);

    // Now add the partial results
    S128_RAdd(r, &ed, &fc);
    S128_Add(r, &fd);
    S128_Add(r, &gb);
    S128_Add(r, &gc);
    S128_Add(r, &gd);
    S128_Add(r, &ha);
    S128_Add(r, &hb);
    S128_Add(r, &hc);
    S128_Add(r, &hd);
}

void S128_UnsignedDivMod(s128* dividend, s128* divisor,
        s128* quotient, s128* remainder)
{
    s32 i;
    quotient->lo = dividend->lo, quotient->hi = dividend->hi;
    remainder->lo = 0, remainder->hi = 0;
    for (i = 0; i < 128; ++i)
    {
        // Left shift Remainder:Quotient by 1
        S128_LShift(remainder, 1);
        if (S128_Compare(quotient, &S128_zero) < 0)
            remainder->lo |= 1;
        S128_LShift(quotient, 1);

        if (S128_Compare(remainder, divisor) >= 0)
        {
            S128_Sub(remainder, divisor);
            S128_Inc(quotient);
        }
    }
}

void S128_DivMod(s128* dividend, s128* divisor,
        s128* quotient, s128* remainder)
{
    // Determine the sign of results and make the operands positive.
    s32 remainderSign = 1;
    s32 quotientSign = 1;
    if (S128_Compare(dividend, &S128_zero) < 0)
    {
        S128_Neg(dividend);
        remainderSign = -1;
    }
    if (S128_Compare(divisor, &S128_zero) < 0)
    {
        S128_Neg(divisor);
        quotientSign = -1;
    }
    quotientSign *= remainderSign;

    S128_UnsignedDivMod(dividend, divisor, quotient, remainder);

    // Adjust signs of results
    if (quotientSign < 0)
        S128_Neg(quotient);
    if (remainderSign < 0)
        S128_Neg(remainder);
}

