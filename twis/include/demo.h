#ifndef DEMO_H
#define DEMO_H

#include <gba.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "mem.h"
#include "heapstack.h"
#include "heapllist.h"
#include "sync.h"

#ifdef MUSIC_PCM
#  include "pcmplay.h"
#  define ZIC_MS (g_pcmplay.ms)
#elif defined(MUSIC_NMOD)
#  include "nmod.h"
#  define ZIC_MS (NMOD_row) // FIXME compute the actual ms from NMOD data
#endif

#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wunused-variable"

#define VRAM_BUF1 (0x06000000)
#define VRAM_BUF2 (0x0600A000)
#define VRAM_BUFSWITCH (0xA000)
#define DCNT_PAGE (0x10)

// Define your overlay here
#define OVERLAY_3D 0
#define OVERLAY_M7 1
#define OVERLAY_TWISTER 2
#define OVERLAY_FIRE 3

#define IWRAM_O0_CODE	__attribute__((section(".iwram0"), long_call))
#define IWRAM_O1_CODE	__attribute__((section(".iwram1"), long_call))
#define IWRAM_O2_CODE	__attribute__((section(".iwram2"), long_call))
#define IWRAM_O3_CODE	__attribute__((section(".iwram3"), long_call))
#define IWRAM_O4_CODE	__attribute__((section(".iwram4"), long_call))
#define IWRAM_O5_CODE	__attribute__((section(".iwram5"), long_call))
#define IWRAM_O6_CODE	__attribute__((section(".iwram6"), long_call))
#define IWRAM_O7_CODE	__attribute__((section(".iwram7"), long_call))
#define IWRAM_O8_CODE	__attribute__((section(".iwram8"), long_call))
#define IWRAM_O9_CODE	__attribute__((section(".iwram9"), long_call))

extern char __eheap_start[];
extern char __iheap_start[];
extern char __sp_usr[];
extern char __iwram_overlay_start[];
extern char __load_start_iwram0[];
extern char __load_stop_iwram0[];
extern char __load_start_iwram1[];
extern char __load_stop_iwram1[];
extern char __load_start_iwram2[];
extern char __load_stop_iwram2[];
extern char __load_start_iwram3[];
extern char __load_stop_iwram3[];
extern char __load_start_iwram4[];
extern char __load_stop_iwram4[];
extern char __load_start_iwram5[];
extern char __load_stop_iwram5[];
extern char __load_start_iwram6[];
extern char __load_stop_iwram6[];
extern char __load_start_iwram7[];
extern char __load_stop_iwram7[];
extern char __load_start_iwram8[];
extern char __load_stop_iwram8[];
extern char __load_start_iwram9[];
extern char __load_stop_iwram9[];
#define LoadOverlay(i) LoadOverlay_I(i)
#define LoadOverlay_I(i) \
    do { if (i != g_overlay) { \
        memcpy32(__iwram_overlay_start, __load_start_iwram ## i, (u32)__load_stop_iwram ## i - (u32)__load_start_iwram ## i); \
        g_overlay = i; \
    }} while(0)
// (Re)Create the IWRAM frame heap to the max possible of given overlay.
// No data is copied, but it can be done by the callee if needed since
// the new heap start address will be before the default one.
// Don't forget to set it back to default size for next FX using ResetIHeap.
#define ExtendIHeap(i) ExtendIHeap_I(i)
#define ExtendIHeap_I(i) \
    do { \
        u32 osz = (u32)__iheap_start - (u32)__iwram_overlay_start; \
        u32 oisz = (u32)__load_stop_iwram ## i - (u32)__load_start_iwram ## i; \
        u32 dsz = osz - oisz; \
        g_hs = HeapStack_Create(__iheap_start - dsz, (u32)__sp_usr - (u32)__iheap_start + dsz); \
    } while(0)
// (Re)Create the IWRAM frame heap to the free size left after the
// biggest of all overlays (default at startup). You must use this
// if you plan on keeping the iheap data between overlay loads.
#define ResetIHeap() (g_hs = HeapStack_Create(__iheap_start, (u32)__sp_usr - (u32)__iheap_start))
// Helpers to combine the above
#define LoadOverlayAndExtendIHeap(i) LoadOverlay(i); ExtendIHeap(i)
#define ResetOverlayAndIHeap() LoadOverlay(0); ResetIHeap()
// Current loaded overlay.
extern u8 g_overlay;

typedef uint64_t u64;
typedef int64_t s64;

// replacement of malloc with a simple linked list heap
// to save space in IWRAM
extern HeapLList* g_h;
#define malloc(sz) HeapLList_Alloc(g_h, sz)
#define free(p) HeapLList_Free(g_h, p)
#define realloc(p, sz) HeapLList_Realloc(g_h, p, sz)
#define calloc not_available
// stack heap on the IWRAM, going opposite direction of the stack pointer
// - use this for IWRAM allocations that last more than a frame, or for
// IWRAM allocations which last for more than local scope (eg a function
// returning a struct in IWRAM, free'd later by the caller).
extern HeapStack* g_hs;
#define iwalloc(sz) HeapStack_Alloc(g_hs, sz)
#define iwfree(p) HeapStack_Free(g_hs, p)
#define iwrealloc(p, sz) HeapStack_Realloc(g_hs, p, sz)
// pointer holding the current fx data
extern void* g_fx_data;

#define breakpoint() asm volatile("mov r11,r11")
#define nop() asm volatile("nop")

// VBA console print
static inline void DebugPrint(char* s)
{
    asm volatile(
        "mov r0,%0\n"
#ifdef __thumb__
        "swi 0xff\n"
#else
        "swi 0xff0000\n"
#endif
        :: "r" (s) : "r0"
    );
}
extern void DebugPrintf(const char* format, ...) __attribute__((format(printf, 1, 2)));

#endif

