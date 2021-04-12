fx_40years_init SUBROUTINE
	; Quad size players
	lda #$07
	sta NUSIZ0
	lda #$00
	sta REFP0 ; No reflexion
	sta ENAM0 ; No missile 0
	sta ENAM1 ; No missile 1
	sta GRP1 ; No player 1
	sta COLUBK ; Black background

	; Position Sprite 0 for the cartridge
	sta WSYNC
	ldy #7
.rough_loop
	dey
	bpl .rough_loop
	sta RESP0
	lda #$60
	sta HMP0
	sta WSYNC
	sta HMOVE
	jmp RTSBank

fx_40years_vblank:
	; Initialize background pointer
	lda framecnt
	and #$3F
	tay
	lda pix_bgsin,Y
	clc
	adc #<pix_bgcol_upper
	sta bg_ptr
	lda #$00
	adc #>pix_bgcol_upper
	sta bg_ptr+1
	jmp RTSBank

fx_40years_overscan:
	jmp RTSBank

fx_40years_kernel SUBROUTINE
	clc
	ldy #(112-1)
.upper_loop:
	lda (bg_ptr),y
	sta WSYNC
	sta COLUBK
	lda pix_pfcol_upper,y
	sta COLUPF
	lda pix_pf0_upper,y
	sta PF0
	lda pix_pf1_upper,y
	sta PF1
	lda pix_pf2_upper,y
	sta PF2
	lda pix_pf3_upper,y
	sta PF0
	lda pix_pf4_upper,y
	sta PF1
	lda pix_pf5_upper,y
	sta PF2
	dey
	bpl .upper_loop

	ldy #(248-112-1)
.lower_loop:
	lda pix_pfcol,y
	sta WSYNC
	sta COLUPF
	lda pix_pf0,y
	sta PF0
	lda pix_pf1,y
	sta PF1
	lda pix_pf2,y
	sta PF2
	lda pix_spcol,y
	sta COLUP0
	lda pix_sprite,y
	sta GRP0
	lda pix_pf3,y
	sta PF0
	lda pix_pf4,y
	sta PF1
	lda pix_pf5,y
	sta PF2
	dey
	bne .lower_loop
	; line 0 is not displayed but that's ok
	; since it's a black line.

	sta WSYNC
	lda #0
	sta COLUPF
	sta COLUP0
	jmp RTSBank

	include "fx_40years_data.asm"

;;;;;;;;;;;;;;;;;;;;
;;; Candle
;
;    include "candle1.asm"
;
;fx_candle_init SUBROUTINE
;	lda #$00
;	sta REFP0 ; No reflexion
;	sta ENAM0 ; No missile 0
;	sta ENAM1 ; No missile 1
;	sta GRP0 ; No player 0
;	sta GRP1 ; No player 1
;
;    lda #$DA
;	sta COLUBK
;
;	jmp RTSBank
;
;fx_candle_vblank SUBROUTINE
;	jmp RTSBank
;
;fx_candle_kernel SUBROUTINE
;    ldx #6
;.delay
;	sta WSYNC
;    dex
;    bpl .delay
;
;    lda framecnt
;    and #8
;    beq .frame2
;
;	ldy #57
;.loopy:
;    ldx #3
;.loopx:
;	sta WSYNC
;	lda candle1_col,y
;	sta COLUPF
;	lda candle1_pf0,y
;	sta PF0
;	lda candle1_pf1,y
;	sta PF1
;	lda candle1_pf2,y
;	sta PF2
;	lda candle1_pf3,y
;	sta PF0
;	lda candle1_pf4,y
;	sta PF1
;	lda candle1_pf5,y
;	sta PF2
;    dex
;    bpl .loopx
;	dey
;	bpl .loopy
;    jmp .end
;
;.frame2
;	ldy #57
;.loopy2:
;    ldx #3
;.loopx2:
;	sta WSYNC
;	lda candle2_col,y
;	sta COLUPF
;	lda candle2_pf0,y
;	sta PF0
;	lda candle2_pf1,y
;	sta PF1
;	lda candle2_pf2,y
;	sta PF2
;	lda candle2_pf3,y
;	sta PF0
;	lda candle2_pf4,y
;	sta PF1
;	lda candle2_pf5,y
;	sta PF2
;    dex
;    bpl .loopx2
;	dey
;	bpl .loopy2
;
;.end
;	sta WSYNC
;	lda #0
;	sta PF0
;	sta PF1
;    sta PF2
;	jmp RTSBank
