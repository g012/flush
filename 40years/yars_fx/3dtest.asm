fx_init:
	lda #0
	sta CTRLPF
	rts

fx_vblank:
	ldx data_cnt
	dex
	stx tmp5
.blank_loop:
	ldx tmp5
	ldy data_y,x
	lda data_x,x
	tax
	lda frame_cnt
	jsr fx_rot_x
	jsr scale_x
	sta tmp6		; tmp6 = scale_x(rotz_x)
	
	ldx tmp5
	ldy data_y,x
	lda data_x,x
	tax
	lda frame_cnt
	jsr fx_rot_y		; a = rotz_y
	sta tmp7

	ldx tmp5
	ldy data_z,x
	tax
	lda frame_cnt
	jsr fx_rot_x		; a = rotx_x*rotz_y
	jsr scale_y

	tay
	ldx tmp6
	jsr project_point
	
	dec tmp5
	bpl .blank_loop
	rts

fx_kernel:
	lda #$ff
	sta COLUPF
	ldy #(LINES_COUNT*8)-1 ; 4 bytes/line
.next_line:
	sta WSYNC
	tya
	lsr
	and #$fc
	tax
	lda #0
	sta PF0
	lda buffer+0,x
	sta PF1
	lda buffer+1,x
	sta PF2
	SLEEP 10
	lda buffer+2,x
	and #$f0
	sta PF0
	lda buffer+3,x
	sta PF1
	lda buffer+2,x
	and #$0f
	sta PF2
	dey
	cpy #$ff
	bne .next_line

	lda #0
	sta WSYNC
	sta COLUBK
	sta COLUPF
	sta PF0
	sta PF1
	sta PF2
	rts

fx_overscan:
	jsr fx_cleanbuf
	inc frame_cnt
	rts

fx_cleanbuf:
	lda #0
	ldx #(LINES_COUNT*4 - 1)
.cleanloop:
	sta buffer,x
	dex
	bpl .cleanloop
	rts
	
;;; TODO optimize to use only one temporary memory byte
;;; takes x & y fixed point values into x & y registers
;;; x in [0, 31], y in [0, 27]
;;; Alters a, x, y, tmp, tmp1 registers
project_point:
	;; byte in `buffer` is y*4 + x>>3
	tya
	asl
	asl
	sta tmp
	lda pf_map,x
	tax
	lsr
	lsr
	lsr
	ora tmp
	sta tmp

	txa
	and #$07
	tax ; x has the bit index
	
	lda #$80
	cpx #0
	beq .prj_end
.prj_loop:
	lsr
	dex
	bne .prj_loop
.prj_end:
	sta tmp1
	ldx tmp
	lda buffer,x
	ora tmp1
	sta buffer,x
	rts

;;; Angle is in A register
;;; A will have the result: sin(a)
;;; Uses x register
fx_sin:
	and #$7f		; 7 bits ints sin
	tax
	lda sin_table,x
	rts

fx_cos:
	sec
	sbc #32			; a - pi/2
	and #$7f
	tax
	lda sin_table,x
	jsr fx_opposite
	rts

;;; Take value in a reg and returns result in a
fx_opposite:
	eor #$ff
	clc
	adc #1
	rts

;;; Multiply a with x
;;; Uses a, x, y, tmp, tmp1
fx_mul:
	sta tmp			; tmp = a
	;; Compute sign of result
	and #$80
	sta tmp1
	txa
	tay			; y = b
	and #$80
	eor tmp1
	sta tmp1		; tmp1 contains sign

	;; Convert values to opposite when negatives
	lda tmp
	bpl .b_sign
	jsr fx_opposite
	sta tmp
.b_sign:
	tya
	bpl .zero_mul
	jsr fx_opposite
	tay

.zero_mul:
	beq .zero_res 		; y = b = 0
	lda tmp
	bne .do_multiply
.zero_res:
	lda #0
	rts

.do_multiply:
	tax			; x = tmp = a
	lda exp2log_table,x
	sta tmp
	lda exp2log_table,y	; y = b
	clc
	adc tmp
	tax
	lda log2exp_table,x	; a contains the result

	;; return opposite depending on operation sign
	ldx tmp1		; x contains sign
	bne .opposite_res
	rts
.opposite_res:
	jsr fx_opposite
	rts


;;; x, y registers = X, Y values (or any 2 components to rotate)
;;; a = angle in [0, 128[
;;; at exit a contains rotated value of x
;;; res = sin(a)*z + cos(a)*x
;;; Uses a, x, y, tmp, tmp1 registers through fx_mul call
;;; Also needs tmp2, tmp3, tmp4
fx_rot_y:
	stx tmp4		; tmp4 = X value
	sty tmp2		; tmp2 = Y value
	sta tmp3		; tmp3 = angle
	jsr fx_sin		; a = sin(a)
	ldx tmp4		; x = X
	jsr fx_mul
	sta tmp4		; tmp4 = sin(A)*X
	lda tmp3
	jsr fx_cos		; a = cos(A)
	ldx tmp2		; x = Y value
	jsr fx_mul		; a = cos(A)*Y
	clc
	adc tmp4		; a = sin(A)*X + cos(A)*Y
	rts
	
fx_rot_x:
	stx tmp4		; tmp4 = X value
	sty tmp2		; tmp2 = Y value
	sta tmp3		; tmp3 = angle
	jsr fx_cos		; a = cos(A)
	ldx tmp4		; x = X
	jsr fx_mul
	sta tmp4		; tmp4 = cos(A)*X
	lda tmp3
	jsr fx_sin		; a = sin(A)
	ldx tmp2		; x = Y value
	jsr fx_mul		; a = sin(A)*Y
	jsr fx_opposite
	clc
	adc tmp4		; a = cos(A)*X - sin(A)*Y
	rts
	
;;; The value to be scaled must be provided in a register
;;; Uses X register
scale_x:
	clc
	adc #$40
	tax
	lda scalex_table,x
	rts
	
;;; Uses X register
scale_y:
	clc
	adc #$40
	tax
	lda scaley_table,x
	rts

pf_map:
	dc.b $00, $01, $02, $03, $04, $05, $06, $07
	dc.b $0f, $0e, $0d, $0c, $0b, $0a, $09, $08
	dc.b $13, $12, $11, $10, $18, $19, $1a, $1b
	dc.b $1c, $1d, $1e, $1f, $17, $16, $15, $14

data_cnt:
	dc.b 5
	
data_x:
	dc.b 36
	dc.b 36
	dc.b 36
	dc.b 36
	dc.b 220
	dc.b 220
	dc.b 220
	dc.b 220

data_y:
	dc.b 220
	dc.b 220
	dc.b 36
	dc.b 36
	dc.b 0
	dc.b 220
	dc.b 36
	dc.b 36

data_z:
	dc.b 36
	dc.b 220
	dc.b 220
	dc.b 36
	dc.b 0
	dc.b 220
	dc.b 220
	dc.b 36

	INCLUDE "yars_tables.asm"
