	.section .iwram,"ax"
    .arm
    .align
    
	.global	fx_twister_line_flat_S
	.type	fx_twister_line_flat_S,%function
@r0 = VRAM line address
@r1 = x0
@r2 = x1
@r3 = col
fx_twister_line_flat_S:
    stmfd   sp!,{r4}
    subs    r4,r2,r1
    rsbmi   r4,r4,#0
    add     r4,r4,#0x80
    add     r3,r3,r4,lsr #8
    and     r3,r3,#0xFF
    add     r1,r1,#0x80
    add     r2,r2,#0x80
	add	    r1,r0,r1,lsr #8 @start address
	add	    r2,r0,r2,lsr #8 @end address
	tst	    r2,#1			@is x1 odd ?
	beq	    1f              @nop
    ldrh    r0,[r2,#-1]!
    and     r0,r0,#0xFF00
    orr     r0,r0,r3
    strh    r0,[r2]
1:
	tst	    r1,#1			@is x0 odd ?
	beq	    2f              @nop
    ldrh    r0,[r1,#-1]!
    and     r0,r0,#0xFF
    orr     r0,r0,r3,lsl #8
    strh    r0,[r1],#2
2:
    cmp     r2,r1
	ble	    4f      		@if no pixel left to draw, end
	orr	    r3,r3,r3,lsl #8 @write 2 pixels at a time
3:
	strh	r3,[r1],#2
    cmp     r2,r1
	bgt	    3b
4:
    ldmfd   sp!,{r4}
    bx      lr

	.global	fx_twister_line_tex_S
	.type	fx_twister_line_tex_S,%function
@r0 = VRAM line address
@r1 = x0
@r2 = x1
@r3 = uv
fx_twister_line_tex_S:
    stmfd   sp!,{r4-r8}
    subs    r6,r2,r1
    rsbmi   r6,r6,#0
    add     r6,r6,#0x80
    lsr     r6,r6,#8        @l = abs(x1-x0)+0x80 >> 8
    and     r4,r3,#~0xFF    @v = uv & ~0xFF
    and     r3,r3,#0xFF
    lsl     r3,r3,#8        @u = (uv & 0xFF) << 8
    ldr     r5,=twister_div_bin
    add     r5,r5,r6,lsl #1
    ldrh    r5,[r5,#-2]     @uinc = (64 / l) << 8
    tst     r6,#1
    addeq   r3,r3,r5,lsr #1 @if l pair, u += uinc / 2
    add     r6,r6,#4
    and     r6,r6,#7<<3
    add     r4,r4,r6,lsl #13 @v += 256 * 256 * ((l + 4 >> 3) & 7)
    add     r1,r1,#0x80
    add     r2,r2,#0x80
	add	    r1,r0,r1,lsr #8 @start address
	add	    r2,r0,r2,lsr #8 @end address
    ldr     r7,=twister_tex_bin
	tst	    r1,#1			@is x0 odd ?
	beq	    2f              @nop
    ldrh    r0,[r1,#-1]!
    and     r0,r0,#0xFF
    add     r6,r3,#0x80
    add     r6,r4,r6,lsr #8
    ldrb    r6,[r7,r6]      @twister_tex_bin[((u+0x80)>>8)|v]
    add     r3,r3,r5        @u += uinc
    orr     r0,r0,r6,lsl #8
    strh    r0,[r1],#2
2:

    mov     r8,r2
    bic     r8,r8,#1        @make x1 pair
    cmp     r8,r1
	ble	    4f
3:
    add     r6,r3,#0x80
    add     r6,r4,r6,lsr #8
    ldrb    r6,[r7,r6]      @twister_tex_bin[((u+0x80)>>8)|v]
    mov r0,r6,lsr #8
    add     r3,r3,r5        @u += uinc
    add     r0,r3,#0x80
    add     r0,r4,r0,lsr #8
    ldrb    r0,[r7,r0]      @twister_tex_bin[((u+0x80)>>8)|v]
    add     r3,r3,r5        @u += uinc
    and     r6,r6,#0xFF
    orr     r6,r6,r0,lsl #8
	strh	r6,[r1],#2
    cmp     r8,r1
	bgt	    3b
4:
	tst	    r2,#1			@is x1 odd ?
	beq	    1f              @nop
    ldrh    r0,[r2,#-1]!
    and     r0,r0,#0xFF00
    add     r6,r3,#0x80
    add     r6,r4,r6,lsr #8
    ldrb    r6,[r7,r6]      @twister_tex_bin[((u+0x80)>>8)|v]
    orr     r0,r0,r6
    strh    r0,[r2]
1:
    ldmfd   sp!,{r4-r8}
    bx      lr

	.global	fx_twister_clearscreen
	.type	fx_twister_clearscreen,%function
@clear the left half of the screen
@r0 = screen address
fx_twister_clearscreen:
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
1:
	stmia	r0!,{r1-r12}
	stmia	r0!,{r1-r12}
	stmia	r0!,{r1-r6}
    add     r0,#120
	subs	r14,r14,#1
	bne	    1b
	ldmfd	r13!,{r4-r12,lr}
	bx	    lr
