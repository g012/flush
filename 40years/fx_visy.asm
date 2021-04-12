	INCLUDE "data/dancer.inc"

pic_h = 244
scr_h = 122

fx_visy_init:
	lda #0
	sta CTRLPF
	sta scroll
	lda #92-16
	sta bgtime
	lda #0
	sta scroll_dir
	sta time
    sta framecnt
	lda #pic_h
	sta scroll_end
	jmp RTSBank

fx_visy_vblank:	
	lda framecnt
	cmp #128
	bne .no_time
	lda bgtime
	clc
	adc #16
	sta bgtime

	lda #0
	sta framecnt
	lda time
	clc
	adc #1
	and #3
	sta time

.no_time:
	and #127
	tax
	lda sintab,x
	sta scroll
	clc
	adc #117
	sta scroll_end

  ;set up colptr
  ;time = 1 -> coltab
  ;time = 3 -> coltab2
  lda time
  and #2
  bne .setup_coltab2
  SET_POINTER colptr, coltab
  jmp .done_coltab
.setup_coltab2:
  SET_POINTER colptr, coltab2
.done_coltab:

	ldx #0
	lda #71
	jsr PositionObjecttt

	lda time
	cmp #1
	bne .no_blond
	lda #$3e
	sta haircolor
	jmp .hairdone
.no_blond:
	lda #0
	sta haircolor
.hairdone:

	jmp RTSBank

fx_visy_kernel:
	lda time
  and #1
	bne .main_time  ;time = 1 or 3

.intro_outro_time:

.intro_time:
	lda #1
	sta COLUBK
  ;could use X or Y
	ldx #68

	sta WSYNC
.intro_line2:
	;ora #92
	;ora #71
	lda coltab,x
	;sbc time
	sta WSYNC
	ora framecnt
	sta COLUBK
	and #1
	sta COLUPF

	lda dancer_pf0,x
	sta PF0
	lda dancer_pf1,x
	sta PF1
	lda dancer_pf2,x
	sta PF2
	lda dancer_pf3,x
	sta PF0
	lda dancer_pf4,x
	sta PF1
	lda dancer_pf5,x
	sta PF2

  SLEEP 36

	lda dancer_pf0,x
	sta PF0
	lda dancer_pf1,x
	sta PF1
	lda dancer_pf2,x
	sta PF2
	lda dancer_pf3,x
	sta PF0
	lda dancer_pf4,x
	sta PF1
	lda dancer_pf5,x
	sta PF2


  inx
	cpx #185
	bne .intro_line2
	beq .done

.main_time:
	lda #%00000111
	sta NUSIZ0
	
	lda #1
	sta COLUBK
	ldx #0
  ;must use Y due to (colptr),Y
	ldy scroll

	sta WSYNC
	sta HMOVE
.next_line2:
	;ora #92
	;ora #71
	lda (colptr),Y
	sta WSYNC
	sta COLUBK
	tya
	ora bgtime
	sta COLUPF

	lda dancer_pf0,Y
	sta PF0
	lda dancer_pf1,Y
	sta PF1
	lda dancer_pf2,Y
	sta PF2
	lda dancer_pf3,Y
	sta PF0
	lda dancer_pf4,Y
	sta PF1
	lda dancer_pf5,Y
	sta PF2


	lda haircolor
	sta COLUP0

	txa
	pha
	adc scroll
	tax

	cpx #88
	bcs .no_sprite

	lda sprite,x
	sta GRP0

	jmp .skip
.no_sprite:
	SLEEP 8

.skip:

	lda dancer_pf0,Y
	sta PF0
	lda dancer_pf1,Y
	sta PF1
	lda dancer_pf2,Y
	sta PF2
	lda dancer_pf3,Y
	sta PF0
	lda dancer_pf4,Y
	sta PF1
	lda dancer_pf5,Y
	sta PF2

	pla
	tax

	inx
	iny
	cpy scroll_end
	bne .next_line2

.done:
	sta WSYNC
	lda #0
	sta PF2
	sta PF0
	sta PF1
	sta COLUBK
	sta COLUPF

fx_visy_overscan:   ;re-use RTS
	jmp RTSBank


PositionObjecttt
    clc
    sta WSYNC
DivideLooppp
    sbc #15
    bcs DivideLooppp
#if >DivideLooppp - >*
    echo "DivideLooppp not aligned"
    ERR
#endif
    eor #7
    asl
    asl
    asl
    asl
    sta HMP0,X
    sta RESP0,X
    rts


;.align = $100  not how you align on dasm.. but also doesn't seem to be needed /Tjoppen
coltab:
	.byte 60,60,60,15,15,67+35,67+35,67+35,68+35,68+35,69+35,69+35,70+35,70+35,71+35,71+35,72+35,72+35
	.byte 60,60,60,15,15,67,67,67
	REPEAT 45
	.byte 106
	REPEND
	REPEAT 20
	.byte 10
	.byte 10
	.byte 0
	.byte 0
	REPEND
	REPEAT 45
	.byte 106
	REPEND
	REPEAT 46
	.byte 0
	REPEND

coltab2:
	.byte 60,60,60,15,15,$40,$40,$40,$41,$41,$42,$42,$43,$43,$44,$44,$45,$45
	.byte 60,60,60,15,15,67,67,67
	REPEAT 45
	.byte $40
	REPEND
	REPEAT 20
	.byte $68
	.byte $68
	.byte $A8
	.byte $A8
	REPEND
	REPEAT 45
	.byte $40
	REPEND
	REPEAT 46
	.byte 2
	REPEND
sintab:
	.byte 64,67,70,73,76,79,82,85,88,91,93,96,99,101,104,106,108,111,113,115,116,118,120,121,122,123,124,125,126,126,127,127,127,127,127,126,126,125,124,123,122,121,120,118,116,115,113,111,108,106,104,101,99,96,93,91,88,85,82,79,76,73,70,67,64,60,57,54,51,48,45,42,39,36,34,31,28,26,23,21,19,16,14,12,11,9,7,6,5,4,3,2,1,1,0,0,0,0,0,1,1,2,3,4,5,6,7,9,11,12,14,16,19,21,23,26,28,31,34,36,39,42,45,48,51,54,57,60,64


sprite:
	REPEAT 35
	.byte 0
	REPEND
	.byte %00011000
	.byte %00111100
	.byte %11111110
	.byte %01111110
	.byte %01000010
	.byte %11000010
	.byte %11000010
	.byte %11000010
	.byte %01000010
	.byte %01000010
	.byte %10000001
	.byte %10000001
	.byte %10000001
	.byte %11000011
	.byte %11000011
	.byte %11000011
	.byte %10000001
	.byte %10000001
	.byte %10000001
	.byte %01000010
	.byte %01000010
	.byte %01000010
	.byte %10000001
	.byte %10000001
	.byte %01000010
	.byte %01000010
	.byte %00100100
	.byte %00100100
	.byte %00000000
	REPEAT 100
	.byte 0
	REPEND
