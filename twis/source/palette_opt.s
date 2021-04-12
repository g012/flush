	.section .iwram,"ax",%progbits
	.arm
	.align 2

// enable this to get rounding on both blend and fade
//#define CLR_ROUND 

    /*
     * From http://forum.gbadev.org/viewtopic.php?p=53322#53322
     * This is Tonc's modified version with optional rounding.
     */
    .global palette_blend
    .type palette_blend,%function
palette_blend:
	movs	r3, r3, lsr #1			@ adjust nclrs for u32 run
	bxeq	lr						@ quit on nclrs=0
	ldr		r12, [sp]				@ get alpha from stack
#ifdef CLR_ROUND
	stmfd	sp!, {r4-r10, lr}
	ldr		lr, =0x00200401			@ -1-|1-1
	rsb		r7, lr, lr, lsl #5		@ MASKLO: -g-|b-r
#else
	stmfd	sp!, {r4-r10}
	ldr		r7, =0x03E07C1F			@ MASKLO: -g-|b-r
#endif
	mov		r6, r7, lsl #5			@ MASKHI: g-|b-r-
.Lbld_fast_loop:
		ldr		r8, [r0], #4			@ a= *pa++
		ldr		r9, [r1], #4			@ b= *pb++
		@ --- -g-|b-r
		and		r4, r6, r8, lsl #5		@ x/32: (-g-|b-r)
		and		r5, r7, r9				@ y: -g-|b-r
		sub		r5, r5, r4, lsr #5		@ z: y-x
		mla		r4, r5, r12, r4			@ z: (y-x)*w + x*32
#ifdef CLR_ROUND
		add		r4, r4, lr, lsl #4		@ round
#endif
		and		r10, r7, r4, lsr #5		@ blend(-g-|b-r)			
		@ --- b-r|-g- (rotated by 16 for great awesome)
		and		r4, r6, r8, ror #11		@ x/32: -g-|b-r (ror16)
		and		r5, r7, r9, ror #16		@ y: -g-|b-r (ror16)
		sub		r5, r5, r4, lsr #5		@ z: y-x
		mla		r4, r5, r12, r4			@ z: (y-x)*w + x*32
#ifdef CLR_ROUND
		add		r4, r4, lr, lsl #4		@ round
#endif
		and		r4, r7, r4, lsr #5		@ blend(-g-|b-r (ror16))
		@ --- mix -g-|b-r and b-r|-g-
		orr		r10, r10, r4, ror #16
		@ --- write blended, loop
		str		r10, [r2], #4			@ *dst++= c
		subs	r3, r3, #1
		bgt		.Lbld_fast_loop		
#ifdef CLR_ROUND
	ldmfd	sp!, {r4-r10, lr}
#else
	ldmfd	sp!, {r4-r10}
#endif
	bx		lr


    /*
     * Derivative from blend which fades to a fixed target color.
     */
    .global palette_fade
    .type palette_fade,%function
palette_fade:
	movs	r3, r3, lsr #1			@ adjust nclrs for u32 run
	bxeq	lr						@ quit on nclrs=0
	ldr		r12, [sp]				@ get alpha from stack
#ifdef CLR_ROUND
	stmfd	sp!, {r4-r10, lr}
	ldr		lr, =0x00200401			@ -1-|1-1
	rsb		r7, lr, lr, lsl #5		@ MASKLO: -g-|b-r
#else
	stmfd	sp!, {r4-r10}
	ldr		r7, =0x03E07C1F			@ MASKLO: -g-|b-r
#endif
	mov		r6, r7, lsl #5			@ MASKHI: g-|b-r-

	@ Precalc y1 and y2
	orr		r1, r1, r1, lsl #16
	and		r9, r7, r1, ror #16		@ precalc: y2= -g-|b-r (ror16)
	and		r1, r7, r1				@ precalc: y1= -g-|b-r
.Lfade_fast_loop:
		ldr		r8, [r0], #4			@ a= *pa++
		@ --- -g-|b-r
		and		r4, r6, r8, lsl #5		@ x/32: (-g-|b-r)
		sub		r5, r1, r4, lsr #5		@ z: y1-x
		mla		r4, r5, r12, r4			@ z: (y1-x)*w + x*32
#ifdef CLR_ROUND
		add		r4, r4, lr, lsl #4		@ round
#endif
		and		r10, r7, r4, lsr #5		@ blend(-g-|b-r)			
		@ --- b-r|-g- (rotated by 16 for great awesome)
		and		r4, r6, r8, ror #11		@ x/32: -g-|b-r (ror16)
		sub		r5, r9, r4, lsr #5		@ z: y2-x
		mla		r4, r5, r12, r4			@ z: (y2-x)*w + x*32
#ifdef CLR_ROUND
		add		r4, r4, lr, lsl #4		@ round
#endif
		and		r4, r7, r4, lsr #5		@ blend(-g-|b-r (ror16))
		@ --- mix -g-|b-r and b-r|-g-
		orr		r10, r10, r4, ror #16
		@ --- write faded, loop
		str		r10, [r2], #4			@ *dst++= c
		subs	r3, r3, #1
		bgt		.Lfade_fast_loop		
#ifdef CLR_ROUND
	ldmfd	sp!, {r4-r10, lr}
#else
	ldmfd	sp!, {r4-r10}
#endif
	bx		lr


