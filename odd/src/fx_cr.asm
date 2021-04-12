FX_CR_BGCOL = 0 
FX_CR_BGLINECOL = $3A

FX_CR_TOP_LH = 48
FX_CR_TOP_OY = 22

FX_CR_MID_OY = 50

FX_CR_BOT_LH = 48
FX_CR_BOT_OY = 50

FX_CR_MID_LH = 8

fx_cr_flushtimi = fxdata ; 1
fx_cr_flushcols = fxdata+1 ; 5
fx_cr_delayptr = fxdata+6 ; 2
fx_cr_s1 = fxdata+8 ; 2
fx_cr_s2 = fxdata+10 ; 2
fx_cr_s3 = fxdata+12 ; 2
fx_cr_s4 = fxdata+14 ; 2
fx_cr_s5 = fxdata+16 ; 2
fx_cr_s6 = fxdata+18 ; 2

fx_cr_waitlines SUBROUTINE
    sta WSYNC
    dex
    bne fx_cr_waitlines
    rts

fx_cr_bgline    SUBROUTINE
    lda #FX_CR_BGLINECOL
    sta WSYNC
    sta COLUBK
    lda #0
    sta WSYNC
    sta COLUBK
    rts

fx_cr_sprite    SUBROUTINE
    ldy #16
.text:
    sta WSYNC
    ;jmp (DelayPTR)
.delay:
    ;dc.b $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9
    ;dc.b $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9
    ;dc.b $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9
    ;dc.b $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c5
    ;nop
    lda (fx_cr_s1),y
    sta GRP0
    sta GRP1
    dey
    bne .text
    sta WSYNC
    lda #0
    sta GRP0
    sta GRP1
    sta WSYNC
    beq fx_cr_bgline    ; beq is one byte less than jmp

fx_cr_top       SUBROUTINE
    lda #$C6
    sta COLUP0
    lda #$66
    sta COLUP1

    ldx #FX_CR_TOP_OY
    jsr fx_cr_waitlines
    jsr fx_cr_bgline

    sta WSYNC
    sta HMOVE
    beq fx_cr_sprite

fx_cr_bot       SUBROUTINE
    lda #$4A
    sta COLUP0
    lda #$2C
    sta COLUP1
    ldx #FX_CR_BOT_OY
    jsr fx_cr_waitlines
    jsr fx_cr_bgline

    sta WSYNC
    beq fx_cr_sprite

fx_cr_mid       SUBROUTINE
    ldx #FX_CR_MID_OY
    jsr fx_cr_waitlines
    ldx #4
.lines:
    ldy #FX_CR_MID_LH
.line:
    sta WSYNC               ; 0 [ 0]
    lda fx_cr_flushcols,x   ; 4 [ 4]
    sta COLUPF              ; 3 [ 7]

    lda fx_cr_flush+0,x     ; 4 [11]
    sta PF0                 ; 3 [14]
    lda fx_cr_flush+5,x     ; 4 [18]
    sta PF1                 ; 3 [21]
    lda fx_cr_flush+10,x    ; 4 [25]
    sta PF2                 ; 3 [28]
    lda fx_cr_flush+15,x    ; 4 [32]
    sta PF0                 ; 3 [35]
    nop                     ; 2 [37]
    nop                     ; 2 [39]
    lda fx_cr_flush+20,x    ; 4 [43]
    sta PF1                 ; 3 [46]
    nop                     ; 2 [48]
    nop                     ; 2 [50]
    lda fx_cr_flush+25,x    ; 4 [54]
    sta PF2                 ; 3 [57]

    dey                     ; 2 [59]
    bne .line               ; 2 [61]
    dex                     ; 2 [63]
    bpl .lines              ; 2 [65]

    lda #0                  ; 2 [67]
    sta COLUPF              ; 3 [70]
    sta PF0                 ; 3 [73]
    sta PF1                 ; 3 [76]
    sta PF2                 ; 3 [79]
    rts

fx_cr_copycol   SUBROUTINE
    ldy #4
.copy:
    lda fx_cr_flushcolt,x
    sta fx_cr_flushcols,y
    dex
    dey
    bpl .copy
    rts

fx_cr_kernel    SUBROUTINE
    inc fx_cr_flushtimi
    lda #$5F
    cmp fx_cr_flushtimi
    bpl .flushtimevalid
    lda #0
    sta fx_cr_flushtimi
.flushtimevalid:
    ldy fx_cr_flushtimi
    ldx fx_cr_flushtime,y
    jsr fx_cr_copycol

    jsr WaitForVBlankEnd
    
    jsr fx_cr_top
    jsr fx_cr_mid
    jsr fx_cr_bot

    jsr WaitForDisplayEnd

    lda #4
    bit time+1
    bne .end
    jmp MainLoop
.end:
    jmp FXNext

fx_cr_setup     SUBROUTINE
    lda #FX_CR_BGCOL
    sta COLUBK
    lda #0
    sta fx_cr_flushtimi
    sta time
    sta time+1

    sta WSYNC
    sta RESP0
    REPEAT 12
    nop
    REPEND
    sta RESP1

    lda #$10
    sta HMP0
    sta HMP1

    lda #3
    sta NUSIZ0
    sta NUSIZ1

    lda #<fx_cr_graph1
    sta fx_cr_s1
    lda #>fx_cr_graph1
    sta fx_cr_s1+1
    lda #<fx_cr_graph2
    sta fx_cr_s2
    lda #>fx_cr_graph2
    sta fx_cr_s2+1
    lda #<fx_cr_graph3
    sta fx_cr_s3
    lda #>fx_cr_graph3
    sta fx_cr_s3+1
    lda #<fx_cr_graph4
    sta fx_cr_s4
    lda #>fx_cr_graph4
    sta fx_cr_s4+1
    lda #<fx_cr_graph5
    sta fx_cr_s5
    lda #>fx_cr_graph5
    sta fx_cr_s5+1
    lda #<fx_cr_graph6
    sta fx_cr_s6
    lda #>fx_cr_graph6
    sta fx_cr_s6+1
    
    jmp MainLoop


	;ALIGN $100

fx_cr_graph1:
    dc.b %00000000
    dc.b %00000011
    dc.b %00000011
    dc.b %00000011
    dc.b %00000011
    dc.b %00000011
    dc.b %00000011
    dc.b %00000011
    dc.b %00000011
    dc.b %00000011
    dc.b %00000011
    dc.b %00000011
    dc.b %00000011
    dc.b %11000011
    dc.b %00110011
    dc.b %00001111
    dc.b %00000011
fx_cr_graph2:
    dc.b %00000000
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %01100000
	dc.b %00011000
	dc.b %00000110
	dc.b %11000110
	dc.b %01111100
fx_cr_graph3:
    dc.b %00000000
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %01111000
	dc.b %11000000
	dc.b %11111100
	dc.b %11001100
	dc.b %01111000
	dc.b %00000000
fx_cr_graph4:
    dc.b %00000000
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %00000110
	dc.b %00000110
	dc.b %11111110
	dc.b %11000110
	dc.b %01100110
	dc.b %01100110
fx_cr_graph5:
    dc.b %00000000
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
    dc.b %01111100
	dc.b %00000110
	dc.b %01111100
	dc.b %11000000
	dc.b %01111100
	dc.b %00000000
fx_cr_graph6:
    dc.b %00000000
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11111110
	dc.b %11000000
	dc.b %11111000
	dc.b %11001100
	dc.b %11001100
	dc.b %11111000
	dc.b %00000000

fx_cr_flushtime: ; 96 entries
    dc.b 4, 4, 4, 4, 4
    dc.b 5, 5, 5, 5
    dc.b 6, 6, 6
    dc.b 7, 7
    dc.b 8
    dc.b 9, 9
    dc.b 10, 10, 10
    dc.b 11, 11, 11, 11
    dc.b 12, 12, 12, 12, 12
    dc.b 13, 13, 13, 13
    dc.b 14, 14, 14
    dc.b 15, 15
    dc.b 16
    dc.b 17, 17
    dc.b 18, 18, 18
    dc.b 19, 19, 19, 19
    dc.b 20, 20, 20, 20, 20
    dc.b 19, 19, 19, 19
    dc.b 18, 18, 18
    dc.b 17, 17
    dc.b 16
    dc.b 15, 15
    dc.b 14, 14, 14
    dc.b 13, 13, 13, 13
    dc.b 12, 12, 12, 12, 12
    dc.b 11, 11, 11, 11
    dc.b 10, 10, 10
    dc.b 9, 9
    dc.b 8
    dc.b 7, 7
    dc.b 6, 6, 6
    dc.b 5, 5, 5, 5

fx_cr_flushcolt:
    dc.b $00, $00, $00, $00, $00, $92, $94, $96, $98, $9A
    dc.b $9C
    dc.b $9A, $98, $96, $94, $92, $00, $00, $00, $00, $00

fx_cr_flush:
    include "fx_cr_flush.h"
