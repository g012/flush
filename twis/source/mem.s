// Extra memcpy/set functions taken from Tonc lib.

	.section .iwram,"ax"
	.arm
	.align

    .global memcpy32
    .type   memcpy32,%function
    .global memcpy32_count
    .type   memcpy32_count,%function
@r0 = dst
@r1 = src
@r2 = size in bytes
memcpy32:
	mov	    r2, r2, lsr #2
memcpy32_count: @r2 = size/4
	and		r12, r2, #7
	movs	r2, r2, lsr #3
	beq		2f
	stmfd	sp!, {r4-r10}
1: @ copy 32byte chunks with 8fold xxmia
    ldmia	r1!, {r3-r10}	
    stmia	r0!, {r3-r10}
    subs	r2, r2, #1
    bhi		1b
	ldmfd	sp!, {r4-r10}
2: @ and the residual 0-7 words
    subs	r12, r12, #1
    ldmcsia	r1!, {r3}
    stmcsia	r0!, {r3}
    bhi		2b
	bx	    lr

    .global memset32
    .type   memset32,%function
    .global memset32_count
    .type   memset32_count,%function
@r0 = dst
@r1 = value
@r2 = size in bytes
memset32:
	mov	    r2, r2, lsr #2
memset32_count: @r2 = size/4
	and		r12, r2, #7
	movs	r2, r2, lsr #3
	beq		2f
	stmfd	sp!, {r4-r9}
	mov		r3, r1
	mov		r4, r1
	mov		r5, r1
	mov		r6, r1
	mov		r7, r1
	mov		r8, r1
	mov		r9, r1
1: @ set 32byte chunks with 8fold xxmia
    stmia	r0!, {r1, r3-r9}
    subs	r2, r2, #1
    bhi		1b
	ldmfd	sp!, {r4-r9}
2: @ residual 0-7 words
    subs	r12, r12, #1
    stmhsia	r0!, {r1}
    bhi		2b
	bx	    lr


	.section .text,"ax"
	.thumb
	.align

    .global memcpy16
    .type   memcpy16,%function
    .global memcpy16_count
    .type   memcpy16_count,%function
@r0 = dst
@r1 = src
@r2 = size in bytes
memcpy16:
    lsr     r2, r2, #1
memcpy16_count: @r2 = size/2
	push	{r4,lr}
	@ under 5 hwords -> std cpy
	cmp		r2, #5
	bls		.Ltail_cpy16
	@ unreconcilable alignment -> std cpy
	@ if (dst^src)&2 -> alignment impossible
	mov		r3, r0
	eor		r3, r1
	lsl		r3, r3, #31		@ (dst^src), bit 1 into carry
	bcs		.Ltail_cpy16	@ (dst^src)&2 : must copy by halfword
	@ src and dst have same alignment -> word align
	lsl		r3, r0, #31
	bcc		.Lmain_cpy16	@ ~src&2 : already word aligned
	@ aligning is necessary: copy 1 hword and align
		ldrh	r3, [r1]
		strh	r3, [r0]
		add		r0, #2
		add		r1, #2
		sub		r2, r2, #1
	@ right, and for the REAL work, we're gonna use memcpy32
.Lmain_cpy16:
	lsl		r4, r2, #31
	lsr		r2, r2, #1
	ldr		r3, =memcpy32_count
	bl		.Llong_bl_cpy16
	@ NOTE: r0,r1 are altered by memcpy32, but in exactly the right 
	@ way, so we can use them as is.
	lsr		r2, r4, #31
	beq		.Lend_cpy16
.Ltail_cpy16:
	sub		r2, #1
	bcc		.Lend_cpy16		@ r2 was 0, bug out
	lsl		r2, r2, #1
.Lres_cpy16:
		ldrh	r3, [r1, r2]
		strh	r3, [r0, r2]
		sub		r2, r2, #2
		bcs		.Lres_cpy16
.Lend_cpy16:
	pop	    {r4}
	pop 	{r3}
.Llong_bl_cpy16:
	bx	r3

    .global memset16
    .type   memset16,%function
    .global memset16_count
    .type   memset16_count,%function
@r0 = dst
@r1 = value
@r2 = size in bytes
memset16:
    lsr     r2, r2, #1
memset16_count: @r2 = size/2
	push	{r4, lr}
	@ under 6 hwords -> std set
	cmp		r2, #5
	bls		.Ltail_set16
	@ dst not word aligned: copy 1 hword and align
	lsl		r3, r0, #31
	bcc		.Lmain_set16
		strh	r1, [r0]
		add		r0, #2
		sub		r2, r2, #1
	@ Again, memset32 does the real work
.Lmain_set16:
	lsl		r4, r1, #16
	orr		r1, r4
	lsl		r4, r2, #31
	lsr		r2, r2, #1
	ldr		r3, =memset32_count
	bl		.Llong_bl_set16
	@ NOTE: r0 is altered by memset32, but in exactly the right 
	@ way, so we can use is as is. r1 is now doubled though.
	lsr		r2, r4, #31
	beq		.Lend_set16
	lsr		r1, #16
.Ltail_set16:
	sub		r2, #1
	bcc		.Lend_set16		@ r2 was 0, bug out
	lsl		r2, r2, #1
.Lres_set16:
		strh	r1, [r0, r2]
		sub		r2, r2, #2
		bcs		.Lres_set16
.Lend_set16:
	pop		{r4}
	pop		{r3}
.Llong_bl_set16:
	bx	r3
