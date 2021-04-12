	.section .iwram,"ax"
    .arm
    .align
    
	.global	fx_twister_clearscreen
	.type	fx_twister_clearscreen,%function
@clear the left half of the screen
@r0 = screen address
fx_twister_clearscreen:
	stmfd	r13!,{r4-r11,lr}
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
	ldmfd	r13!,{r4-r11,lr}
	bx	    lr
