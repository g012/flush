#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gba.h>
#include "demo.h"
#include "effect-manager.h"

// gamepak rom/sram access timings
#define REG_WAITCNT (*((vu32*)0x4000204))
// undocumented register for EWRAM wait cycle count control
#define REG_INTERNALMEMORYCONTROL (*((vu32*)0x4000800))

HeapLList* g_h;
HeapStack* g_hs;
void* g_fx_data = 0;
u8 g_overlay = 0;

void DebugPrintf(const char* format, ...)
{
    va_list vlist;
    char s[4096];
    va_start(vlist, format);
    vsnprintf(s, sizeof(s), format, vlist);
    va_end(vlist);
    s[sizeof(s) - 1] = 0;
    DebugPrint(s);
}

int main(void)
{
    // Keep these here in case we need it last minute
    // - ROM -
    // overclock rom 0100-0110-1101-1011 : SRAM 8 - WS0 2,1 - WS1 2,1 - WS2 2,1 - PHI off - Prefetch on
    // default is WS0 4,2, 
    //   fast commercial games put WS0 3,1 (they need to be patched to run on Supercard)
    // Supercard can only do 4,2, better cards at least 3,1
    //REG_WAITCNT = 0x46CB; // fast commercial games: 0x4317
    // - EWRAM -
    // overclock ewram (GBA and GBA SP only - crashes GBA Micro, not available on DS)
    //REG_INTERNALMEMORYCONTROL = (REG_INTERNALMEMORYCONTROL & 0x00FFFFFF) | (0x0E000000);
    
    g_h = HeapLList_Create(__eheap_start, 0x02040000 - (u32)__eheap_start, 0);
    ResetIHeap();
    
    demo_init();
    for (;;) demo_play();
}
