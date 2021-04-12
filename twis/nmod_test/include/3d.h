
void palette_generation(const u8 *pal_data, u16 *dest);
void draw_object(u16 *screen, const s16 *two_d_buf, s32 *matrix, const s16 *obj, const s16 *light);
void make_matrix(s32 *matrix, s32 rx, s32 ry, s32 rz);
void rotransjection(s16 *dest, const s16 *obj, const s32 *matrix, s32 tx, s32 ty, s32 tz);
void rotransjectionn(s16 *dest, const s16 *obj, const s32 *matrix, s32 tx, s32 ty, s32 tz, u32 nv);
void clear_screen(u16 *screen);
