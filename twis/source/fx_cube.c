#include "demo.h"

#include "bg02.h"
#include "dirt02.h"
#include "twister_pal.h"

#include "3d.h"
#include "int.h"
#include "fixed.h"

#define DISTANCE (-600)
#define MASTER_SIZE (100)
#define SPACING (5)
#define ITERATIONS (4)
#define CUBE_COUNT (1+ITERATIONS*6)
#define PROJBUF_LEN (CUBE_COUNT*8*3)

typedef struct
{
    u32 bb;
    s16 tx, ty, tz; // translation
    u16 rx, ry, rz; // rotation
    s32 m[9]; // rotation matrix
    s16 l[3]; // light
    u16 a;
    s16 p[PROJBUF_LEN]; // projected vertices list
    u16 mat[6*4];
    Geometry* g;

    u32 step;
    u32 fc;
    u32 bw;
} FXCube;

static inline void ShiftV(s32v3* v, u32 n)
{
    v->x >>= n, v->y >>= n, v->z >>= n;
}
static inline void Rotate(s32v3* d, s32* m, s32v3* v)
{
    d->x = m[0] * v->x + m[1] * v->y + m[2] * v->z >> 15;
    d->y = m[3] * v->x + m[4] * v->y + m[5] * v->z >> 15;
    d->z = m[6] * v->x + m[7] * v->y + m[8] * v->z >> 15;
}
static inline void RotateE(s32v3* d, s32* m, s32 vx, s32 vy, s32 vz)
{
    d->x = m[0] * vx + m[1] * vy + m[2] * vz >> 15;
    d->y = m[3] * vx + m[4] * vy + m[5] * vz >> 15;
    d->z = m[6] * vx + m[7] * vy + m[8] * vz >> 15;
}
static inline void RotateTrans(s32v3* d, s32* m, s32v3* v, s32v3* t)
{
    /*d->x = ((t->x << 15) + (m[0] * v->x + m[1] * v->y + m[2] * v->z)) >> 8;// >> 15);
    d->y = ((t->y << 15) + (m[3] * v->x + m[4] * v->y + m[5] * v->z)) >> 8;// >> 15);
    d->z = ((t->z << 15) + (m[6] * v->x + m[7] * v->y + m[8] * v->z)) >> 8;// >> 15);*/
    d->x = t->x + (m[0] * v->x + m[1] * v->y + m[2] * v->z >> 15);
    d->y = t->y + (m[3] * v->x + m[4] * v->y + m[5] * v->z >> 15);
    d->z = t->z + (m[6] * v->x + m[7] * v->y + m[8] * v->z >> 15);
}

static IWRAM_O0_CODE void MakeCube(Geometry* g, u32 index, u16* facemat, s32v3* pos, s32v3* sz, s32v3* rot)
{
    s32 o = index*8;
    s16* v = g->verts[o].a;
    u32 i = 0;
    s32 m[9];

    make_matrix(m, rot->x >> 2, rot->y >> 2, rot->z >> 2);

    v[i++] = pos->x + (m[0] * -sz->x + m[1] * sz->y + m[2] * sz->z >> 15);
    v[i++] = pos->y + (m[3] * -sz->x + m[4] * sz->y + m[5] * sz->z >> 15);
    v[i++] = pos->z + (m[6] * -sz->x + m[7] * sz->y + m[8] * sz->z >> 15);

    v[i++] = pos->x + (m[0] * sz->x + m[1] * sz->y + m[2] * sz->z >> 15);
    v[i++] = pos->y + (m[3] * sz->x + m[4] * sz->y + m[5] * sz->z >> 15);
    v[i++] = pos->z + (m[6] * sz->x + m[7] * sz->y + m[8] * sz->z >> 15);

    v[i++] = pos->x + (m[0] * sz->x + m[1] * -sz->y + m[2] * sz->z >> 15);
    v[i++] = pos->y + (m[3] * sz->x + m[4] * -sz->y + m[5] * sz->z >> 15);
    v[i++] = pos->z + (m[6] * sz->x + m[7] * -sz->y + m[8] * sz->z >> 15);

    v[i++] = pos->x + (m[0] * -sz->x + m[1] * -sz->y + m[2] * sz->z >> 15);
    v[i++] = pos->y + (m[3] * -sz->x + m[4] * -sz->y + m[5] * sz->z >> 15);
    v[i++] = pos->z + (m[6] * -sz->x + m[7] * -sz->y + m[8] * sz->z >> 15);

    v[i++] = pos->x + (m[0] * -sz->x + m[1] * sz->y + m[2] * -sz->z >> 15);
    v[i++] = pos->y + (m[3] * -sz->x + m[4] * sz->y + m[5] * -sz->z >> 15);
    v[i++] = pos->z + (m[6] * -sz->x + m[7] * sz->y + m[8] * -sz->z >> 15);

    v[i++] = pos->x + (m[0] * sz->x + m[1] * sz->y + m[2] * -sz->z >> 15);
    v[i++] = pos->y + (m[3] * sz->x + m[4] * sz->y + m[5] * -sz->z >> 15);
    v[i++] = pos->z + (m[6] * sz->x + m[7] * sz->y + m[8] * -sz->z >> 15);

    v[i++] = pos->x + (m[0] * sz->x + m[1] * -sz->y + m[2] * -sz->z >> 15);
    v[i++] = pos->y + (m[3] * sz->x + m[4] * -sz->y + m[5] * -sz->z >> 15);
    v[i++] = pos->z + (m[6] * sz->x + m[7] * -sz->y + m[8] * -sz->z >> 15);

    v[i++] = pos->x + (m[0] * -sz->x + m[1] * -sz->y + m[2] * -sz->z >> 15);
    v[i++] = pos->y + (m[3] * -sz->x + m[4] * -sz->y + m[5] * -sz->z >> 15);
    v[i++] = pos->z + (m[6] * -sz->x + m[7] * -sz->y + m[8] * -sz->z >> 15);

    i = 0;
    Quad* q = Geometry_GetQuads(g) + index*6;
    Quad_Set(q + i++, facemat[0], 0, 0, 0x7FFF, o+0, o+3, o+2, o+1); // front
    Quad_Set(q + i++, facemat[1], 0, 0, 0x8000, o+4, o+5, o+6, o+7); // back
    Quad_Set(q + i++, facemat[2], 0x8000, 0, 0, o+0, o+4, o+7, o+3); // left
    Quad_Set(q + i++, facemat[3], 0x7FFF, 0, 0, o+1, o+2, o+6, o+5); // right
    Quad_Set(q + i++, facemat[4], 0, 0x7FFF, 0, o+0, o+1, o+5, o+4); // top
    Quad_Set(q + i++, facemat[5], 0, 0x8000, 0, o+3, o+7, o+6, o+2); // bottom
}

static IWRAM_O0_CODE void GenMesh(s32 xa)
{
    FXCube* x = g_fx_data;

    u32 order[ITERATIONS*6+1];
    {
        s32 sz = MASTER_SIZE;
        s32 dist[ITERATIONS*6+1];
        s32 o = 0;
        s32v3 trans = { x->tx, x->ty, x->tz };
        s32v3 p;
        u32 pi = 0;
        s32* m = x->m;
        s32v3 pos = { 0, 0, 0 };
        RotateTrans(&p, m, &pos, &trans);
        dist[pi++] = p.x*p.x+p.y*p.y+p.z*p.z;
        s32 a = xa;
        for (u32 i = 0; i < ITERATIONS; ++i)
        {
            s32 s = X32_SinIdx2(a), c = X32_CosIdx2(a);
            a += xa;
            o += sz;
            sz = (sz >> 1) + (sz >> 3);
            o += sz + SPACING;
            s32 co = c*o >> 12, so = s*o >> 12;
            pos.x =  co; pos.y =   0; pos.z = -so; RotateTrans(&p, m, &pos, &trans); dist[pi++] = p.x*p.x+p.y*p.y+p.z*p.z;
            pos.x = -co; pos.y =   0; pos.z =  so; RotateTrans(&p, m, &pos, &trans); dist[pi++] = p.x*p.x+p.y*p.y+p.z*p.z;
            pos.x =   0; pos.y =  co; pos.z =  so; RotateTrans(&p, m, &pos, &trans); dist[pi++] = p.x*p.x+p.y*p.y+p.z*p.z;
            pos.x =   0; pos.y = -co; pos.z = -so; RotateTrans(&p, m, &pos, &trans); dist[pi++] = p.x*p.x+p.y*p.y+p.z*p.z;
            pos.x =  so; pos.y =   0; pos.z =  co; RotateTrans(&p, m, &pos, &trans); dist[pi++] = p.x*p.x+p.y*p.y+p.z*p.z;
            pos.x = -so; pos.y =   0; pos.z = -co; RotateTrans(&p, m, &pos, &trans); dist[pi++] = p.x*p.x+p.y*p.y+p.z*p.z;
        }
        for (u32 i = 0; i < sizeof(order) / sizeof(*order); ++i) order[i] = i;
        for (u32 i = 0; i < sizeof(order) / sizeof(*order); ++i)
        {
            s32 oi = order[i];
            for (u32 j = i + 1; j < sizeof(order) / sizeof(*order); ++j)
            {
                s32 oj = order[j];
                if (dist[oi] > dist[oj]) order[i] = oj, order[j] = oi, oi = oj;
            }
        }
    }
    u32 map[sizeof(order) / sizeof(*order)];
    for (u32 i = 0; i < sizeof(order) / sizeof(*order); ++i) map[order[i]] = i;

    s32v3 pos = { 0, 0, 0 };
    s32v3 sz = { MASTER_SIZE, MASTER_SIZE, MASTER_SIZE };
    s32v3 rot = { 0, 0, 0 };
    u32 cubei = 0;
    MakeCube(x->g, map[cubei++], x->mat, &pos, &sz, &rot);
    s32 o = 0;
    s32 a = xa;
    for (u32 i = 0; i < ITERATIONS; ++i)
    {
        s32 s = X32_SinIdx2(a), c = X32_CosIdx2(a);
        a += xa;
        o += sz.x;
        sz.x = sz.y = sz.z = (sz.z >> 1) + (sz.z >> 3);
        o += sz.x + SPACING;
        s32 co = c*o >> 12, so = s*o >> 12;
        rot.x = a; pos.x =  co; pos.y =   0; pos.z = -so; MakeCube(x->g, map[cubei++], x->mat +  6, &pos, &sz, &rot); rot.x = 0;
        rot.y = a; pos.x = -co; pos.y =   0; pos.z =  so; MakeCube(x->g, map[cubei++], x->mat +  6, &pos, &sz, &rot); rot.y = 0;
        rot.z = a; pos.x =   0; pos.y =  co; pos.z =  so; MakeCube(x->g, map[cubei++], x->mat + 12, &pos, &sz, &rot); rot.z = 0;
        rot.x = a; pos.x =   0; pos.y = -co; pos.z = -so; MakeCube(x->g, map[cubei++], x->mat + 12, &pos, &sz, &rot); rot.x = 0;
        rot.y = a; pos.x =  so; pos.y =   0; pos.z =  co; MakeCube(x->g, map[cubei++], x->mat + 18, &pos, &sz, &rot); rot.y = 0;
        rot.z = a; pos.x = -so; pos.y =   0; pos.z = -co; MakeCube(x->g, map[cubei++], x->mat + 18, &pos, &sz, &rot); rot.z = 0;
    }
}

static void SetNoise(void)
{
    FXCube* xx = g_fx_data;

    // noise fx
    memcpy32((u8*)CHAR_BASE_BLOCK(5) + bg02TilesLen/* + fg01TilesLen*/, dirt02Tiles, dirt02TilesLen);
    OBJATTR bgt = { ATTR0_SQUARE | ATTR0_COLOR_256 | OBJ_Y(60), ATTR1_SIZE_64 | OBJ_X(60), ATTR2_PRIORITY(3) | OBJ_CHAR(512) }; 
    s32 x, y, i = 32;
    obj_setpriority(&bgt, 0);
    obj_setshape(&bgt, ATTR0_TALL);
    obj_setsize(&bgt, ATTR1_SIZE_32);
    obj_setflipxy(&bgt, 0, 0);
    u32 ochar0 = 512 + 2 * (16 * 4);
    u32 ochar;
    for (y = 0; y < 5; ++y)
    {
        obj_sety(&bgt, y * 32);
        if (y > 2) { obj_setflipy(&bgt, 1); ochar = (5 - y) * 8*2*7; }
        else ochar = 8*2*7 * y;
        s32 xdir = 1;
        for (x = 0; x < 15; ++x, ++i, ochar += xdir*8*2)
        {
            if (x == 8) xdir = 0; if (x == 9) xdir = -1;
            obj_setflipx(&bgt, x > 8);
            obj_setx(&bgt, x * 16);
            u32 oo = ochar + xx->fc;
            oo &= 0x3F;
            oo += ochar0;
            obj_setchar(&bgt, oo);
            OAM[i] = bgt;
        }
    }

    // blend
    REG_BLDCNT = 0x0450; // blend OBJ with BG/backdrop, but not other objs
    u16 v = (xx->bw >> 8) & 0x0F;
    u16 u = 0x10 - v;
    REG_BLDALPHA = (u << 8) | v;//0x1000 | (xx->bw >> 8); // weights
    xx->bw = X32_SinIdx2(xx->fc);
}

void fx_cube_init(void)
{
    // sprite background
    {
        memcpy32(SPRITE_PALETTE, bg02Pal, bg02PalLen);
        memcpy32(CHAR_BASE_BLOCK(5), bg02Tiles, bg02TilesLen);
        OBJATTR bgt = { ATTR0_SQUARE | ATTR0_COLOR_256 | OBJ_Y(60), ATTR1_SIZE_64 | OBJ_X(60), ATTR2_PRIORITY(3) | OBJ_CHAR(512) }; 
        s32 x, y, i;
        for (y = 0, i = 0; y < 160+64; y += 64)
        {
            bgt.attr0 &= ~0xFF; bgt.attr0 |= OBJ_Y(y);
            for (x = 0; x < 240+64*4; x += 64, ++i)
            {
                bgt.attr1 &= ~0x1FF; bgt.attr1 |= OBJ_X(x - 32);
                OAM[i] = bgt;
            }
        }
    }

    FXCube* x;

    LoadOverlayAndExtendIHeap(OVERLAY_3D);

    g_fx_data = x = iwalloc(sizeof(*x));
    x->bb = VRAM_BUF2;

    x->tx = x->ty = 0;
    x->tz = DISTANCE;
    x->rx = 0, x->ry = 0x200, x->rz = 0x1000;
    x->l[0] = -18918; x->l[1] = 18918; x->l[2] = 18918;
    x->mat[0] = x->mat[1] = x->mat[2] = x->mat[3] = x->mat[4] = x->mat[5] = 1;
    x->mat[6] = x->mat[7] = x->mat[8] = x->mat[9] = x->mat[10] = x->mat[11] = 3;
    x->mat[12] = x->mat[13] = x->mat[14] = x->mat[15] = x->mat[16] = x->mat[17] = 5;
    x->mat[18] = x->mat[19] = x->mat[20] = x->mat[21] = x->mat[22] = x->mat[23] = 7;

    x->g = Geometry_Alloc(8 * CUBE_COUNT, 6 * CUBE_COUNT, POLY_QUAD);

    x->step = 0;
    x->fc = 0x100;
    x->bw = 0;

    memcpy32(BG_PALETTE, twister_pal, twister_pal_size);

    REG_BG2CNT = BG_PRIORITY(2);
    REG_DISPCNT = MODE_4 | BG2_ON | OBJ_ON | OBJ_1D_MAP;
}

void fx_cube_deinit(void)
{
    ResetIHeap();
    oam_disable(OAM, 128);
}

IWRAM_O0_CODE void fx_cube_exec(void)
{
    FXCube* x = g_fx_data;
    ++x->fc;

        SetNoise();
    if (sync & SYNC_AFTER) ++x->step;

    clear_screen((void*)x->bb);
    if (x->step > ITERATIONS + 2)
    {
        ++x->rx; x->ry -= 20; x->rz += 60;
        if (sync & SYNC_AFTERSTRONG) ((u16*)&x->rx)[x->step & 1] += 0x2000;
    }
    make_matrix(x->m, x->rx >> 2, x->ry >> 2, x->rz >> 2);
    if (x->step > ITERATIONS)
    {
        if (x->step < ITERATIONS + 8 && sync)
            x->a += 0x400;
        else
            x->a += 0x80;
    }
    s32 a = X32_SinIdx2(x->a) >> 1;
    GenMesh(a);

    u32 cube_count = x->step; if (cube_count > ITERATIONS) cube_count = ITERATIONS;
    x->g->poly_count = 6 * (6 * cube_count + 1);

    rotransjection(x->p, (void*)x->g, x->m, x->tx, x->ty, x->tz);
    draw_object((void*)x->bb, x->p, x->m, (void*)x->g, x->l);

	VBlankIntrWait();
    x->bb ^= VRAM_BUFSWITCH;
    REG_DISPCNT ^= DCNT_PAGE;
}

