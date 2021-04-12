#include "demo.h"

#include "fixed.h"
#include "3d.h"

extern Geometry evillogo;
extern u8 evillogo_palette_data[];

typedef struct
{
    u32 bb;
    s32 time;
    s16 tx, ty, tz; // translation
    u16 rx, ry, rz; // rotation
    s32 m[9]; // rotation matrix
    s32 m2[9]; // rotation matrix
    s16 l[3]; // light
    u16 a;
    void* test;
    s16 *p;         // projected vertices list
    Geometry *g;    // Geometry
} FXEvil;


void fx_evillogo_init(void)
{
    FXEvil* x;
    static const u8 palette_data[] = {
        0,   0,   0,   24,
        255, 192, 0,   7,
        255, 255, 255, 1,
        0,   0,   255, 224,
        0,   0,   255, 0
    };

    LoadOverlayAndExtendIHeap(OVERLAY_3D);

    g_fx_data = x = iwalloc(sizeof(*x));
    x->bb = VRAM_BUF2;
    x->time = 0;

    x->tx = 0;
    x->ty = -50;
    x->tz = -800;
    x->rx = 0, x->ry = 0, x->rz = 0;
    x->l[0] = -18918; x->l[1] = 18918; x->l[2] = 18918;

    x->p = iwalloc(evillogo.vertex_count*3*2);
    x->g = iwalloc(((u8*)&evillogo_palette_data)-((u8*)&evillogo));
    memcpy(x->g, &evillogo, ((u8*)evillogo_palette_data)-((u8*)&evillogo));

    palette_generation(palette_data, BG_PALETTE);
    REG_DISPCNT = MODE_4 | BG2_ON;
}

void fx_evillogo_deinit(void)
{
    ResetIHeap();
}

IWRAM_O0_CODE void fx_evillogo_exec(void)
{
    FXEvil* x = g_fx_data;
    // static const u16 poly1 = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 };

    const u16 *spoly = ((const u16*)&evillogo) + 2 + evillogo.vertex_count*3;
    u16 *dpoly = ((u16*)x->g) + 2 + x->g->vertex_count*3;

    s32 time = x->time++;
    s32 l = 0x8000-(cos_table[time*64&0x1fff]/2+0x4000);
    x->ry = l/2 & 0x3fff;
    s32 r2 = (0x8000-(cos_table[(time*64)+0x1d00&0x1fff]/2+0x4000))/2 & 0x3fff;

    if (x->ry >= 0x2000) {
        memcpy(dpoly, spoly+8*9+2*8, 5*9*sizeof(u16));
        memcpy(dpoly+8*9+2*8, spoly, 5*9*sizeof(u16));
    } else {
        memcpy(dpoly, spoly, 5*9*sizeof(u16));
        memcpy(dpoly+8*9+2*8, spoly+8*9+2*8, 5*9*sizeof(u16));
    }

    clear_screen((void*)x->bb);
    make_matrix(x->m, x->rx, x->ry, x->rz);
    make_matrix(x->m2, 0, r2, 0);

    rotransjectionn(x->p, (s16*)x->g->verts, x->m, x->tx, x->ty, x->tz, 8);
    rotransjectionn(x->p + 24, (s16*)x->g->verts + 24, x->m2, x->tx, x->ty, x->tz, 6);
    rotransjectionn(x->p + 42, (s16*)x->g->verts + 42, x->m, x->tx, x->ty, x->tz, 8);



    // rotransjection(x->p, (const s16*)x->g, x->m, x->tx, x->ty, x->tz);
    draw_object((void*)x->bb, x->p, x->m, (const s16*)x->g, x->l);

	VBlankIntrWait();
    x->bb ^= VRAM_BUFSWITCH;
    REG_DISPCNT ^= DCNT_PAGE;
}

