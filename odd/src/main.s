
.include "vcs.inc"
.include "globals.inc"

.segment "ZEROPAGE"

.segment "RODATA"

demopartslo:
   .lobytes partsaddrlist
demopartshi:
   .hibytes partsaddrlist

.segment "CODE"

reset:
   cld
   ldx #$ff
   txs
   inx
   txa
@clrloop:
   pha
   dex
   bne @clrloop
   pha
   beq firstrun

waitvblank:
   lda #TIMER_SCREEN
@waitloop:
   bit TIMINT
   bpl @waitloop
   sta TIM1KTI
   rts
   
waitscreen:
   lda #TIMER_OVERSCAN
@waitloop:
   bit TIMINT
   bpl @waitloop
   sta TIM64TI
   lda #$02
   sta VBLANK
   rts

waitoverscan:
   lda #TIMER_VBLANK
   pha
   php
   pla
   and #%00000100 ; irq flag
   bne nonext
   inc schedule
firstrun:
   sei
   
nonext:
@waitloop:
   bit TIMINT
   bpl @waitloop

   lda #%00001110  ; each '1' bits generate a VSYNC ON line (bits 1..3)
@syncloop:
   sta WSYNC
   sta VSYNC       ; 1st '0' bit resets VSYNC, 2nd '0' bit exit loop
   lsr
   bne @syncloop   ; branch until VSYNC has been reset
   sta VBLANK
   sta COLUBK
   pla
   sta TIM64TI

   ldx schedule
   lda demopartshi,x
   pha
   lda demopartslo,x
   pha
   rts

