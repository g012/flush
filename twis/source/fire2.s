/*--------------------------------------*
 * Fire effect on Gameboy Advance	*
 * by zerkman / sector one		*
 *--------------------------------------*/

	.section .iwram3,"ax"
	.arm
	.align

	.global	render_fire
	.type	render_fire,%function
@ render fire
@r0 = screen address
@r1 = random seed
@r2 = local 120x81 buffer
@returns new random seed
render_fire:
@ set display to mode 4, select the screen to be displayed
	stmfd	r13!,{r4-r12}

	mov	r9,r2		@screen buffer
	mov	r12,r1		@random seed

@ fill the bottom of the drawing screen with random stuff.
	add	r2,r9,#120*80	@address of the bottom of the screen
	mov	r3,#120 	@pixels counter
rnd_loop:
	mov	r4,r12,lsr #24
	strb	r4,[r2],#1	@store the next random number
	add	r12,r12,r12,lsl #6
	add	r12,r12,#37	@next LCG value of the random generator
	subs	r3,r3,#1
	bne	rnd_loop

@ draw the screen.
	add	r10,r9,#120
	mov	r3,#80 		@lines counter
lines_loop:

	mov	r4,#120 	@pixels counter
pixels_loop:
	ldrb	r5,[r10,#1]	@right pixel
	ldrb	r7,[r10,#-1]	@left pixel
	add	r5,r5,r7
	ldrb	r7,[r10],#1	@bottom pixel
	add	r5,r5,r7
	ldrb	r7,[r9]		@pos pixel
	add	r5,r5,r7	@new pixel value << 2
	movs	r5,r5,lsr #2	@new pixel value
	subne	r5,r5,#1
	strb	r5,[r9],#1	@new pixel value

	ldrb	r6,[r10,#1]	@right pixel
	ldrb	r7,[r10,#-1]	@left pixel
	add	r6,r6,r7
	ldrb	r7,[r10],#1	@bottom pixel
	add	r6,r6,r7
	ldrb	r7,[r9]		@pos pixel
	add	r6,r6,r7	@new pixel value << 2
	movs	r6,r6,lsr #2	@new pixel value
	subne	r6,r6,#1
	strb	r6,[r9],#1	@new pixel value

	orr	r6,r5,r6,lsl #8
	strh	r6,[r0],#2	@store the pixel values

	subs	r4,r4,#2
	bne	pixels_loop

	add	r0,r0,#120

	subs	r3,r3,#1
	bne	lines_loop

	mov	r0,r12
	ldmfd	r13!,{r4-r12}
	bx	lr
