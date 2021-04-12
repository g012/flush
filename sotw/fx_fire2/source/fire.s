/*--------------------------------------*
 * Fire effect on Gameboy Advance	*
 * by zerkman / sector one		*
 *--------------------------------------*/

	.section .text,"ax"
	.thumb
	.align

	.global	palette_generation
	.thumb_func
@ palette generator
@ r0 : address of the data.
@ r1 : destination address.
palette_generation:
	push	{r4-r7}
	mov	r4,r8
	mov	r5,r9
	mov	r6,r10
	mov	r7,r11
	push	{r4-r7}
palette_gen_loop0:
	ldrb	r2,[r0,#3]	@number of steps
	cmp	r2,#0
	beq	palette_gen_end
	ldr	r3,=inverse_table
	lsl	r4,r2,#1
	ldrh	r3,[r3,r4]	@r3=1/r2

	ldrb	r4,[r0,#0]	@current red value
	ldrb	r5,[r0,#1]	@current green value
	ldrb	r6,[r0,#2]	@current blue value
	lsl	r4,r4,#8
	lsl	r5,r5,#8
	lsl	r6,r6,#8

	ldrb	r7,[r0,#4]	@next red value
	lsl	r7,r7,#8
	sub	r7,r7,r4	@red offset
	mul	r7,r7,r3	@red offset / number of steps
	asr	r7,r7,#16
	mov	r8,r7

	ldrb	r7,[r0,#5]	@next green value
	lsl	r7,r7,#8
	sub	r7,r7,r5	@green offset
	mul	r7,r7,r3	@green offset / number of steps
	asr	r7,r7,#16
	mov	r9,r7

	ldrb	r7,[r0,#6]	@next blue value
	lsl	r7,r7,#8
	sub	r7,r7,r6	@blue offset
	mul	r7,r7,r3	@blue offset / number of steps
	asr	r7,r7,#16
	mov	r10,r7
	mov	r11,r0		@save the data address

palette_gen_loop:
	@store the current colour
	lsr	r0,r4,#11	@red value
	lsr	r3,r5,#6
	mov	r7,#0x001F	@mask
	lsl	r7,r7,#5	@green mask
	and	r3,r3,r7	@green value
	orr	r0,r0,r3
	lsr	r3,r6,#1
	lsl	r7,r7,#5	@blue mask
	and	r3,r3,r7	@blue value
	orr	r0,r0,r3
	strh	r0,[r1]
	add	r1,r1,#2

	@compute the next colour
	add	r4,r4,r8	@red
	add	r5,r5,r9	@green
	add	r6,r6,r10	@blue

	sub	r2,r2,#1
	bne	palette_gen_loop
	mov	r0,r11		@restore the data address
	add	r0,r0,#4
	b	palette_gen_loop0
palette_gen_end:
	pop	{r4-r7}
	mov	r8,r4
	mov	r9,r5
	mov	r10,r6
	mov	r11,r7
	pop	{r4-r7}
	bx	lr

	.pool


	.section .iwram,"ax"
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
