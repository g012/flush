#include "sync.h"

//#define TEMPO 418

extern const u16 sync_d[];

// dt in ms, beat type
// each time value is a delta with the previous
#if 0
const u16 sync_d[] =
{
    TEMPO*4,     3,
    TEMPO*5,     1,
    TEMPO*6,     1,
    TEMPO*7,     1,
    TEMPO*8,     3,
    TEMPO*9,     1,
    TEMPO*10,    1,
    TEMPO*11,    1,
    TEMPO*12,    3,
    TEMPO*13,    1,
    TEMPO*14,    1,
    TEMPO*15,    1,
    TEMPO*16,    3,
    TEMPO*17,    1,
    TEMPO*18,    1,
    TEMPO*19,    1,
    TEMPO*20,    3,
    TEMPO*21,    1,
    TEMPO*22,    1,
    TEMPO*23,    1,
    TEMPO*24,    3,
    TEMPO*25,    1,
    TEMPO*26,    1,
    TEMPO*27,    1,
    TEMPO*28,    3,
    TEMPO*29,    1,
    TEMPO*30,    1,
    TEMPO*31,    1,
    TEMPO*32,    3,
    TEMPO*33,    1,
    TEMPO*34,    1,
    TEMPO*35,    1,
    TEMPO*36,    3,
    TEMPO*37,    1,
    TEMPO*38,    1,
    TEMPO*39,    1,
    TEMPO*40,    3,
    TEMPO*41,    1,
    TEMPO*42,    1,
    TEMPO*43,    1,
    TEMPO*44,    3,
    TEMPO*45,    1,
    TEMPO*46,    1,
    TEMPO*47,    1,
#if 0
    1671, 3,
    2101-1671, 1,
    2496-2101, 1,
    2925-2496, 1,
    3332-2925, 3,
    3750-3332, 1,
    4167-3750, 1,
    4585-4167, 1,
    5003-4585, 3,
    5421-5003, 1,
    5839-5421, 1,
    6257-5839, 1,
    6466-6257, 4,
    6652-6466, 3,
    6873-6652, 6,
    7082-6873, 1,
    7302-7082, 4,
    7500-7302, 1,
    7720-7500, 6,
    7918-7720, 1,
    8138-7918, 4,
    8335-8138, 3,
    8544-8335, 6,
    8753-8544, 1,
    8974-8753, 4,
    9183-8974, 1,
    9369-9183, 6,
    9589-9369, 1,
    9798-9589, 4,
    10007-9798, 3,
    10193-10007, 6,
    10425-10193, 1,
    10623-10425, 4,
    10832-10623, 1,
    11041-10832, 6,
    11238-11041, 1,
    11470-11238, 4,
    11656-11470, 3,
    11865-11656, 6,
    12085-11865, 1,
    12283-12085, 4,
    12492-12283, 1,
    12701-12492, 6,
#endif
};
#endif

IWRAM_CODE void Sync_Update(void)
{
    sync = 0;
    for (;;)
    {
        u32 d = sync_d[sync_pos];
        u32 t = d + sync_t;
        if (t > ZIC_MS) break;
        sync_t += d;
        sync = sync_d[++sync_pos];
        ++sync_pos;
    }
}

