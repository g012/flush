/*------------------------------*
 * 3d on Gameboy Advance	*
 * by zerkman / sector one	*
 *------------------------------*/

	.section .text,"ax"
	.thumb
	.align

SIN_BITS	=	14
Z_SHIFT 	=	7
T_SH		=	4
RADIX_N		=	4
MAX_VISIBLE	=	2000

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

@sort an array of ints, according to most significant bits
@r0 = array address
@r1 = number of items
@r2 = most significant bit position
radix_sort:
	sub	r3,r13,#(1<<RADIX_N)*4	@pointer/counter array
	sub	r4,r3,r1,lsl #2		@second array
	mov	r5,r13
	mov	r13,r4
	str	r5,[r13,#-4]!

rs_loop:
	mov	r9,#0
	mov	r10,#0
	mov	r11,#0
	mov	r12,#0
	add	r8,r3,#(1<<RADIX_N)*4
	mov	r5,#1<<(RADIX_N-2)
rs_clear:
	stmfd	r8!,{r9-r12}
	subs	r5,#1
	bne	rs_clear

	mov	r5,#0
rs_scan1:
	ldr	r6,[r0,r5,lsl #2]	@read array element
	mov	r7,#(1<<RADIX_N)-1	@bit mask
	and	r7,r7,r6,lsr r2		@extract radix bits
	ldr	r8,[r3,r7,lsl #2]	@radix counter
	add	r8,#1
	str	r8,[r3,r7,lsl #2]	@incremented counter
	add	r5,#1
	cmp	r5,r1
	bne	rs_scan1

	mov	r5,#0
	mov	r6,r4			@second array address
rs_mkptr:
        ldr     r7,[r3,r5,lsl #2]	@counter value
        str	r6,[r3,r5,lsl #2]	@pointer
	add	r6,r7,lsl #2		@increase pointer vith value
	add	r5,#1
	cmp	r5,#(1<<RADIX_N)
	bne	rs_mkptr

	mov	r5,#0
rs_scan2:
	ldr	r6,[r0,r5,lsl #2]	@read array element
	mov	r7,#(1<<RADIX_N)-1	@bit mask
	and	r7,r7,r6,lsr r2		@extract radix bits
	ldr	r8,[r3,r7,lsl #2]	@radix pointer
	str	r6,[r8],#4		@store element at destination address
	str	r8,[r3,r7,lsl #2]	@store updated pointer
	add	r5,#1
	cmp	r5,r1
	bne	rs_scan2

	mov	r5,r0
	mov	r0,r4
	mov	r4,r5			@swap array addresses

	add	r2,#RADIX_N
	cmp	r2,#32
	bmi	rs_loop

	ldr	r13,[r13]
	mov	pc,r14


@draw a polygon on the screen.
@r0 = screen address
@r1 = 2d vertex array address (v0.x, v0.y, dummy, v1.x, ...)
@r2 = polygon definition address (vertex count, v1, v2, ...)
@r3 = colour of the polygon [0;255]
draw_poly:
	stmfd	r13!,{r0,r4-r9,r14}
	sub	r13,r13,#8	@allocate two words in the stack
	@look for the uppermost corner.
	ldrh	r4,[r2],#2	@vertex count
	mov	r4,r4,lsl #1	@vertex count*2
	add	r5,r1,#2	@y coord array.
	mov	r6,#0x7fffffff	@currently highest known y coord
	sub	r9,r4,#2	@offset of the last vertex
dp_uppermost_loop:
	ldrh	r10,[r2,r9] 	@next vertex number*4
	ldrsh	r8,[r5,r10] 	@next vertex y coord
	cmp	r8,r6		@new coord < current coord ?
	movlt	r6,r8		@new highest y coord
	movlt	r7,r9		@position in poly [0;n-1]*2 of current topmost vertex
	movlt	r11,r10		@number*4 of the current topmost vertex
	subs	r9,r9,#2
	bpl	dp_uppermost_loop

	orr	r3,r3,r4,lsl #16	@save vertex count (spare one register)
	ldrsh	r12,[r1,r11]		@lefttopmost x position
	mov	r8,r12			@righttopmost x position
	mov	r4,r6			@righttopmost y position
	mov	r10,r7			@righttopmost position in poly

	sub	r5,r6,#1
	movs	r5,r5,asr #T_SH
	adcs	r5,r5,#0		@integer rounded current y coord
dp_search_left:
	add	r7,r7,#2		@next left vertex offset
	cmp	r7,r3,lsr #16
	moveq	r7,#0			@list loop control
	ldrh	r9,[r2,r7]		@next vertex number*4
	add	r11,r1,r9	 	@next vertex 2d coords address
	ldrsh	r9,[r11,#2]		@next left y coord
	cmp	r9,r6
	bmi	dp_end
	movs	r14,r9,asr #T_SH
	adcs	r14,r14,#0		@integer rounded next y coord
	cmp	r5,r14
	ldreqsh	r12,[r11]		@curr x <- new x
	moveq	r6,r9			@curr y <- new y
	beq	dp_search_left

	str	r7,[r13,#4]		@store the next left vertex
	mov	r7,r12			@current left x coord
	ldrsh	r5,[r11]		@next left x coord

	sub	r12,r4,#1
	movs	r12,r12,asr #T_SH
	adcs	r12,r12,#0		@integer rounded current y coord
dp_search_right:
	subs	r10,r10,#2		@next right vertex offset
	addmi	r10,r3,lsr #16		@list loop control
	ldrh	r11,[r2,r10]		@next right vertex number*4
	add	r11,r1,r11		@next vertex 2d coords address
	ldrsh	r14,[r11,#2]		@next right y coord
	cmp	r14,r4
	bmi	dp_end
	movs	r14,r14,asr #T_SH
	adcs	r14,r14,#0		@integer rounded next y coord
	cmp	r12,r14
	ldreqsh	r8,[r11]		@curr x <- new x
	ldreqsh	r4,[r11,#2]		@curr y <- new y
	beq	dp_search_right

	str	r10,[r13]		@store the next right vertex
	ldrsh	r12,[r11]		@next right x coord
	ldrsh	r11,[r11,#2]		@next right y coord

	ldr	r14,=inverse_table

	sub	r5,r5,r7		@x deviation
	mov	r7,r7,lsl #16-T_SH	@current left x coord (16.16)
	sub	r9,r9,r6		@y deviation
	lsl	r10,r9,#1
	ldrh	r10,[r14,r10]		@1/(y deviation)
	mul	r5,r10,r5		@x deviation per line (16.16)
	@r5 = left x deviation per line (16.16)
	@r7 = current left x coord (16.16)
	@r9 = left y deviation

	mov	r10,r8,lsl #16-T_SH	@current right x coord (16.16)
	sub	r8,r12,r8		@x deviation
	sub	r11,r11,r4		@y deviation
	lsl	r12,r11,#1
	ldrh	r12,[r14,r12]		@1/(y deviation)
	mul	r8,r12,r8		@x deviation per line (16.16)
	@r8 = right x deviation per line (16.16)
	@r10 = current right x coord (16.16)
	@r11 = right y deviation

	@finish some pre-computings before main loop.
	mov     r14,r6
	add	r6,r6,#(1<<(T_SH-1))-1
	and	r6,r6,#-1<<T_SH		@round y to nearest integer
	orr	r6,r6,#1<<(T_SH-1)	@set y to half-pixel
	sub	r14,r6,r14		@fractional y increment to get to half-pixel
	mul	r12,r5,r14
	add	r7,r12,asr #T_SH
	sub     r4,r6,r4
	mul	r12,r8,r4
	add	r10,r12,asr #T_SH
	subs	r11,r11,r4		@decrement right y counter
	subs	r9,r9,r14		@decrement left y counter

	mov	r12,#240
	mov	r4,r6,lsr #T_SH
	mla	r0,r12,r4,r0 		@line address in bytes
	@r4,r12,r14 = free

dp_line_loop:
	movs	r14,r7,asr #16		@integer value of left x position
	adcs	r14,r14,#0		@plus topmost decimal bit
	movmi	r14,#0			@left clipping
	add	r14,r14,r0		@pixel address
	movs	r12,r10,asr #16 	@integer value of right x position
	adc	r12,r12,#0		@plus topmost decimal bit
	cmp	r12,#240
	movgt	r12,#240		@right clipping
	add	r12,r12,r0		@pixel address
	cmp	r6,#0			@top clipping
	bmi	dp_end_of_line
	cmp	r6,#160<<T_SH
	bpl	dp_end
	cmp	r14,r12
	bpl	dp_end_of_line		@if width <= 0 pixels, display nothing.
	tst	r14,#1			@is r14 odd ?
	beq	dp_no_left_odd
	ldrh	r4,[r14,#-1]!		@read two pixels
	and	r4,r4,#0xff		@remove the right pixel
	orr	r4,r4,r3,lsl #8 	@replace it with our colour.
	strh	r4,[r14],#2		@write the new values
dp_no_left_odd:
	tst	r12,#1			@is r12 odd ?
	beq	dp_no_right_odd
	ldrh	r4,[r12,#-1]!		@read two pixels
	and	r4,r4,#0xff00		@remove the left pixel
	orr	r4,r4,r3		@replace it with our colour
	strh	r4,[r12]		@store the new values
dp_no_right_odd:
	subs	r12,r12,r14		@number of bytes to be written
	beq	dp_end_of_line		@if width == 0 pixels, display nothing.
	orr	r4,r3,r3,lsl #8 	@write 2 pixels at a time
dp_write_loop:
	strh	r4,[r14],#2
	subs	r12,r12,#2
	bne	dp_write_loop

dp_end_of_line:
	add	r0,r0,#240		@new line address
	add	r7,r7,r5		@add left x deviation
	add	r10,r10,r8		@add right x deviation
	add	r6,r6,#1<<T_SH		@increment y position.
	subs	r11,r11,#1<<T_SH	@decrement right y counter
	blle	dp_new_right_vertex
	subs	r9,r9,#1<<T_SH		@decrement left y counter
	blle	dp_new_left_vertex
	b	dp_line_loop

dp_new_left_vertex:
	@free = r4, r5, r7, r9, r12
	ldr	r12,[r13,#4]		@get current left vertex from the stack
	ldrh	r7,[r2,r12]		@current vertex number *4
	add	r7,r1			@vertex address
	ldrsh	r4,[r7,#2]		@current y coord
	ldrsh	r7,[r7]			@current x coord
	add	r12,r12,#2		@next vertex
	cmp	r12,r3,lsr #16		@number of vertices *2
	moveq	r12,#0			@list loop control
	str	r12,[r13,#4]		@store the next vertex in the stack
	ldrh	r12,[r2,r12]		@next vertex number *4
	add	r12,r1			@next vertex 2d coords address
	ldrsh	r5,[r12,#2]		@next y coord
	subs	r9,r5,r4		@new y deviation
	ble	dp_end
	cmp	r5,r6
	bmi	dp_new_left_vertex	@loop if next y coord is above current line
	ldrsh	r12,[r12]		@next x coord
	sub	r5,r12,r7		@new x deviation
	ldr	r12,=inverse_table
	add	r12,r9,lsl #1
	ldrh	r12,[r12]		@1/(y deviation)
	mul	r5,r12,r5		@left x deviation per line (16.16)
	mov	r7,r7,lsl #16-T_SH	@x position in 16.16 format
	sub	r12,r6,r4		@half-pixel y coord-current y coord (.T_SH)
	mul	r4,r5,r12		@x deviation to half pixel (.16+T_SH)
	add	r7,r7,r4,asr #T_SH
	sub	r9,r12			@adjust y deviation
	mov	pc,r14

dp_new_right_vertex:
	@free = r4, r8, r10, r11, r12
	ldr	r12,[r13]		@get current right vertex from the stack
	ldrh	r10,[r2,r12]		@current vertex number *4
	add	r10,r1			@vertex address
	ldrsh	r4,[r10,#2]		@current y coord
	ldrsh	r10,[r10]		@current x coord
	subs	r12,r12,#2		@next vertex.
	addmi	r12,r12,r3,lsr #16	@list loop control
	str	r12,[r13]		@store the next vertex in the stack
	ldrh	r12,[r2,r12]		@next vertex number *4
	add	r12,r1			@next vertex 2d coords address
	ldrsh	r8,[r12,#2]		@next y coord.
	subs	r11,r8,r4		@new y deviation
	ble	dp_end			@ <= 0 -> end of poly drawing
	cmp	r8,r6
	bmi	dp_new_right_vertex	@loop if next y coord is above current line
	ldrsh	r12,[r12]		@next x coord
	sub	r8,r12,r10		@new x deviation
	ldr	r12,=inverse_table
	add	r12,r11,lsl #1
	ldrh	r12,[r12]		@1/(y deviation)
	mul	r8,r12,r8		@right x deviation per line (16.16)
	mov	r10,r10,lsl #16-T_SH 	@x position in 16.16 format
	sub	r12,r6,r4		@half-pixel y coord-current y coord (.T_SH)
	mul	r4,r8,r12		@x deviation to half pixel (.16+T_SH)
	add	r10,r10,r4,asr #T_SH
	sub	r11,r12			@adjust y deviation
	mov	pc,r14

dp_end:
	add	r13,r13,#8		@release the pushed values
	ldmfd	r13!,{r0,r4-r9,pc}

	.global	draw_object
	.type	draw_object,%function
@draw a 2D object onto the screen
@r0 = screen address
@r1 = buffer of 2D-projected vertices
@r2 = rotation matrix
@r3 = object definition address
@[sp] = light source position
draw_object:
	stmfd	r13!,{r4-r12,lr}
	ldrh	r5,[r3],#2		@vertex count
	ldrh	r14,[r3],#2		@polygon count
	add	r5,r5,r5,lsl #1
	add	r3,r3,r5,lsl #1		@address of the polygons.

	@generate a table of the visible polygons.
	mov	r5,#-1
	str	r5,[r13,#-4]!		@terminal element of the list
	mov	r12,r13			@end of visible list (on the stack)
	mov	r5,r3			@list of the polygons
do_visible_loop:
	ldrh	r6,[r5,#10]		@first vertex
	add	r6,r1,r6		@its 2d coords
	ldrh	r7,[r5,#12]		@second vertex
	add	r7,r1,r7		@its 2d coords
	ldrh	r8,[r5,#14]		@third vertex
	add	r8,r1,r8		@its 2d coords
	ldrsh	r9,[r7] 		@x2
	ldrsh	r7,[r7,#2]		@y2
	ldrsh	r11,[r6]		@x1
	sub	r11,r9,r11		@x2-x1
	ldrsh	r10,[r8,#2]		@y3
	sub	r10,r10,r7		@y3-y2
	mul	r11,r10,r11		@(x2-x1)(y3-y2)
	ldrsh	r10,[r6,#2]		@y1
	sub	r7,r7,r10		@y2-y1
	ldrsh	r10,[r8]		@x3
	sub	r10,r10,r9		@x3-x2
	mul	r10,r7,r10		@(y2-y1)(x3-x2)
	cmp	r11,r10	 		@is the polygon drawable ?
	bpl	do_not_drawable

@x clipping
	add	r6,r5,#8		@vertex list address
	ldrh	r4,[r6],#2		@vertex count
	ldrh	r7,[r6],#2		@first vertex
	ldrsh	r8,[r1,r7]		@its x coord
	mov	r9,r8			@x min
	mov	r10,r8			@x max
	sub	r4,#1
do_xclip_loop:
	ldrh	r7,[r6],#2		@next vertex
	ldrsh	r8,[r1,r7]		@x coord
	cmp	r8,r9
	movmi	r9,r8			@update x min
	cmp	r8,r10
	movpl	r10,r8			@update x max
	subs	r4,#1
	bne	do_xclip_loop
        ldr     r7,=((239<<1)+1)<<(T_SH-1)+1
	cmp	r9,r7
	bpl	do_not_drawable
	cmp	r10,#1<<(T_SH-1)
	bmi	do_not_drawable

	ldrh	r6,[r5,#10]		@first vertex
	add	r6,r1,r6		@its 2d coords
	sub	r7,r5,r3		@polygon offset
	ldrsh	r6,[r6,#4]		@get the first z coord of the polygon
	sub	r7,r6,lsl #16		@shift it to msb part of offset
	str	r7,[r13,#-4]!		@store it along with the poly
do_not_drawable:
	ldrh	r6,[r5,#8] 		@polygon count
	add	r5,#10
	add	r5,r5,r6,lsl #1		@next polygon address
	subs	r14,r14,#1
	bne	do_visible_loop

	ldr	r4,[r12,#(10+1)*4]	@light source position

	stmfd	r13!,{r0-r4}
	@sort the polygons.
	add	r0,r13,#5*4		@visible array address
	sub	r1,r12,r0		@offset to end of array
	lsr	r1,#2			@number of items
	mov	r2,#16			@starting lsb
	bl	radix_sort

	ldmfd	r13!,{r0-r4}

	@now, draw the visible polygons.
	mov	r5,r3			@polygons address
	mov	r6,r2			@rotation matrix
	ldrsh	r7,[r4]			@light direction x
	ldrsh	r8,[r4,#2]		@light direction y
	ldrsh	r9,[r4,#4]		@light direction z

	b	do_poly_test
do_poly_loop:
	@mov	r3,r2,lsl #1
	@and	r3,r3,#0xff
	add	r2,r2,r5		@poly color and normal

	ldrsh	r10,[r2,#2]		@normal x
	ldrsh	r11,[r2,#4]		@normal y
	ldrsh	r12,[r2,#6]		@normal z
	ldr	r14,[r6],#4
	mul	r4,r14,r10
	ldr	r14,[r6],#4
	mla	r4,r14,r11,r4
	ldr	r14,[r6],#4
	mla	r4,r14,r12,r4
	asr	r4,#15			@rotated x normal
	mul	r3,r4,r7		@scalar product with light.x
	ldr	r14,[r6],#4
	mul	r4,r14,r10
	ldr	r14,[r6],#4
	mla	r4,r14,r11,r4
	ldr	r14,[r6],#4
	mla	r4,r14,r12,r4
	asr	r4,#15			@rotated y normal
	mla	r3,r4,r8,r3		@scalar product with light.y
	ldr	r14,[r6],#4
	mul	r4,r14,r10
	ldr	r14,[r6],#4
	mla	r4,r14,r11,r4
	ldr	r14,[r6],#-32
	mla	r4,r14,r12,r4
	asr	r4,#15			@rotated z normal
	mla	r3,r4,r9,r3		@scalar product with light.z

	mov	r3,r3,asr #26
	add	r3,#16
	ldrh	r4,[r2],#8
	add	r3,r4,lsl #5

	bl	draw_poly
do_poly_test:
	ldrh	r2,[r13],#4		@fetch next polygon
	mov	r10,#-1
	cmp	r2,r10,lsr #16
	bne	do_poly_loop

	ldmfd	r13!,{r4-r12,lr}
	bx	lr

	.global	make_matrix
	.type	make_matrix,%function
@compute a rotation matrix
@r0 = destination matrix
@r1 = x rotation angle (a)
@r2 = y rotation angle (b)
@r3 = z rotation angle (c)
make_matrix:
	stmfd	r13!,{r8-r12,r14}
	ldr	r14,=sin_table
	mov	r1,r1,lsl #1		@because of ldrsh
	mov	r2,r2,lsl #1		@because of ldrsh
	mov	r3,r3,lsl #1		@because of ldrsh
	ldrsh	r8,[r14,r1]		@sin a (1.15 format)
	ldrsh	r9,[r14,r2]		@sin b
	ldrsh	r10,[r14,r3]		@sin c
	add	r14,r14,#1<<(SIN_BITS-1)	@cos table
	ldrsh	r11,[r14,r1]		@cos a
	ldrsh	r12,[r14,r2]		@cos b
	ldrsh	r14,[r14,r3]		@cos c
	mul	r1,r12,r14		@cos b.cos c (2.30 format)
	mov	r1,r1,asr #15		@17.15 format
	str	r1,[r0],#4

	mul	r1,r12,r10		@cos b.sin c
	mov	r1,r1,asr #15
	rsb	r1,r1,#0		@-cos b.sin c
	str	r1,[r0],#4

	str	r9,[r0],#4		@sin b

	mul	r3,r8,r9		@sin a.sin b
	mov	r3,r3,asr #15
	mul	r1,r3,r14		@sin a.sin b.cos c
	mov	r1,r1,asr #15
	mul	r2,r11,r10		@cos a.sin c
	add	r1,r1,r2,asr #15	@sin a.sin b.cos c + cos a.sin c
	str	r1,[r0],#4

	mul	r1,r11,r14		@cos a.cos c
	mov	r1,r1,asr #15
	mul	r2,r3,r10		@sin a.sin b.sin c
	sub	r1,r1,r2,asr #15	@-sin a.sin b.sin c + cos a.cos c
	str	r1,[r0],#4

	mul	r1,r8,r12		@sin a.cos b
	mov	r1,r1,asr #15
	rsb	r1,r1,#0		@-sin a.cos b
	str	r1,[r0],#4

	mul	r1,r8,r10		@sin a.sin c
	mov	r1,r1,asr #15
	mul	r3,r11,r9		@cos a.sin b
	mov	r3,r3,asr #15
	mul	r2,r3,r14		@cos a.sin b.cos c
	sub	r1,r1,r2,asr #15	@-cos a.sin b.cos c + sin a.sin c
	str	r1,[r0],#4

	mul	r1,r3,r10		@cos a.sin b.sin c
	mov	r1,r1,asr #15
	mul	r2,r8,r14		@sin a.cos c
	add	r1,r1,r2,asr #15	@cos a.sin b.sin c + sin a.cos c
	str	r1,[r0],#4

	mul	r1,r11,r12		@cos a.cos b
	mov	r1,r1,asr #15
	str	r1,[r0],#-32

	ldmfd	r13!,{r8-r12,r14}
	bx	r14

.global	rotransjection
.type	rotransjection,%function
@perform a rotation / translation / 2D projection of the vertices of an object
@r0 = destination address for projected vertices
@r1 = object address
@r2 = rotation matrix
@r3 = x translation offset
@r4 = y translation offset
@r5 = z translation offset
rotransjection:
	stmfd	r13!,{r4-r12,lr}
	add	r12,r13,#10*4
	ldmfd	r12,{r4-r5}

	ldrh	r6,[r1],#4		@vertex count
	sub	r6,r6,#1
	mov	r7,#-1
	and	r3,r3,r7,lsr #15
	orr	r3,r3,r6,lsl #17	@trick to spare one register
	ldr	r14,=inverse_table
rtj_vertex_loop:
	ldrsh	r6,[r1],#2		@x coord of the vertex
	ldrsh	r7,[r1],#2		@y coord
	ldrsh	r8,[r1],#2		@z coord

	mov	r10,r3,lsl #15		@this removes the vertex count
	ldr	r9,[r2],#4
	mla	r10,r6,r9,r10
	ldr	r9,[r2],#4
	mla	r10,r7,r9,r10
	ldr	r9,[r2],#4
	mla	r10,r8,r9,r10
	mov	r10,r10,asr #(15-Z_SHIFT) 	@rotated + translated x coord.

	mov	r11,r4,lsl #15
	ldr	r9,[r2],#4
	mla	r11,r6,r9,r11
	ldr	r9,[r2],#4
	mla	r11,r7,r9,r11
	ldr	r9,[r2],#4
	mla	r11,r8,r9,r11
	mov	r11,r11,asr #(15-Z_SHIFT)	@rotated + translated y coord.

	ldr	r9,[r2],#4
	mul	r12,r6,r9
	ldr	r9,[r2],#4
	mla	r12,r7,r9,r12
	ldr	r9,[r2],#-32
	mla	r12,r8,r9,r12
	add	r12,r5,r12,asr #15	@rotated + translated z coord.
	rsb	r12,r12,#0		@-z (should be positive)
	strh	r12,[r0,#4]		@store it for sorting purposes
	lsl	r12,#1
	ldrh	r12,[r14,r12]		@1/-z (0.32 format)
	mov	r12,r12,lsl #T_SH 	@1/-z (16.16 format)

	mul	r10,r12,r10		@2D x coord (16.16)
	movs	r10,r10,asr #16
	adc	r10,r10,#120<<T_SH	@center to the middle of the screen
	strh	r10,[r0],#2
	mul	r11,r12,r11		@2D y coord (16.16)
	movs	r11,r11,asr #16
	rsc	r11,r11,#80<<T_SH	@center to the middle of the screen
	strh	r11,[r0],#4

	subs	r3,r3,#1<<17
	bpl	rtj_vertex_loop

	ldmfd	r13!,{r4-r12,lr}
	bx	lr

	.global	clear_screen
	.type	clear_screen,%function
@clear the screen
@r0 = screen address
clear_screen:
	stmfd	r13!,{r4-r12,lr}
	mov	r1,#0
	mov	r2,#0
	mov	r3,#0
	mov	r4,#0
	mov	r5,#0
	mov	r6,#0
	mov	r7,#0
	mov	r8,#0
	mov	r9,#0
	mov	r10,#0
	mov	r11,#0
	mov	r12,#0
	mov	r14,#160	@lines counter
clear_scr_loop:
	stmia	r0!,{r1-r12}
	stmia	r0!,{r1-r12}
	stmia	r0!,{r1-r12}
	stmia	r0!,{r1-r12}
	stmia	r0!,{r1-r12}	@12*5*4 = 240 bytes (one full line)
	subs	r14,r14,#1
	bne	clear_scr_loop
	ldmfd	r13!,{r4-r12,lr}
	bx	lr
