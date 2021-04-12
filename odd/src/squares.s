
.include "vcs.inc"
.include "globals.inc"

.segment "ZEROPAGE"

frmcnt:
   .word 0
tmp:
   .byte 0

.segment "RODATA"

sqp1:
   .byte $ff,$00,$00,$00
sqp2:
   .byte $ff,$00,$00,$00
sqp3:
   .byte $ff,$3c,$00,$3c
sqp4:
   .byte $ff,$3c,$18,$3c,$ff

sqm1:
   .byte $00,$00,$02,$00
sqm2:
   .byte $00,$00,$02,$00
sqm3:
   .byte $00,$02,$02,$02,$00
sqm4:
   .byte $02,$02,$02,$02,$02
   
msiz:
   .byte $16,$26,$36,$26,$16
mmov:
   .byte $d0,$e0,$00,$e0,$d0

.segment "CODE"

spritepos:
   sta WSYNC
   lda #$00
   sta HMP0
   lda #$10
   sta HMP1
   lda #$10
   adc mmov,x
   sta HMM0
   inx
   lda #$20
   adc mmov,x
   sta RESBL
   sta RESP0
   sta RESP1
   sta RESM0
   sta RESM1
   sta HMM1
   sbc #$3f
   sta HMBL
   lda msiz,x
   sta NUSIZ1
   ora #$01
   sta CTRLPF
   dex
   lda msiz,x
   sta NUSIZ0
   rts
   
fx_squares:
   sta WSYNC
   sta HMCLR
   lda #$00
   sta VDELP1
   inc frmcnt
   bne @nohigh
   inc frmcnt+1
   lda frmcnt+1
   cmp #$03
   bne @nohigh
   cli
@nohigh:

   jsr waitvblank

   ldx #$08
@waitloop:
   sta WSYNC
   dex
   bne @waitloop

   stx COLUPF
   stx COLUP0
   stx COLUP1
   stx COLUBK
   lda #$06
   sta NUSIZ0
   sta NUSIZ1

.macro block _grp, _grm
   inx
   lda _grp,x
   sta GRP1
   lda _grm,x
   sta ENAM1
   sta ENABL
   dex
   lda _grp,x
   sta GRP0
   lda _grm,x
   sta ENAM0
.endmacro

   lda frmcnt
   lsr
   lsr
   and #$03
   tax
   
   ldy #$0c
@loop:
   jsr spritepos
   tya
   asl
   asl
   asl
   adc frmcnt
   and #$78
   cmp #$40
   bcs @notoggle
   eor #$78
@notoggle:
   lsr
   lsr
   sta tmp
   
   tya
   asl
   asl
   asl
   asl
   adc tmp
   sta COLUP0
   sta COLUP1
   sta COLUPF
   sta WSYNC
   sta HMOVE
   block sqp1, sqm1 
   sta WSYNC
   sta HMCLR
   sta WSYNC
   block sqp2, sqm2 
   sta WSYNC
   sta WSYNC
   block sqp3, sqm3 
   sta WSYNC
   sta WSYNC
   block sqp4, sqm4 
   sta WSYNC
   sta WSYNC
   sta WSYNC
   sta WSYNC
   block sqp3, sqm3 
   sta WSYNC
   sta WSYNC
   block sqp2, sqm2 
   sta WSYNC
   sta WSYNC
   block sqp1, sqm1
   sta WSYNC
   sta WSYNC
   lda #$00
   sta GRP0
   sta GRP1
   sta ENAM0
   sta ENAM1
   sta ENABL
   dex
   txa
   and #$03
   tax
   dey
   beq @out
   jmp @loop
@out: 
   
   lda #$00
   sta WSYNC
   sta GRP0
   sta GRP1
   sta ENAM0
   sta ENAM1
   sta COLUBK
   sta COLUPF
   
   jsr waitscreen
   jmp waitoverscan

delay12:
   rts
