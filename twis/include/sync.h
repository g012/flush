/*
 * 00001111
 *     ||||_ beat
 *     |||____ strong beat (includes beat)
 *     ||_______ afterbeat
 *     |__________ strong afterbeat
 */

#define SYNC_BEAT 1
#define SYNC_BEATSTRONG 3
#define SYNC_AFTER 4
#define SYNC_AFTERSTRONG 8

// This frame beat info as specified up
extern u16 sync;
// internal data
extern u16 sync_pos;
extern u32 sync_t;

extern void Sync_Update(void);

