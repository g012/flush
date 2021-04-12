#ifndef HEAPSTACK_H
#define HEAPSTACK_H

#include <gba.h>

/*
 * A stack frame heap: allocates and frees only at the end.
 */

typedef struct
{
	u32 capacity;
	u32 offset;
} HeapStack;

// Create a new stack heap in place using memory at mem, of size memSize.
static inline HeapStack* HeapStack_Create(void* mem, u32 memSize)
{
    HeapStack* h;
    void* start = (void*)(((u32)mem + 3) & ~3);
    memSize -= (u32)start - (u32)mem;
    h = start;
	h->capacity = memSize - sizeof(*h);
	h->offset = sizeof(*h);
    return h;
}
// Reset the heap to all free - initial state.
static inline void HeapStack_Reset(HeapStack* h)
{ h->offset = sizeof(*h); }

static inline void* HeapStack_Alloc(HeapStack* h, u32 size)
{
	void* ptr;
	if (size <= 0 || h->offset + size > h->capacity)
		return 0;
	ptr = (u8*)h + h->offset;
	h->offset += size;
	return ptr;
}
// frees everything allocated from ptr and onward
static inline void HeapStack_Free(HeapStack* h, void* ptr)
{ h->offset = (u8*)ptr - (u8*)h; }
// valid only if ptr was the last allocation
static inline void* HeapStack_ReAlloc(HeapStack* h, void* ptr, u32 newSize)
{
	if ((u8*)ptr - (u8*)h + newSize > h->capacity)
		return 0;
	h->offset = (u8*)ptr - (u8*)h + newSize;
	return ptr;
}    

static inline u32 HeapStack_Tell(HeapStack* h)
{ return h->offset; }
static inline void HeapStack_Set(HeapStack* h, u32 pos)
{ h->offset = pos; }    
static inline void* HeapStack_PosToPointer(HeapStack* h, u32 pos)
{ return (u8*)h + pos; }
static inline u32 HeapStack_PointerToPos(HeapStack* h, void* ptr)
{ return (u8*)ptr - (u8*)h; }

#endif

