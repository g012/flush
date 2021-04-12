#include <stddef.h>
#include "heapllist.h"

#define HEAPLLIST_START offsetof(HeapLList, base)
#define HeapLList_OffsetToPointer(o) ((HeapLListHeader*)((u8*)heap + HEAPLLIST_START + o * HEAPLLIST_BLOCKSIZE))
#define HeapLList_PointerToOffset(p) ((u32)(((u8*)p - ((u8*)heap + HEAPLLIST_START))) / HEAPLLIST_BLOCKSIZE)

HeapLList* HeapLList_Create(void* mem, u32 memSize, u32 minAllocSize)
{
	HeapLList* h;
    void* start = (void*)(((u32)mem + 3) & ~3);
    memSize -= (u32)start - (u32)mem;
    
    if (minAllocSize <= 0)
        minAllocSize = 16 * sizeof(HeapLListHeader);

    h = start;
	h->minAllocBlockCount = (minAllocSize + HEAPLLIST_BLOCKSIZE - 1) / HEAPLLIST_BLOCKSIZE;
	h->capacity = memSize - sizeof(HeapLList);
	HeapLList_Reset(h);

    return h;
}

void HeapLList_Reset(HeapLList* h)
{
	h->freepos = sizeof(*h) - HEAPLLIST_START;
	h->base.next = h->free = 0;
	h->base.blockCount = 0;
}

u32 HeapLList_GetSize(HeapLList* heapi, void* ptr)
{
	HeapLListHeader* hh = (HeapLListHeader*)ptr - 1;
	return (u32)hh->blockCount * HEAPLLIST_BLOCKSIZE;
}

void* HeapLList_Alloc(HeapLList* heap, u32 size)
{
	HeapLListHeader *prev, *p;
	u32 prevo, po;
	u32 blockCount = (u32)((size + HEAPLLIST_BLOCKSIZE - 1) / HEAPLLIST_BLOCKSIZE + 1);

	prevo = heap->free;
	prev = HeapLList_OffsetToPointer(prevo);
	for (po = prev->next; ; prevo = po, po = p->next)
	{
		p = HeapLList_OffsetToPointer(po);
		if (p->blockCount >= blockCount)
		{
			prev = HeapLList_OffsetToPointer(prevo);
			if (p->blockCount == blockCount)
				prev->next = p->next;	// remove chunk from free list
			else
			{
				// claim the end of the chunk
				p->blockCount -= blockCount;
				p += p->blockCount;
				p->blockCount = blockCount;
			}
			heap->free = prevo;
			break;
		}
		if (po != heap->free)
			continue;
		// end of the free list - allocate a new block
		{
			u32 rsize;
			if (blockCount < heap->minAllocBlockCount)
				blockCount = heap->minAllocBlockCount;
			rsize = blockCount * HEAPLLIST_BLOCKSIZE;
			if (heap->freepos + rsize > heap->capacity)
				return 0;
			p = HeapLList_OffsetToPointer(heap->freepos);
			heap->freepos += rsize;
			p->blockCount = blockCount;
			break;
		}
	}

	return p + 1;
}

void HeapLList_Free(HeapLList* heap, void* ptr)
{
	HeapLListHeader *h, *p, *n;
	u32 ho, po;

	h = (HeapLListHeader*)ptr - 1;
	ho = HeapLList_PointerToOffset(h);

	po = heap->free;
	p = HeapLList_OffsetToPointer(po);
	for (; ho <= po || ho >= p->next; po = p->next)
	{
		p = HeapLList_OffsetToPointer(po);
		// check the wrapping around list case
		if (po >= p->next && (ho > po || ho < p->next))
			break;
	}

	// combine with next block
	if (ho + h->blockCount == p->next)
	{
		n = HeapLList_OffsetToPointer(p->next);
		h->blockCount += n->blockCount;
		h->next = n->next;
	}
	else
		h->next = p->next;

	// combine with prev block
	if (po + p->blockCount == ho)
	{
		p->blockCount += h->blockCount;
		p->next = h->next;
	}
	else
		p->next = ho;

	heap->free = po;
}

void* HeapLList_ReAlloc(HeapLList* heap, void* ptr, u32 newSize)
{
	HeapLListHeader *h, *prev, *p;
	u32 prevo, po, ho;
	u32 blockCount;

	blockCount = (u32)((newSize + HEAPLLIST_BLOCKSIZE - 1) / HEAPLLIST_BLOCKSIZE + 1);
	if (blockCount < heap->minAllocBlockCount)
		blockCount = heap->minAllocBlockCount;

	h = (HeapLListHeader*)ptr - 1;

	if (blockCount <= h->blockCount)
	{
		if (blockCount == h->blockCount)
			return ptr;

		p = h + blockCount;
		p->blockCount = h->blockCount - blockCount;
		h->blockCount = blockCount;
		HeapLList_Free(heap, p + 1);
		return ptr;
	}

	ho = HeapLList_PointerToOffset(h);
	prevo = heap->free;
	prev = HeapLList_OffsetToPointer(prevo);
	po = prev->next;
	p = HeapLList_OffsetToPointer(po);
	for (; ho <= po || ho >= p->next; prevo = po, prev = p, po = p->next)
	{
		p = HeapLList_OffsetToPointer(po);
		// check the wrapping around list case
		if (po >= p->next && (ho > po || ho < p->next))
			break;
	}

	// check if next block is free and big enough
	if (ho + h->blockCount == p->next && HeapLList_OffsetToPointer(p->next)->blockCount + h->blockCount >= blockCount)
	{
		p->blockCount -= blockCount - h->blockCount;
		if (p->blockCount == 0)
		{
			prev->next = p->next;
			if (heap->free == po)
				heap->free = prevo;
		}
		h->blockCount = blockCount;
		return ptr;
	}

	// if ptr is the last alloc, try and allocate extra memory at the end
	if ((u8*)(h + h->blockCount) == (u8*)HeapLList_OffsetToPointer(heap->freepos))
	{
		u32 rsize;
		rsize = (blockCount - h->blockCount) * HEAPLLIST_BLOCKSIZE;
		if (heap->freepos + rsize <= heap->capacity)
		{
			heap->freepos += rsize;
			h->blockCount = blockCount;
			return ptr;
		}
	}

	// unable to realloc
	{
		void* nptr = HeapLList_Alloc(heap, newSize);
		dmaCopy(ptr, nptr, (u32)((h->blockCount - 1) * HEAPLLIST_BLOCKSIZE));
		HeapLList_Free(heap, ptr);
		return nptr;
	}
}

