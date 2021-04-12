#ifndef PCMPLAY_H
#define PCMPLAY_H

typedef enum
{
    // if mixing DMG and PCM, use highest bitrate (they are summed up together so high range is required)
    PCMPLAY_RESAMPLE_9B_32KHZ  = 0,
    // use this with PCM playback only, to keep 8b precision but higher resampling frequency
    PCMPLAY_RESAMPLE_8B_64KHZ  = 1,
    PCMPLAY_RESAMPLE_7B_128KHZ = 2,
    // use this with DMG playback only, as higher sample precision is unused
    PCMPLAY_RESAMPLE_6B_256KHZ = 3
} PcmPlayHwResample;

typedef enum
{
    PCMPLAY_FREQ_8192  = 13, // CTZ(8192)
    PCMPLAY_FREQ_16384 = 14, // CTZ(16384)
} PcmPlayFreq;

typedef struct
{
    u32 stopAt; // timer 1 interrupt count at which to stop song 
    u32 tick; // number of 1/64s since song start
    u32 ms; // current position in milliseconds
} PcmPlay;
extern PcmPlay g_pcmplay;

// PCM data must be signed 8 bits non-interleaved stereo.
void PcmPlay_Start(void* pcml, void* pcmr, u32 sampleCount, PcmPlayFreq freq, PcmPlayHwResample re);
void PcmPlay_Stop(void);
void PcmPlay_Timer(void);

#endif

