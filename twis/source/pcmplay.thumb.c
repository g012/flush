#include "demo.h"
#include "pcmplay.h"

#ifdef MUSIC_PCM

IWRAM_DATA PcmPlay g_pcmplay;

void PcmPlay_Start(void* pcml, void* pcmr, u32 sampleCount, PcmPlayFreq freq, PcmPlayHwResample re)
{
    PcmPlay* p = &g_pcmplay;
    p->stopAt = sampleCount >> 7 + freq - PCMPLAY_FREQ_8192;
    p->tick = 0;
    p->ms = 0;

    REG_SOUNDCNT_H = SNDA_RESET_FIFO | SNDA_L_ENABLE | SNDA_VOL_100 | SNDB_RESET_FIFO | SNDB_R_ENABLE | SNDB_VOL_100;
    REG_SOUNDBIAS = 0x200 /* add 0x200 to each sample from allowed range [-0x200, 0x200] -> converts to [0, 0x400] (unsigned) */ | re << 14;
    REG_SOUNDCNT_X = 0x80 /* master enable */;

    REG_DMA1CNT = 0;
    REG_DMA1SAD = (u32)pcml;
    REG_DMA1DAD = (u32)&REG_FIFO_A;
    REG_DMA1CNT = DMA_ENABLE | DMA32 | DMA_SPECIAL | DMA_REPEAT;

    REG_DMA2CNT = 0;
    REG_DMA2SAD = (u32)pcmr;
    REG_DMA2DAD = (u32)&REG_FIFO_B;
    REG_DMA2CNT = DMA_ENABLE | DMA32 | DMA_SPECIAL | DMA_REPEAT;

    REG_TM1CNT_L = 0x10000 - (0x80 << freq - PCMPLAY_FREQ_8192); // trigger every 1/64th of a second
    REG_TM1CNT_H = TIMER_START | 4 /* cascade */ | 0x40 /* trigger interrupt */;
    REG_TM0CNT_L = 0x10000 - (0x1000000 /* 16 MHz */ >> freq); // overflow at freq

    irqSet(IRQ_TIMER1, PcmPlay_Timer);

    REG_TM0CNT_H = TIMER_START;
}

void PcmPlay_Stop(void)
{
    // stop sound and cut power consumption to minimum
    irqDisable(IRQ_TIMER1);
    REG_DMA1CNT = 0;
    REG_DMA2CNT = 0;
    REG_SOUNDCNT_H = 0;
    REG_SOUNDCNT_X = 0; 
    REG_SOUNDBIAS = 0;
}

#endif

