#ifndef HEAPLLIST_H
#define HEAPLLIST_H

#include <gba.h>

/*
 * An inplace basic linked list heap.
 */

typedef struct
{
	u32 next;
	u32 blockCount;
} HeapLListHeader;
#define HEAPLLIST_BLOCKSIZE sizeof(HeapLListHeader)

typedef struct
{
	u32 capacity;
	u32 freepos;
	u32 minAllocBlockCount;
	u32 free;
	HeapLListHeader base;
} HeapLList;

// Create a new linked list heap in place using memory at mem, of size memSize.
extern HeapLList* HeapLList_Create(void* mem, u32 memSize, u32 minAllocSize);
// Reset the heap to all free - initial state.
extern void HeapLList_Reset(HeapLList* h);

extern u32 HeapLList_GetSize(HeapLList* h, void* ptr);

extern void* HeapLList_Alloc(HeapLList* h, u32 size);
extern void HeapLList_Free(HeapLList* h, void* ptr);
extern void* HeapLList_ReAlloc(HeapLList* h, void* ptr, u32 newSize);

#endif

