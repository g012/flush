#include "demo.h"
#include "pcmplay.h"

#ifdef MUSIC_PCM

IWRAM_CODE void PcmPlay_Timer(void)
{
    PcmPlay* p = &g_pcmplay;
    ++p->tick; // 1 tick == 1/64s
    p->ms = 1000 * p->tick >> 6;
    if (p->tick >= p->stopAt) PcmPlay_Stop();
}

#endif

