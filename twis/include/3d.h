#ifndef THREED_H
#define THREED_H

typedef enum
{
    POLY_TRI    = 3,
    POLY_QUAD   = 4
} PolyType;
#pragma pack(push,1)
typedef struct
{
    union { s16 x, y, z; s16 a[3]; };
} Vertex;
typedef struct
{
    u16 mat;
    s16 nx, ny, nz; // 0.16
    u16 index_count;
    s16 indices[3]; // offset in bytes from start of verts (vertex index * 6)
} Tri;
typedef struct
{
    u16 mat;
    s16 nx, ny, nz; // 0.16
    u16 index_count;
    s16 indices[4]; // offset in bytes from start of verts (vertex index * 6)
} Quad;
typedef struct
{
    u16 vertex_count;
    u16 poly_count;
    Vertex verts[1]; // overallocated
} Geometry;
#pragma pack(pop)

// Allocated a geometry in iwram
static inline Geometry* Geometry_Alloc(u32 vertex_count, u32 polygon_count, PolyType polyt)
{
    Geometry* g = iwalloc(offsetof(Geometry, verts[vertex_count]) + offsetof(Tri, indices[polyt]) * polygon_count);
    g->vertex_count = (u16)vertex_count;
    g->poly_count = (u16)polygon_count;
    return g;
}
// Get pointer to polys array
static inline Tri* Geometry_GetTris(Geometry* g)
{ return (Tri*)((u8*)g + offsetof(Geometry, verts[g->vertex_count])); }
static inline Quad* Geometry_GetQuads(Geometry* g)
{ return (Quad*)((u8*)g + offsetof(Geometry, verts[g->vertex_count])); }
static inline void Tri_Set(Tri* q, u16 mat, s16 nx, s16 ny, s16 nz, s16 i0, s16 i1, s16 i2)
{ q->mat = mat; q->nx = nx; q->ny = ny; q->nz = nz; q->index_count = 3;
  q->indices[0] = i0*6; q->indices[1] = i1*6; q->indices[2] = i2*6; }
static inline void Quad_Set(Quad* q, u16 mat, s16 nx, s16 ny, s16 nz, s16 i0, s16 i1, s16 i2, s16 i3)
{ q->mat = mat; q->nx = nx; q->ny = ny; q->nz = nz; q->index_count = 4;
  q->indices[0] = i0*6; q->indices[1] = i1*6; q->indices[2] = i2*6; q->indices[3] = i3*6; }

void palette_generation(const u8 *pal_data, u16 *dest);
void draw_object(u16 *screen, const s16 *two_d_buf, s32 *matrix, const s16 *obj, const s16 *light);
void make_matrix(s32 *matrix, s32 rx, s32 ry, s32 rz);
void rotransjection(s16 *dest, const s16 *obj, const s32 *matrix, s32 tx, s32 ty, s32 tz);
void rotransjectionn(s16 *dest, const s16 *obj, const s32 *matrix, s32 tx, s32 ty, s32 tz, u32 nv);
void clear_screen(u16 *screen);

#endif

