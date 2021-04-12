#ifdef MUSIC_NMOD
@**************************************************************************
@           NMOD Player v1 beta for GCC/DEVKITADV by NEiM0D/QTX!
@           ----------------------------------------------------
@1) COPYRIGHT NOTICE
@All libraries and source files inside this SDK are copyright (C) 2002 by
@ NEiM0D.
@
@My permission is required if you want to use this module player in your
@game/demo/tool/other project. Just send me an email with the request.
@Also you are requested to add my name and email address to the project credits
@list.
@
@YOU CANNOT USE THIS PLAYER IN COMMERCIAL/SHAREWARE PROJECT.
@PLEASE CONTACT ME (neimod@hotmail.com) BEFORE ADDING THIS PLAYER IN SUCH A PROJECT.
@I THINK WE WILL FIND A GOOD SOLUTION FOR BOTH SIDES.
@
@2) PROGRAMMERS NOTES:
@
@This is the real thing, written totally from scratch to arm asm!
@Hardcore optimized by yours truly.
@
@
@I've left finetunes out for the time being, maybe I'll add them later
@(It's not that you will notice them anyway)
@
@
@
@3) WARNINGS:
@-This code dynamicly changes its mixing loop code, so this code will
@ NOT WORK IN ROM! Only in iwram or ewram - the code is automaticly copied
@ to iwram for your convenience.
@
@4) OPTIMIZATION:
@-The mixing loop is fully optimized (decrementing source address,
@ upper/lower bits of delta register used for 32bit calculation,
@ it's just finished!)
@-The modplayer tick/period/... updater could be made a bit faster
@ but it wouldn't matter much in speed
@
@5) CONTACT:
@Contact me at: neimod@hotmail.com (don't have a nice email address yet!)
@
@6) GREETINGS:
@
@ -sgstair, exoticorn: You know what you did!
@
@7) SPEED:
@
@ Speed should be about 6.4% average with a normal 125bpm song.
@
@8) PROBLEMS:
@
@ There shouldn't be any problems as far as I know of.
@
@
@*** This message will self-destruct in 5 seconds.
@
@Signed, NEiM0D. On 29th Novembre 2002.
@
@email: neimod@hotmail.com
@**************************************************************************
@Warning: Dirty code ahead :-)
        .ARM
        .ALIGN

        .GLOBL  NMOD_Play
        .GLOBL  NMOD_Stop
        .GLOBL  NMOD_SetMasterVol


        .TYPE   NMOD_Play,function   @ Not always required but useful for .map files
	.ALIGN
ArpeggioTab:
        .word      0x0400,0x03c7
        .word      0x0390,0x035d
        .word      0x032c,0x02ff
        .word      0x02d4,0x02ac
        .word      0x0285,0x0261
        .word      0x023f,0x021e
        .word      0x0200,0x01e3
        .word      0x01c8,0x01ae
SineTab:
        .byte      0x00,0x18,0x31,0x4a
        .byte      0x61,0x78,0x8d,0xa1
        .byte      0xb4,0xc5,0xd4,0xe0
        .byte      0xeb,0xf4,0xfa,0xfd
        .byte      0xff,0xfd,0xfa,0xf4
        .byte      0xeb,0xe0,0xd4,0xc5
        .byte      0xb4,0xa1,0x8d,0x78
        .byte      0x61,0x4a,0x31,0x18
RampTab:
        .byte      0x00,0xff,0xf6,0xee
        .byte      0xe6,0xde,0xd5,0xcd
        .byte      0xc5,0xbd,0xb4,0xac
        .byte      0xa4,0x9c,0x94,0x8b
        .byte      0x83,0x7b,0x73,0x6a
        .byte      0x62,0x5a,0x52,0x4a
        .byte      0x41,0x39,0x31,0x29
        .byte      0x20,0x18,0x10,0x08
	.ALIGN
NMOD_Play:
	stmfd	sp!,{r4-r7}
	ldr	r1,=NMOD_modaddress
	str	r0,[r1]
	add	r1,r0,#952
	sub	r1,r1,#2
	ldrb	r2,[r1],#2
	ldr	r3,=songlength
	strb	r2,[r3]
	mov	r2,#128	@i
	mov	r3,#0	@max patterns
fetch_greatestpattern:
	ldrb	r4,[r1],#1
	cmp	r3,r4
	movlt	r3,r4
	subs	r2,r2,#1
	bne	fetch_greatestpattern
	@behold! r3 is the max pattern
	add	r3,r3,#1	@max_pattern+1
	mov	r3,r3,asl #10	@^^ * 1024
	add	r3,r3,r0
	ldr	r1,=1084
	add	r3,r3,r1	@sampleaddress
	mov	r1,#0	@i
fetch_sampleinfo:
	ldr	r2,=sample_length
	add	r2,r2,r1,asl #1
	add	r4,r0,#42	@module+42
	mov	r5,#30		@
	mul	r6,r1,r5	@r6=i*30
	ldrb	r5,[r4,r6]	@r4=[module+42+i*30]
	mov	r5,r5,asl #9	@<<8 * 2
	add	r4,r4,#1
	ldrb	r7,[r4,r6]	@r6=[module+43+i*30]
	add	r7,r5,r7,asl #1 @* 2 @r4 = sample_length
	strh	r7,[r2]		@save samplelength
	ldr	r2,=sample_address
	add	r2,r2,r1,asl #2
	str	r3,[r2]
	add	r3,r3,r7
	@r4 = module+43
	@r6 = i*30
	add	r4,r4,#1	@module+44
	ldrb	r5,[r4,r6]	@r5=[module+44+i*30]
	ldr	r2,=sample_finetune
	add	r2,r2,r1
	cmp	r5,#7
	strleb	r5,[r2]
	subgt	r5,r5,#16
	strgtb	r5,[r2]

	ldr	r2,=sample_volume
	add	r2,r2,r1
	add	r4,r4,#1	@module+45
	ldrb	r5,[r4,r6]
	strb	r5,[r2]

	add	r4,r4,#1
	ldrb	r5,[r4,r6]	@r5=[module+46+i*30]
	mov	r5,r5,asl #9
	add	r4,r4,#1
	ldrb	r7,[r4,r6]	@47
	add	r5,r5,r7,asl #1
	ldr	r2,=sample_repstart
	add	r2,r2,r1,asl #1
	strh	r5,[r2]

	add	r4,r4,#1
	ldrb	r5,[r4,r6]	@r5=[module+48+i*30]
	mov	r5,r5,asl #9
	add	r4,r4,#1
	ldrb	r7,[r4,r6]	@49
	add	r5,r5,r7,asl #1
	ldr	r2,=sample_replen
	add	r2,r2,r1,asl #1
	strh	r5,[r2]

	add	r1,r1,#1
	cmp	r1,#31
	blt	fetch_sampleinfo
	@init vars
	ldr	r0,=NMOD_period
	mov	r1,#0
	str	r1,[r0,#0x0]
	str	r1,[r0,#0x4]
	str	r1,[r0,#0x8]
	str	r1,[r0,#0xc]
	ldr	r0,=NMOD_tick
	mov	r1,#6
	strb	r1,[r0]
	ldr	r0,=NMOD_speed
	strb	r1,[r0]
	mov	r1,#0
	ldr	r0,=NMOD_row
	strb	r1,[r0]
	ldr	r0,=tickleft
	ldr	r1,=320
	str	r1,[r0]
	ldr	r2,=tempo
	mov	r3,#320
	str	r3,[r2]
	ldr	r2,=mo16tempo
	str	r3,[r2]


	ldr	r2,=pattern
	mov	r3,#0
	strb	r3,[r2]
	ldr	r2,=NMOD_row
	mov	r3,#0
	strb	r3,[r2]

	mov	r0,#0x04000000	@global pointer to..
	add	r1,r0,#0x100	@global pointer to..
	add	r6,r1,#0x100	@global pointer to..

	ldr	r2,=0x9a0f
	strh	r2,[r0,#0x82]
	mov	r2,#0x4200
	strh	r2,[r0,#0x88]
	mov	r2,#0x80
	strh	r2,[r0,#0x84]
	ldr	r2,=-1049
	strh	r2,[r1,#0x0]
	ldr	r2,=-320
	strh	r2,[r1,#0x4]
	mov	r2,#0
	strh	r2,[r6,#0x8]
	ldrh	r2,[r6,#0x0]
	orr	r2,r2,#16
	strh	r2,[r6,#0x0]
	mov	r2,#1
	strh	r2,[r6,#0x8]
	mov	r2,#128
	strh	r2,[r1,#0x2]
	mov	r2,#0xc4
	strh	r2,[r1,#0x6]
	ldmfd	sp!,{r4-r7}
	bx	lr
NMOD_Stop:
	mov	r0,#0x04000000	@global pointer to..
	add	r1,r0,#0x100	@global pointer to..
	add	r12,r1,#0x100	@global pointer to..

	mov	r2,#0
	strh	r2,[r0,#0x82]
	strh	r2,[r0,#0x84]
	strh	r2,[r0,#0xc6]
	strh	r2,[r0,#0xd2]
	strh	r2,[r1,#0x4]
	strh	r2,[r12,#0x8]
	ldrh	r2,[r12,#0x0]
	ldr	r3,=-10
	and	r2,r2,r3
	strh	r2,[r12,#0x0]
	mov	r2,#1
	strh	r2,[r12,#0x8]
	mov	r2,#0
	strh	r2,[r1,#0x2]
	strh	r2,[r1,#0x6]
	bx	lr
NMOD_SetMasterVol:
	ldr	r2,=NMOD_mastervol
	strb	r0,[r2,r1]
	bx	lr
	.SECTION .iwram,"ax",%progbits
        .ARM
        .ALIGN
	.GLOBL	NMOD_Timer1iRQ
IWRAM_MODPLAY_BEGIN:
	@modulus function by neimod! :-)
modulus:
	cmp	r1,#0
	moveq	r0,#0
	moveq	pc,lr
modulus_loop:
	subs	r0,r0,r1
	bge	modulus_loop
	add	r0,r0,r1
	mov	pc,lr

fdiv: @replacement fdiv using 3d's inverse table
@  cmp r1,#0xbb0
@  blt 1f
@  mov r1,#0xbb0
@1:
  ldr r2,=.Linv
  ldr r2,[r2]
  lsl r1,r1,#1
  ldrh r1,[r2,r1]
  mul r2,r0,r1
  lsr r0,r2,#16
  mov pc,r14
  .ltorg
.Linv: .word inverse_table

/*
	@divide routine by Peter Acorn
	@looks like a simple 2^n bit shifter divide
fdiv:
  cmp r1,#1
  beq uo
  mov r2,#0
  cmp r1,r0,lsr#15
  bhi l0_15
  cmp r1,r0,lsr#23
  bhi l16_23
  cmp r1,r0,lsr#27
  bhi l24_27
  cmp r1,r0,lsr#29
  bhi l28_29
  cmp r1,r0,lsr#30
  bhi u30
  b u31
l28_29:
  cmp r1,r0,lsr#28
  bhi u28
  b u29

l24_27:
  cmp r1,r0,lsr#25
  bhi l24_25
  cmp r1,r0,lsr#26
  bhi u26
  b u27
l24_25:
  cmp r1,r0,lsr#24
  bhi u24
  b u25

l16_23:
  cmp r1,r0,lsr#19
  bhi l16_19
  cmp r1,r0,lsr#21
  bhi l20_21
  cmp r1,r0,lsr#22
  bhi u22
  b u23
l20_21:
  cmp r1,r0,lsr#20
  bhi u20
  b u21

l16_19:
  cmp r1,r0,lsr#17
  bhi l16_17
  cmp r1,r0,lsr#18
  bhi u18
  b u19
l16_17:
  cmp r1,r0,lsr#16
  bhi u16
  b u17

l0_15:
  cmp r1,r0,lsr#7
  bhi l0_7
  cmp r1,r0,lsr#11
  bhi l8_11
  cmp r1,r0,lsr#13
  bhi l12_13
  cmp r1,r0,lsr#14
  bhi u14
  b u15
l12_13:
  cmp r1,r0,lsr#12
  bhi u12
  b u13

l8_11:
  cmp r1,r0,lsr#9
  bhi l8_9
  cmp r1,r0,lsr#10
  bhi u10
  b u11
l8_9:
  cmp r1,r0,lsr#8
  bhi u8
  b u9

l0_7:
  cmp r1,r0,lsr#3
  bhi l0_3
  cmp r1,r0,lsr#5
  bhi l4_5
  cmp r1,r0,lsr#6
  bhi u6
  b u7
l4_5:
  cmp r1,r0,lsr#4
  bhi u4
  b u5

l0_3:
  cmp r1,r0,lsr#1
  bhi l0_1
  cmp r1,r0,lsr#2
  bhi u2
  b u3
l0_1:
  cmp r1,r0
  bhi u0
  b u1

u31:
  cmp r0,r1,lsl#30
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#30
u30:
  cmp r0,r1,lsl#29
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#29
u29:
  cmp r0,r1,lsl#28
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#28
u28:
  cmp r0,r1,lsl#27
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#27
u27:
  cmp r0,r1,lsl#26
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#26
u26:
  cmp r0,r1,lsl#25
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#25
u25:
  cmp r0,r1,lsl#24
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#24
u24:
  cmp r0,r1,lsl#23
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#23
u23:
  cmp r0,r1,lsl#22
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#22
u22:
  cmp r0,r1,lsl#21
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#21
u21:
  cmp r0,r1,lsl#20
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#20
u20:
  cmp r0,r1,lsl#19
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#19
u19:
  cmp r0,r1,lsl#18
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#18
u18:
  cmp r0,r1,lsl#17
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#17
u17:
  cmp r0,r1,lsl#16
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#16
u16:
  cmp r0,r1,lsl#15
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#15
u15:
  cmp r0,r1,lsl#14
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#14
u14:
  cmp r0,r1,lsl#13
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#13
u13:
  cmp r0,r1,lsl#12
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#12
u12:
  cmp r0,r1,lsl#11
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#11
u11:
  cmp r0,r1,lsl#10
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#10
u10:
  cmp r0,r1,lsl#9
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#9
u9:
  cmp r0,r1,lsl#8
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#8
u8:
  cmp r0,r1,lsl#7
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#7
u7:
  cmp r0,r1,lsl#6
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#6
u6:
  cmp r0,r1,lsl#5
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#5
u5:
  cmp r0,r1,lsl#4
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#4
u4:
  cmp r0,r1,lsl#3
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#3
u3:
  cmp r0,r1,lsl#2
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#2
u2:
  cmp r0,r1,lsl#1
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#1
u1:
  cmp r0,r1,lsl#0
  adc r2,r2,r2
  subcs r0,r0,r1,lsl#0
u0:
  mov r1,r0
  mov r0,r2
  mov pc,r14
uo:
  mov r1,#0
  mov pc,r14
  */
tick0_effecttable: @0xf effects
	.long	tick0_exit
	.long	tick0_exit
	.long	tick0_exit
	.long	tick0_effect3
	.long	tick0_effect4
	.long	tick0_exit
	.long	tick0_exit
	.long	tick0_effect7
	.long	tick0_exit
	.long	tick0_exit
	.long	tick0_effecta
	.long	tick0_effectb
	.long	tick0_effectc
	.long	tick0_effectd
	.long	tick0_effecte
	.long	tick0_effectf
tick0_exit:
	mov	pc,lr
tick0_effect3:
	@porta_to_period already stored.
	@store porta
	cmp	r9,#0
	ldr	r1,=porta_to_speed
	strneb	r9,[r1,r6]
	ldr	r0,=glissando
	ldrb	r0,[r0]
	@check glissando
	cmp	r0,#0
	beq	skip_glissando
	@r8 is period, if effect was 3, it skipped the new period, thus
	@me need not to worry :)
	ldr	r0,=porta_to_period
	ldr	r0,[r0,r6,asl #2]	@r0=porta_to_period[k]
	ldr	r1,=porta_to_speed
	ldrb	r1,[r1,r6]		@r1=porta_to_speed[k]
	ldr	r2,=NMOD_speed
	ldrb	r2,[r2]			@r2=speed
	cmp	r8,r0
	bgt	note_bigger
note_smaller:
	mul	r2,r1,r2		@r2=speed*porta_to_speed[k]
	add	r8,r8,r2		@period+=r2
	cmp	r8,r0
	movgt	r8,r0
	@save period
	ldr	r0,=NMOD_period
	str	r8,[r0,r6,asl #2]
	mov	r1,r8
	b	porta3_deltacalc
note_bigger:
	mul	r2,r1,r2		@r2=speed*porta_to_speed[k]
	sub	r8,r8,r2		@period+=r2
	cmp	r8,r0
	movlt	r8,r0
	@save period
	ldr	r0,=NMOD_period
	str	r8,[r0,r6,asl #2]
	mov	r1,r8
porta3_deltacalc:
	ldr	r0,=56750
	stmfd	sp!,{lr}
	bl	fdiv
	ldmfd	sp!,{lr}
	ldr	r1,=delta
	str	r0,[r1,r6,asl #2]
skip_glissando:
	mov	pc,lr
tick0_effect4:
	cmp	r10,#0
	beq	skip_vibspeed
	ldr	r1,=vibrato_speed
	strb	r10,[r1,r6]
skip_vibspeed:
	cmp	r11,#0
	beq	skip_vibdep
	ldr	r1,=vibrato_depth
	strb	r11,[r1,r6]
skip_vibdep:
	mov	pc,lr
tick0_effect7:
	ldr	r0,=volume_bak
	ldr	r1,=NMOD_volume
	ldrb	r1,[r1,r6]
	strb	r1,[r0,r6]
	cmp	r10,#0
	beq	skip_tremspeed
	ldr	r1,=tremolo_speed
	strb	r10,[r1,r6]
skip_tremspeed:
	cmp	r11,#0
	beq	skip_tremdep
	ldr	r1,=tremolo_depth
	strb	r11,[r1,r6]
skip_tremdep:
	mov	pc,lr
tick0_effecta:
	mov	pc,lr
tick0_effectb:
	ldr	r0,=NMOD_row
	mov	r1,#0xff	@row=-1
	strb	r1,[r0]
	ldr	r0,=pattern
	ldr	r2,=songlength
	ldrb	r2,[r2]
	cmp	r9,r2
	movge	r9,#0
	strb	r9,[r0]
	mov	pc,lr
tick0_effectc:
	ldr	r1,=NMOD_volume
	strb	r9,[r1,r6]
	mov	pc,lr
tick0_effectd:
	mov	r0,#10
	mul	r0,r10,r0
	add	r0,r0,r11
	sub	r0,r0,#1
	cmp	r0,#63
	movgt	r0,#0
	ldr	r1,=songlength
	ldrb	r12,[r1]
	ldr	r1,=pattern
	ldrb	r2,[r1]
	add	r2,r2,#1
	cmp	r2,r12
	movge	r2,#0
	strb	r2,[r1]
	ldr	r1,=NMOD_row
	strb	r0,[r1]
	mov	pc,lr
tick0_seffecttable:
	.long	tick0_sexit
	.long	tick0_seffect1
	.long	tick0_seffect2
	.long	tick0_seffect3
	.long	tick0_seffect4
	.long	tick0_seffect5
	.long	tick0_seffect6
	.long	tick0_seffect7
	.long	tick0_sexit
	.long	tick0_sexit
	.long	tick0_seffecta
	.long	tick0_seffectb
	.long	tick0_sexit
	.long	tick0_sexit
	.long	tick0_seffecte
	.long	tick0_sexit
tick0_sexit:
	mov	pc,lr
tick0_seffect1:
	cmp	r8,#0
	beq	skip_0seffect1
	subs	r1,r8,r11
	movlt	r1,#1
	ldr	r0,=NMOD_period
	str	r1,[r0,r6,asl #2]
	ldr	r0,=56750
	stmfd	sp!,{lr}
	bl	fdiv
	ldmfd	sp!,{lr}
	ldr	r1,=delta
	str	r0,[r1,r6,asl #2]
skip_0seffect1:
	mov	pc,lr
tick0_seffect2:
	cmp	r8,#0
	beq	skip_0seffect2
	add	r1,r8,r11
	ldr	r0,=NMOD_period
	str	r1,[r0,r6,asl #2]
	ldr	r0,=56750
	stmfd	sp!,{lr}
	bl	fdiv
	ldmfd	sp!,{lr}
	ldr	r1,=delta
	str	r0,[r1,r6,asl #2]
skip_0seffect2:
	mov	pc,lr
tick0_seffect3:
	ldr	r0,=glissando
	strb	r11,[r0]
	mov	pc,lr
tick0_seffect4:
	ldr	r0,=vibrato_form
	cmp	r11,#3
	moveq	r11,#0
	cmp	r11,#7
	movge	r11,#4
	strb	r11,[r0]
	mov	pc,lr
tick0_seffect5:
	cmp	r11,#7
	subgt	r11,r11,#16
	ldr	r0,=sample_finetune
	strb	r11,[r0,r7]
	mov	pc,lr
tick0_seffect6:
	cmp	r11,#0
	bne	bigger_effect			@effecty[k]!=0
smaller_effect:
	ldr	r1,=patlooprow
	strb	r5,[r1]
	b	continue_0seffect6
bigger_effect:
	ldr	r1,=patloopno			@r1=&patloopno
	ldrb	r2,[r1]				@r2=patloopno
	cmp	r2,#0				@if r2 ==0
	moveq	r2,r11				@r2=effecty[k] else
	subne	r2,r2,#1			@r2--
	strb	r2,[r1]				@save patloopno
	cmp	r2,#0				@if patloopno > 0
	ble	continue_0seffect6		@goto ... else
	ldr	r0,=NMOD_row				@r0=&row
	ldr	r1,=patlooprow			@r1=&patlooprow
	ldrb	r1,[r1]				@r1=patlooprow
	sub	r1,r1,#1			@r1--
	strb	r1,[r0]				@save patlooprow
continue_0seffect6:
	mov	pc,lr
tick0_seffect7:
	ldr	r0,=tremolo_form
	cmp	r11,#3
	moveq	r11,#0
	cmp	r11,#7
	movge	r11,#4
	strb	r11,[r0]
	mov	pc,lr
tick0_seffecta:
	cmp	r8,#0
	moveq	pc,lr
	ldr	r0,=NMOD_volume
	ldrb	r1,[r0,r6]
	add	r1,r1,r11
	cmp	r1,#64
	movgt	r1,#64
	strb	r1,[r0,r6]
	mov	pc,lr
tick0_seffectb:
	cmp	r8,#0
	moveq	pc,lr
	ldr	r0,=NMOD_volume
	ldrb	r1,[r0,r6]
	sub	r1,r1,r11
	cmp	r1,#0
	movlt	r1,#0
	strb	r1,[r0,r6]
	mov	pc,lr
tick0_seffecte:
	ldr	r0,=patdelay
	strb	r11,[r0]
	mov	pc,lr
tick0_effecte:
	stmfd	sp!,{lr}
	ldr	r0,=tick0_seffecttable
	ldr	r0,[r0,r10,asl #2]
	mov	lr,pc
	mov	pc,r0
	ldmfd	sp!,{lr}
	mov	pc,lr
tick0_effectf:
	cmp	r9,#0x20
	bgt	set_tempo
set_speed:
	ldr	r0,=NMOD_speed
	strb	r9,[r0]
	b	 effectf_continue
set_tempo:
	mov	r1,r9
	ldr	r0,=40000 @16000*5/2 (bpm calculation with sample rate)
	stmfd	sp!,{lr}
	bl	fdiv
	ldmfd	sp!,{lr}
	@make multiple of 4
	mov	r2,r0,asr #2
	mov	r2,r2,asl #2
	mov	r0,r0,asr #4
	add	r0,r0,#1
	mov	r0,r0,asl #4
	ldr	r3,=tempo
	ldr	r3,[r3]
	cmp	r3,r2
	beq	 effectf_continue

	ldr	r1,=mo16tempo
	str	r0,[r1]
	ldr	r1,=tempo
	str	r2,[r1]


	ldr	r0,=activebuffer	@r0=&activebuffer
	ldrb	r1,[r0]			@r1=activebuffer
	eor	r1,r1,#1		@activebuffer^=1
	strb	r1,[r0]			@save activebuffer
	ldr	r0,=bufferoffset
	mov	r1,#0
	str	r1,[r0]

	ldr	r0,=bufferleft
	ldr	r1,=mo16tempo
	ldr	r1,[r1]
	str	r1,[r0]
	ldr	r0,=bufferleft
	ldr	r1,[r0]
	ldr	r2,=tickleft
	ldr	r3,[r2]
	ldr	r9,=fillbytes
	cmp	r1,r3
	movlt	r10,r1
	movge	r10,r3
	str	r10,[r9]
	sub	r1,r1,r10
	sub	r3,r3,r10
	str	r3,[r2]
	str	r1,[r0]
	cmp	r3,#0
	bne	skippy
	ldr	r3,=tempo
	ldr	r3,[r3]
	str	r3,[r2]
skippy:
	mov	r0,#0x04000000
	ldr	r3,=activebuffer
	ldrb	r3,[r3]
	cmp	r3,#0
	moveq	r2,#1344
	movne	r2,#1344*2
	sub	r2,r2,#4
	mov	r3,#0
	strh	r3,[r0,#0xc6]
	ldr	r3,=NMOD_buffera
	add	r9,r3,r2
	str	r9,[r0,#0xbc]
	add	r3,r0,#0xa0
	str	r3,[r0,#0xc0]
	ldr	r9,=0xb680
	strh	r9,[r0,#0xc6]
	mov	r3,#0
	strh	r3,[r0,#0xd2]
	ldr	r3,=NMOD_bufferb
	add	r10,r3,r2
	str	r10,[r0,#0xc8]
	add	r3,r0,#0xa4
	str	r3,[r0,#0xcc]
	strh	r9,[r0,#0xd2]

	mov	r0,#0x04000000	@global pointer to..
	add	r1,r0,#0x100	@global pointer to..
	add	r9,r1,#0x100	@global pointer to..

	mov	r2,#0
	strh	r2,[r9,#0x8]
	strh	r2,[r1,#0x6]
	ldr	r2,=mo16tempo
	ldr	r2,[r2]
	rsb	r2,r2,#0
	strh	r2,[r1,#0x4]
	mov	r2,#0xc4
	strh	r2,[r1,#0x6]
	mov	r2,#1
	strh	r2,[r9,#0x8]

effectf_continue:
	mov	pc,lr
@non-tick0 effecttable
tick_effecttable: @0xf effects
	.long	tick_effect0
	.long	tick_effect1
	.long	tick_effect2
	.long	tick_effect3
	.long	tick_effect4
	.long	tick_effect5
	.long	tick_effect6
	.long	tick_effect7
	.long	tick_exit
	.long	tick_exit
	.long	tick_effecta
	.long	tick_exit
	.long	tick_exit
	.long	tick_exit
	.long	tick_effecte
	.long	tick_exit
tick_exit:
	mov	pc,lr
arpeggio_tick1:
	@r3=effect+xy
	@r8=period
	@get arpeggiotab[effectx]
	ldr	r0,=ArpeggioTab		@r0=&ArpeggioTab
	mov	r1,r10,asl #1		@
	@r1=effectx
	ldrh	r0,[r0,r1]		@r0=arpeggiotab[effectx]
	mul	r0,r8,r0		@arpeggiotab[effectx]*period
	mov	r1,r0,asr #10		@>>10@ r1= new_period
	ldr	r0,=56750		@
	@regs crushed = r1, r0 & r2
	stmfd	sp!,{lr}
	bl	fdiv
	ldmfd	sp!,{lr}
	ldr	r9,=delta		@r9=&delta
	str	r0,[r9,r6,asl #2]	@save delta[k]
	mov	pc,lr
arpeggio_tick2:
	@r3=effect+xy
	@r8=period
	@get arpeggiotab[effectx]
	ldr	r0,=ArpeggioTab
	mov	r1,r11,asl #1
	@r1=effectx
	ldrh	r0,[r0,r1]
	@r0=ArpeggioTab[effectx]
	mul	r0,r8,r0		@arpeggiotab[effectx]*period
	mov	r1,r0,asr #10		@>>10@ r1= new_period
	ldr	r0,=56750
	@regs crushed = r1, r0 & r2
	stmfd	sp!,{lr}
	bl	fdiv
	ldmfd	sp!,{lr}
	ldr	r9,=delta		@r9=&delta
	str	r0,[r9,r6,asl #2]	@save delta[k]
	mov	pc,lr
tick_effect0:
	@arpeggio
	cmp	r8,#0
	moveq	pc,lr
	ldr	r0,=NMOD_tick
	ldrb	r0,[r0]
	mov	r1,#3
	stmfd	sp!,{lr}
	bl	modulus
	ldmfd	sp!,{lr}
	cmp	r0,#1
	ldr	r1,=arpeggio_tick1
	moveq	pc,r1
	cmp	r0,#2
	ldr	r1,=arpeggio_tick2
	moveq	pc,r1
	mov	pc,lr
tick_effect1:
	cmp	r8,#0
	moveq	pc,lr
	sub	r1,r8,r9
	cmp	r1,#54
	movlt	r1,#54
	ldr	r0,=NMOD_period
	str	r1,[r0,r6,asl #2]
	ldr	r0,=56750
	stmfd	sp!,{lr}
	bl	fdiv
	ldmfd	sp!,{lr}
	ldr	r1,=delta
	str	r0,[r1,r6,asl #2]
	mov	pc,lr
tick_effect2:
	cmp	r8,#0
	moveq	pc,lr

	add	r1,r8,r9
	ldr	r0,=NMOD_period
	str	r1,[r0,r6,asl #2]
	ldr	r0,=56750
	stmfd	sp!,{lr}
	bl	fdiv
	ldmfd	sp!,{lr}
	ldr	r1,=delta
	str	r0,[r1,r6,asl #2]
	mov	pc,lr
tick_effect3:
	cmp	r8,#0
	moveq	pc,lr

	ldr	r0,=glissando
	ldrb	r0,[r0]
	@check glissando
	cmp	r0,#0
	bne	skip_glissando2
	ldr	r0,=porta_to_period
	ldr	r0,[r0,r6,asl #2]	@r0=porta_to_period[k]
	cmp	r0,#0
	beq	skip_glissando2
	ldr	r1,=porta_to_speed
	ldrb	r1,[r1,r6]		@r1=porta_to_speed[k]
	cmp	r8,r0
	bgt	note_bigger2
note_smaller2:
	add	r8,r8,r1		@period+=r1
	cmp	r8,r0
	movgt	r8,r0
	@save period
	ldr	r0,=NMOD_period
	str	r8,[r0,r6,asl #2]
	mov	r1,r8
	b	porta3_deltacalc2
note_bigger2:
	sub	r8,r8,r1		@period+=r1
	cmp	r8,r0
	movlt	r8,r0
	@save period
	ldr	r0,=NMOD_period
	str	r8,[r0,r6,asl #2]
	mov	r1,r8
porta3_deltacalc2:
	ldr	r0,=56750
	stmfd	sp!,{lr}
	bl	fdiv
	ldmfd	sp!,{lr}
	ldr	r1,=delta
	str	r0,[r1,r6,asl #2]
skip_glissando2:
	mov	pc,lr
tick_effect4:
	cmp	r8,#0
	beq	skip_vibrato
	ldr	r0,=vibrato_form
	ldrb	r0,[r0]
	cmp	r0,#0
	ldreq	r1,=SineTab
	cmp	r0,#4
	ldreq	r1,=SineTab
	cmp	r0,#1
	ldreq	r1,=RampTab
	cmp	r0,#5
	ldreq	r1,=RampTab
	cmp	r0,#2
	beq	squaretab
	cmp	r0,#6
	beq	squaretab
	ldr	r2,=vibrato_pos
	ldrb	r2,[r2,r6]
	ldrb	r1,[r1,r2]
	b	vibrato_continue
squaretab:
	mov	r1,#256
vibrato_continue:
	ldr	r0,=vibrato_depth
	ldrb	r0,[r0,r6]
	mul	r1,r0,r1
	mov	r1,r1,asr #7
	ldr	r0,=vibrato_flag
	ldrb	r0,[r0,r6]
	cmp	r0,#0
	addeq	r8,r8,r1
	subne	r8,r8,r1
	ldr	r0,=56750
	mov	r1,r8
	stmfd	sp!,{lr}
	bl	fdiv
	ldmfd	sp!,{lr}
	ldr	r1,=delta
	str	r0,[r1,r6,asl #2]
	ldr	r1,=vibrato_pos
	ldrb	r2,[r1,r6]
	ldr	r4,=vibrato_speed
	ldrb	r4,[r4,r6]
	add	r2,r2,r4
	cmp	r2,#31
	ble	skip_vibposreset
	sub	r2,r2,#32
	ldr	r4,=vibrato_flag
	ldrb	r5,[r4,r6]
	cmp	r5,#0
	moveq	r5,#1
	movne	r5,#0
	strb	r5,[r4,r6]
skip_vibposreset:
	strb	r2,[r1,r6]
skip_vibrato:
	mov	pc,lr
tick_effect5:
	stmfd	sp!,{lr}
	bl	tick_effect3
	bl	tick_effecta
	ldmfd	sp!,{lr}
	mov	pc,lr
tick_effect6:
	stmfd	sp!,{lr}
	bl	tick_effect4
	bl	tick_effecta
	ldmfd	sp!,{lr}
	mov	pc,lr
tick_effect7:
	cmp	r8,#0
	moveq	pc,lr
	ldr	r0,=tremolo_form
	ldrb	r0,[r0]
	cmp	r0,#0
	ldreq	r1,=SineTab
	cmp	r0,#4
	ldreq	r1,=SineTab
	cmp	r0,#1
	ldreq	r1,=RampTab
	cmp	r0,#5
	ldreq	r1,=RampTab
	cmp	r0,#2
	beq	squaretabt
	cmp	r0,#6
	beq	squaretabt
	ldr	r2,=tremolo_pos
	ldrb	r2,[r2,r6]
	ldrb	r1,[r1,r2]		@r1=Sine/Ramp-tab[tremolopos[k]]
	b	tremolo_continue
squaretabt:
	mov	r1,#256
tremolo_continue:
	ldr	r0,=tremolo_depth
	ldrb	r0,[r0,r6]
	mul	r1,r0,r1
	mov	r1,r1,asr #6
	ldr	r0,=tremolo_flag
	ldrb	r0,[r0,r6]
	cmp	r0,#0
	ldr	r0,=volume_bak
	ldrb	r2,[r0,r6]
	addeq	r2,r2,r1
	subne	r2,r2,r1
	cmp	r2,#0
	movlt	r2,#0
	cmp	r2,#64
	movgt	r2,#64
	ldr	r0,=NMOD_volume
	strb	r2,[r0,r6]
	ldr	r1,=tremolo_pos
	ldrb	r2,[r1,r6]
	ldr	r4,=tremolo_speed
	ldrb	r4,[r4,r6]
	add	r2,r2,r4
	cmp	r2,#31
	ble	skip_tremposreset
	sub	r2,r2,#32
	ldr	r4,=tremolo_flag
	ldrb	r5,[r4,r6]
	cmp	r5,#0
	moveq	r5,#1
	movne	r5,#0
	strb	r5,[r4,r6]
skip_tremposreset:
	strb	r2,[r1,r6]
	mov	pc,lr
tick_effecta:
	cmp	r8,#0
	moveq	pc,lr
	ldr	r0,=NMOD_volume
	ldrsb	r1,[r0,r6]
	add	r1,r1,r10
	subs	r1,r1,r11
	movlt	r1,#0
	cmp	r1,#64
	movgt	r1,#64
	ldr	r0,=NMOD_volume
	strb	r1,[r0,r6]
	mov	pc,lr
tick_effecte:
	cmp	r10,#0xc
	beq	tick_seffectc
	cmp	r10,#0xd
	beq	tick_seffectd
	cmp	r10,#0x9
	beq	tick_seffect9
	b	tick_seffect
tick_seffectc:
	cmp	r8,#0
	moveq	pc,lr
	ldr	r1,=NMOD_tick
	ldrb	r1,[r1]
	ldr	r2,=NMOD_volume
	cmp	r11,r1
	movle	r11,#0
	strleb	r11,[r2,r6]
	b	tick_seffect
tick_seffect9:
	cmp	r8,#0
	moveq	pc,lr
	ldr	r0,=NMOD_tick
	ldrb	r0,[r0]
	mov	r1,r11
	stmfd	sp!,{lr}
	bl	modulus
	ldmfd	sp!,{lr}
	cmp	r0,#0
	bne	tick_seffect
	mov	r0,#0
	ldr	r1,=soundpos
	str	r0,[r1,r6,asl #2]
	b	tick_seffect
tick_seffectd:
	cmp	r8,#0
	moveq	pc,lr
	ldr	r1,=NMOD_tick
	ldrb	r1,[r1]
	cmp	r11,r1
	bgt	tick_seffect
	mov	r1,r8
	ldr	r0,=56750
	stmfd	sp!,{lr}
	bl	fdiv
	ldmfd	sp!,{lr}
	ldr	r1,=delta
	str	r0,[r1,r6,asl #2]
tick_seffect:
	mov	pc,lr
Resample_MOD:
	mov	r0,#0x04000000
	ldrh	r1,[r0,#0x6]
	stmfd	sp!,{r1}
	stmfd	sp!,{lr}
	@switch activebuffer
	ldr	r0,=activebuffer	@r0=&activebuffer
	ldrb	r1,[r0]			@r1=activebuffer
	eor	r1,r1,#1		@activebuffer^=1
	strb	r1,[r0]			@save activebuffer
	ldr	r0,=bufferoffset
	mov	r1,#0
	str	r1,[r0]

	ldr	r0,=bufferleft
	ldr	r1,=mo16tempo
	ldr	r1,[r1]
	str	r1,[r0]
while_bufferleft:
	ldr	r0,=bufferleft
	ldr	r1,[r0]
	ldr	r2,=tickleft
	ldr	r3,[r2]
	ldr	r4,=fillbytes
	cmp	r1,r3
	movlt	r5,r1
	movge	r5,r3
	str	r5,[r4]
	sub	r1,r1,r5
	sub	r3,r3,r5
	str	r3,[r2]
	str	r1,[r0]
	cmp	r3,#0
	bne	mix_samples
	ldr	r3,=tempo
	ldr	r3,[r3]
	str	r3,[r2]
	@check tick position
	ldr	r0,=NMOD_speed		@r0=&speed
	ldrb	r0,[r0]			@r0=speed
	ldr	r1,=NMOD_tick		@r1=&tick
	ldrb	r2,[r1]			@r2=tick
	add	r2,r2,#1		@tick++
	strb	r2,[r1]			@save tick
	cmp	r2,r0			@if (tick<speed)
	blt	nontick0_update		@goto nontick0_update else
	@check patterndelay
	mov	r2,#0			@tick=0@
	strb	r2,[r1]			@save tick
	ldr	r0,=patdelay		@r0=&patdelay
	ldrb	r1,[r0]			@r1=patdelay
	cmp	r1,#0			@if (patdelay!=0)
	subne	r1,r1,#1		@patdelay--
	strneb	r1,[r0]			@save patdelay
	bne	mix_samples		@goto mix_samples else
	@check row
	ldr	r0,=pattern		@r0=&pattern
	ldrb	r1,[r0]			@r1=pattern
	ldr	r2,=NMOD_row			@r2=&row
	ldrsb	r3,[r2]			@r3=row
	cmp	r3,#63			@if (row <= 63)
	ble	skip_row		@goto skip_row else

	mov	r3,#0			@row=0
	strb	r3,[r2]			@save row
	add	r1,r1,#1		@pattern++
	ldr	r4,=songlength		@r4=&songlength
	ldrb	r4,[r4]			@r4=songlength
	cmp	r1,r4			@if (pattern >= songlength)
	movge	r1,#0			@pattern=0
	strb	r1,[r0]			@save pattern
	@reglist:
	@r0=address of pattern
	@r1=pattern
	@r2=address of row
	@r3=row
skip_row:
	ldr	r4,=NMOD_modaddress		@r4=&module
	ldr	r4,[r4]			@r4=moduleaddress
	add	r4,r4,#952		@moduleaddress+=952
	ldrb	r4,[r4,r1]		@r4=[moduleaddr+pattern]
	ldr	r5,=NMOD_pattern
	strb	r4,[r5]

	@backup row and pattern for use with channels
	@NOTE TO SELF:loop globals! don't change these in the loop
	mov	r4,r1			@r4=pattern
	mov	r5,r3			@r5=row

	mov	r6,#3			@k=3
update_tick0:
	@fetch instrument[k] and period[k] for use with effects
	ldr	r7,=NMOD_instrument		@r7=&instrument
	ldrb	r7,[r7,r6]		@r7=instrument[k]
	ldr	r8,=NMOD_period		@r8=&period
	ldr	r8,[r8,r6,asl #2]	@r8=period[k]

	ldr	r1,=delta		@r1=&delta
	ldr	r1,[r1,r6,asl #2]	@r1=delta[k]
	@available regs:
	@r9, r10, r11, r12

	ldr	r9,=NMOD_modaddress		@r9=&module
	ldr	r9,[r9]
	add	r10,r9,#952		@r10=r9+952
	ldrb	r10,[r10,r4]		@r10=patterndata[patternbak]
	add	r10,r9,r10,asl #10	@r10=patterndata[patbak]*1024+&module
	ldr	r11,=1084		@r11=1084
	add	r10,r10,r11		@r10+=1084
	add	r10,r10,r5,asl #4 	@r10+=rowbak*16
	add	r10,r10,r6,asl #2 	@r10+=k*4
	@available: r9, r11, r12

	ldrb	r9,[r10,#0x0]		@r9=[r10]
	and	r9,r9,#0xf		@r9&=0xf
	mov	r9,r9,asl #8		@r9<<=8
	ldrb	r11,[r10,#0x1]		@r11=[r10+1]
	add	r9,r9,r11		@r9+=r11 => r9=period_cur
	ldrb	r11,[r10,#0x0]		@r11=[r10]
	and	r11,r11,#0xf0		@r11&=0xf0
	ldrb	r12,[r10,#0x2]		@r12=[r10+2]
	adds	r11,r11,r12,asr #4 	@r11+=(r12>>4) => r11=instrument_cur
	ldrb	r3,[r10,#0x2]
	and	r3,r3,#0x0f
	ldrb	r12,[r10,#0x3]
	add	r3,r12,r3,asl #8	@r3=effect+xy
	ldr	r10,=NMOD_effect
	str	r3,[r10,r6,asl #2]
	@available: r10
	beq	skip_volume
	sub	r10,r11,#1
	ldr	r12,=last_ins
	strb	r10,[r12,r6]
	ldr	r12,=sample_volume
	ldrb	r10,[r12,r10]
	ldr	r12,=NMOD_volume
	strb	r10,[r12,r6]
skip_volume:
	cmp	r9,#0
	beq	skip_period		@if (period_cur==0) goto skip_period

	ldr	r12,=vibrato_form
	ldrb	r12,[r12]
	cmp	r12,#4
	blt	skip_vibwavereset
	ldr	r12,=vibrato_pos
	mov	r10,#0
	strb	r10,[r12,r6]
	ldr	r12,=vibrato_flag
	strb	r10,[r12,r6]
skip_vibwavereset:
	ldr	r12,=tremolo_form
	ldrb	r12,[r12]
	cmp	r12,#4
	blt	skip_tremwavereset
	ldr	r12,=tremolo_pos
	mov	r10,#0
	strb	r10,[r12,r6]
	ldr	r12,=tremolo_flag
	strb	r10,[r12,r6]
skip_tremwavereset:
	@available: r10, r11, r12
	ldr	r12,=last_ins
	ldr	r10,=NMOD_instrument
	ldrb	r12,[r12,r6]
	strb	r12,[r10,r6]

	mov	r10,r3,asr #8		@get effect
	cmp	r10,#3			@if effect==3
	@this means period_cur is not 0, so no need to check it again
	beq	effect3_init
	cmp	r10,#9
	bne	skip_sampleskip
	and	r10,r3,#0xff
	mov	r10,r10,asl #16
	ldr	r11,=soundpos
	str	r10,[r11,r6,asl #2]
	b	skip_soffreset
skip_sampleskip:
	ldr	r10,=soundpos		@r10=&soundpos
	mov	r11,#0			@r11=0
	str	r11,[r10,r6,asl #2]	@save 0 to soundpos[k]
skip_soffreset:
	@available: r10, r11, r12
	@period is !=0 so, save period_cur to period
	ldr	r10,=NMOD_period		@r10=&period
	str	r9,[r10,r6,asl #2]	@save period_cur to period[k]
	mov	r8,r9			@r8=period
	@available r9, r10, r11, r12

	@calculating the delta
	@delta[k]=28375*DivTab[(period[k]+finetune[instrument[k]])>>1]>>18
	@delta[k]=(56750/period[k]+finetune)>>8
	mov	r0,r3,asr #4
	and	r0,r0,#0xff
	cmp	r0,#0xed
	beq	skip_period
	ldr	r0,=56750
	mov	r1,r8
	@regs crushed = r1, r0 & r2
	bl	fdiv
	ldr	r9,=delta		@r9=&delta
	str	r0,[r9,r6,asl #2]	@save delta[k]
	b	skip_period
effect3_init:
	@get period_cur[k] for the "porta to note" value
	@and save
	@r9 = period_cur[k]
	ldr	r12,=porta_to_period
	str	r9,[r12,r6,asl #2]
skip_period:
	mov	r12,r3,asr #8		@r12=effect[k]
	ldr	r11,=tick0_effecttable
	ldr	r12,[r11,r12,asl #2]
	@load effectx, effecty, effectxy
	and	r9,r3,#0xff
	and	r11,r3,#0xf
	mov	r10,r3,asr #4
	and	r10,r10,#0xf
	mov	lr,pc
	mov	pc,r12
effect0_jumpback:
	subs	r6,r6,#1
	bge	update_tick0
@	add	r6,r6,#1
@	cmp	r6,#3
@	ble	update_tick0
	ldr	r0,=NMOD_row
	ldrb	r1,[r0]
	add	r1,r1,#1
	strb	r1,[r0]
	b	mix_samples
nontick0_update:
	mov	r6,#3
nontick0_loop:
	ldr	r7,=NMOD_instrument		@r7=&instrument
	ldrb	r7,[r7,r6]		@r7=instrument[k]
	ldr	r8,=NMOD_period		@r8=&period
	ldr	r8,[r8,r6,asl #2]	@r8=period[k]
	ldr	r1,=delta		@r1=&delta
	ldr	r1,[r1,r6,asl #2]	@r1=delta[k]
	ldr	r3,=NMOD_effect
	ldr	r3,[r3,r6,asl #2]
	mov	r12,r3,asr #8		@r12=effect[k]
	ldr	r11,=tick_effecttable
	ldr	r12,[r11,r12,asl #2]
	and	r9,r3,#0xff
	and	r11,r3,#0xf
	mov	r10,r3,asr #4
	and	r10,r10,#0xf
	mov	lr,pc
	mov	pc,r12
effect_jumpback:
	subs	r6,r6,#1
	bge	nontick0_loop
mix_samples:
	@r0=bufferoffset
	mov	r2,#0
__mix_next:
	stmfd	sp!,{r2}
	ldr	r0,=activebuffer	@r0=&activebuffer
	ldrb	r0,[r0]			@r0=activebuffer
	cmp	r0,#0			@if (activebuffer!=0)
	moveq	r0,#1344
	movne	r0,#1344*2		@r0=1344 else r0=0
	sub	r0,r0,#4
	cmp	r2,#0
	ldreq	r1,=NMOD_buffera		@r1=&buffera
	ldrne	r1,=NMOD_bufferb
	add	r0,r1,r0		@r0=&buffera+activebuffer*1344
	ldr	r1,=bufferoffset
	ldr	r1,[r1]
	sub	r0,r0,r1
	ldr	r1,=fillbytes
	ldr	r1,[r1]
	sub	r1,r1,#4
	sub	r0,r0,r1
	@init registers with sample info for a 2 channel mix
	ldr	r14,=NMOD_instrument
	cmp	r2,#0
	ldreqb	r12,[r14,#0*1]
	ldreqb	r14,[r14,#3*1]
	ldrneb	r12,[r14,#1*1]
	ldrneb	r14,[r14,#2*1]
	ldr	r11,=sample_address
	ldr	r3,[r11,r12,asl #2]
	ldr	r8,[r11,r14,asl #2]
	ldr	r7,=sample_replen
	ldr	r4,=sample_repstart
	ldr	r9,=sample_length
	mov	r12,r12,asl #1
	mov	r14,r14,asl #1
	ldrh	r5,[r7,r12]
	ldrh	r10,[r7,r14]
	cmp	r5,#2
	ldrgth	r6,[r4,r12]
	movgt	r6,r6,asl #8
	addgt	r6,r6,r5,asl #8
	ldrleh	r6,[r9,r12]
	movle	r6,r6,asl #8
	cmp	r10,#2
	ldrgth	r11,[r4,r14]
	movgt	r11,r11,asl #8
	addgt	r11,r11,r10,asl #8
	ldrleh	r11,[r9,r14]
	movle	r11,r11,asl #8
	ldr	r14,=delta
	cmp	r2,#0
	ldreq	r4,[r14,#0*4]
	ldreq	r9,[r14,#3*4]
	ldrne	r4,[r14,#1*4]
	ldrne	r9,[r14,#2*4]
	mov	r4,r4,asl #16
	mov	r9,r9,asl #16
	ldr	r14,=stack_save
	str	sp,[r14]
	ldr	r14,=NMOD_volume

	cmp	r2,#0
	ldreqb	r7,[r14,#0*1]
	ldreqb	r12,[r14,#3*1]
	ldrneb	r7,[r14,#1*1]
	ldrneb	r12,[r14,#2*1]
	ldr	sp,=NMOD_mastervol
	ldreqb	lr,[sp,#0*1]
	ldreqb	sp,[sp,#3*1]
	ldrneb	lr,[sp,#1*1]
	ldrneb	sp,[sp,#2*1]
	rsb	lr,lr,#64
	rsb	sp,sp,#64
	sub	r7,r7,lr
	sub	r12,r12,sp
	cmp	r7,#64
	movgt	r7,#64
	cmp	r12,#64
	movgt	r12,#64
	cmp	r7,#0
	movlt	r7,#0
	cmp	r12,#0
	movlt	r12,#0
	add	r4,r4,r7
	add	r9,r9,r12
	ldr	r14,=soundpos
	cmp	r2,#0
	ldreq	sp,[r14,#0*4]
	ldreq	r14,[r14,#3*4]
	ldrne	sp,[r14,#1*4]
	ldrne	r14,[r14,#2*4]

	cmp	r5,#2
	ldrle	r12,=0xa3a02000
	ldrgt	r12,=0xa04dd405
	__a_ = dynamic_code
	__b_ = dynamic_code_3
	__c_ = dynamic_code_5
	__d_ = dynamic_code_7
	ldr	r7,=__a_
	str	r12,[r7]
	ldr	r7,=__b_
	str	r12,[r7]
	ldr	r7,=__c_
	str	r12,[r7]
	ldr	r7,=__d_
	str	r12,[r7]
	cmp	r10,#2
	ldrle	r12,=0xa3a02000
	ldrgt	r12,=0xa04ee40a
	__e_ = dynamic_code_2
	__f_ = dynamic_code_4
	__g_ = dynamic_code_6
	__h_ = dynamic_code_8


	ldr	r7,=__e_
	str	r12,[r7]
	ldr	r7,=__f_
	str	r12,[r7]
	ldr	r7,=__g_
	str	r12,[r7]
	ldr	r7,=__h_
	str	r12,[r7]
mix_samples_loop:
	mov	r2,r13,asr #8		@r2=soundpos[0]>>12
	ldrsb	r2,[r3,r2]		@temp=sample_adr[instrument]+soundpos>>12
	add	r13,r13,r4,asr #16		@soundpos+=delta
	cmp	r13,r6			@if (soundpos<r6)
dynamic_code:
	.long	0x00000000		@dynamic code :)
	@this will be 1 of these below
	@subgt r13,r13,r5,asl #8
	@movle r2,#0
	@subgt r14,r14,r10,asl #8
	mul	r7,r4,r2

	mov	r2,r14,asr #8		@r2=soundpos[0]>>12
	ldrsb	r2,[r8,r2]		@temp=sample_adr[instrument]+soundpos>>12
	add	r14,r14,r9,asr #16		@soundpos+=delta
	cmp	r14,r11			@if (soundpos<r6)
dynamic_code_2:
	.long	0x00000000		@dynamic code
	mul	r2,r9,r2
	add	r7,r7,r2
	mov	r2,r7,asr #7
	mov	r2,r2,lsl #24
	mov	r12,r2,lsr #24
	mov	r2,r13,asr #8		@r2=soundpos[0]>>12
	ldrsb	r2,[r3,r2]		@temp=sample_adr[instrument]+soundpos>>12
	add	r13,r13,r4,asr #16		@soundpos+=delta
	cmp	r13,r6			@if (soundpos<r6)
dynamic_code_3:
	.long	0x0
	mul	r7,r4,r2
	mov	r2,r14,asr #8		@r2=soundpos[0]>>12
	ldrsb	r2,[r8,r2]		@temp=sample_adr[instrument]+soundpos>>12
	add	r14,r14,r9,asr #16		@soundpos+=delta
	cmp	r14,r11			@if (soundpos<r6)
dynamic_code_4:
	.long	0x0
	mul	r2,r9,r2
	add	r7,r7,r2
	mov	r2,r7,asr #7
	mov	r2,r2,lsl #24
	add	r12,r12,r2,lsr #16
	mov	r2,r13,asr #8		@r2=soundpos[0]>>12
	ldrsb	r2,[r3,r2]		@temp=sample_adr[instrument]+soundpos>>12
	add	r13,r13,r4,asr #16		@soundpos+=delta
	cmp	r13,r6			@if (soundpos<r6)
dynamic_code_5:
	.long	0x0
	mul	r7,r4,r2
	mov	r2,r14,asr #8		@r2=soundpos[0]>>12
	ldrsb	r2,[r8,r2]		@temp=sample_adr[instrument]+soundpos>>12
	add	r14,r14,r9,asr #16		@soundpos+=delta
	cmp	r14,r11			@if (soundpos<r6)
dynamic_code_6:
	.long	0x0
	mul	r2,r9,r2
	add	r7,r7,r2
	mov	r2,r7,asr #7
	mov	r2,r2,lsl #24
	add	r12,r12,r2,lsr #8
	mov	r2,r13,asr #8		@r2=soundpos[0]>>12
	ldrsb	r2,[r3,r2]		@temp=sample_adr[instrument]+soundpos>>12
	add	r13,r13,r4,asr #16		@soundpos+=delta
	cmp	r13,r6			@if (soundpos<r6)
dynamic_code_7:
	.long	0x0
	mul	r7,r4,r2
	mov	r2,r14,asr #8		@r2=soundpos[0]>>12
	ldrsb	r2,[r8,r2]		@temp=sample_adr[instrument]+soundpos>>12
	add	r14,r14,r9,asr #16		@soundpos+=delta
	cmp	r14,r11			@if (soundpos<r6)
dynamic_code_8:
	.long	0x0
	mul	r2,r9,r2
	add	r7,r7,r2
	mov	r2,r7,asr #7
	mov	r2,r2,lsl #24
	add	r12,r12,r2
	str	r12,[r0,r1]
	subs	r1,r1,#4
	bge	mix_samples_loop

	mov	r1,sp
	ldr	r0,=stack_save
	ldr	sp,[r0]
	ldmfd	sp!,{r2}
	ldr	r0,=soundpos
	cmp	r2,#0
	streq	r1,[r0,#0*4]
	streq	r14,[r0,#3*4]
	addeq	r2,r2,#1
	beq	__mix_next
	strne	r1,[r0,#1*4]
	strne	r14,[r0,#2*4]


	ldr	r0,=bufferoffset
	ldr	r1,=fillbytes
	ldr	r2,[r0]
	ldr	r3,[r1]
	add	r2,r2,r3
	str	r2,[r0]
	ldr	r0,=bufferleft
	ldr	r1,[r0]
	cmp	r1,#0
	bne	while_bufferleft
__scanline__:
	ldmfd	sp!,{lr}
	ldmfd	sp!,{r1}
	mov	r0,#0x04000000
	ldrh	r0,[r0,#0x6]
	cmp	r0,r1
	blt	scanline_reset
	sub	r1,r0,r1
	b	scanline_save
scanline_reset:
	rsb	r1,r1,#228
	add	r1,r1,r0
scanline_save:
	ldr	r0,=usage
	ldr	r2,[r0]
	add	r2,r2,r1
	str	r2,[r0]
	mov	pc,lr
	.pool
NMOD_Timer1iRQ:
	@the GBA bios permits you to change registers r0,r1,r2,r12
	@so, save the rest of registers before using them.
	stmfd	sp!,{r4-r11} @r3 doesn't need to be saved neither, at least with libgba's handler
	ldr	r1,=mo16tempo
	ldr	r1,[r1]
	ldr	r0,=262160000
	stmfd	sp!,{lr}
	bl	fdiv
	ldmfd	sp!,{lr}
	mov	r0,r0,asr #14
	ldr	r1,=usage_count
	ldr	r2,[r1]
	cmp	r2,r0
	movge	r2,#0
	addlt	r2,r2,#1
	str	r2,[r1]
	ldr	r1,=usage
	ldr	r3,[r1]
	ldr	r4,=NMOD_scanlines
	strge	r3,[r4]
	strge	r2,[r1]

	mov	r0,#0x04000000
	ldr	r3,=activebuffer
	ldrb	r3,[r3]
	cmp	r3,#0
	moveq	r2,#1344
	movne	r2,#1344*2
	sub	r2,r2,#4
	mov	r3,#0
	strh	r3,[r0,#0xc6]
	ldr	r3,=NMOD_buffera
	add	r4,r3,r2
	str	r4,[r0,#0xbc]
	add	r3,r0,#0xa0
	str	r3,[r0,#0xc0]
	ldr	r4,=0xb680
	strh	r4,[r0,#0xc6]
	mov	r3,#0
	strh	r3,[r0,#0xd2]
	ldr	r3,=NMOD_bufferb
	add	r5,r3,r2
	str	r5,[r0,#0xc8]
	add	r3,r0,#0xa4
	str	r3,[r0,#0xcc]
	strh	r4,[r0,#0xd2]
	stmfd	sp!,{lr}
	bl	Resample_MOD
	ldmfd	sp!,{lr}
	ldmfd	sp!,{r4-r11}
	mov	pc,lr
	.pool

	.section .sbss
	.GLOBL	NMOD_buffera
	.GLOBL	NMOD_bufferb
	.GLOBL	NMOD_speed
	.GLOBL	NMOD_tick
	.GLOBL	NMOD_mastervol
	.GLOBL	NMOD_period
	.GLOBL	NMOD_instrument
	.GLOBL	NMOD_effect
	.GLOBL	NMOD_modaddress
	.GLOBL	NMOD_volume
	.GLOBL	NMOD_scanlines
	.GLOBL	NMOD_pattern
	.GLOBL	NMOD_row
NMOD_buffera:	.space 2688
NMOD_bufferb:	.space 2688
sample_length:	.space 62
sample_volume:	.space 31
songlength:	.space 1
activebuffer:	.space 1
NMOD_speed:	.space 1
sample_repstart:	.space 62
sample_replen:	.space 62
sample_address:	.space 124
sample_finetune:	.space 31
NMOD_tick:	.space 1
tempo:	.space 4
mo16tempo:	.space 4
NMOD_mastervol:	.space 4
soundpos:	.space 16
NMOD_period:	.space 16
NMOD_instrument:	.space 4
NMOD_effect:	.space 16
delta:	.space 16
porta_to_period:	.space 16
porta_to_speed:	.space 4
NMOD_modaddress:	.space 4
vibrato_pos:	.space 4
vibrato_flag:	.space 4
vibrato_depth:	.space 4
vibrato_speed:	.space 4
tremolo_pos:	.space 4
tremolo_flag:	.space 4
tremolo_depth:	.space 4
tremolo_speed:	.space 4
NMOD_volume:	.space 4
bufferleft:	.space 4
tickleft:	.space 4
fillbytes:	.space 4
bufferoffset:	.space 4
usage:	.space 4
NMOD_scanlines:	.space 4
usage_count:	.space 4
stack_save:	.space 4
last_ins:	.space 4
patlooprow:	.space 1
patdelay:	.space 1
patloopno:	.space 1
vibrato_form:	.space 1
tremolo_form:	.space 1
glissando:	.space 1
volume_bak:	.space 4
pattern:	.space 1
NMOD_pattern:	.space 1
NMOD_row:	.space 1
#endif
