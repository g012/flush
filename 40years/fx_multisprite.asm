    include "utils.asm"

LINES   equ 228

    ;copied to RAM and modified as needed
Sprite48x3colorsKernelLoop
patch_attr0 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    lda bushnellAttr0,Y
    sta PF0
patch_attr1 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    lda bushnellAttr1,Y
    sta PF2
patch_sprite1_1 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    lda bushnellSprite1,Y
    sta GRP1
patch_sprite0_1 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    lda bushnellSprite0,Y
    sta GRP0
patch_sprite3_1 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    lda bushnellSprite3,Y
    sta GRP1
patch_sprite4_1 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    ldx bushnellSprite4,Y
patch_col2_1 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    lda bushnellCol2,Y
    sta COLUPF
patch_col1_1 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    lda bushnellCol1,Y
    sta COLUBK
patch_sprite2_1 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    lda bushnellSprite2,Y
    sta GRP0
    stx GRP0
patch_spritebk_1 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    lda #bushnellSPRITEBK
    jmp handlefade
handlefaderet equ spritekernel+(*-Sprite48x3colorsKernelLoop)

patch_sprite1_2 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    lda bushnellSprite1,Y
    sta GRP1
patch_sprite0_2 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    lda bushnellSprite0,Y
    sta GRP0
patch_sprite3_2 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    lda bushnellSprite3,Y
    sta GRP1
patch_sprite4_2 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    ldx bushnellSprite4,Y
patch_col2_2 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    lda bushnellCol2,Y
    sta COLUPF
patch_col1_2 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    lda bushnellCol1,Y
    sta COLUBK
patch_sprite2_2 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
    lda bushnellSprite2,Y
    sta GRP0
    stx GRP0
patch_spritebk_2 equ spritekernel+(*-Sprite48x3colorsKernelLoop+1)
handlefaderet2 equ spritekernel+(*-Sprite48x3colorsKernelLoop)
    lda #bushnellSPRITEBK
    dey
    sta COLUBK
    sta COLUPF

    bpl Sprite48x3colorsKernelLoop
nosprite
    jmp RTSBank
SPRITEKERNELSZ equ *-Sprite48x3colorsKernelLoop
    echo "SPRITEKERNELSZ:",(SPRITEKERNELSZ)d

fx_multisprite_kernel:
    ldx spriteburn
burn
    sta WSYNC
    dex
    bne burn

    ldy spriteh
    beq nosprite
    dey

    SLEEP2 47-8-5-24
    ;augment ZP destination of JMP with graphics bank
    ;this automagically makes the jump happen to the right place
    lda patch_attr0+1
    and #%11100000
    sta tmp+1
    lda #spritekernel
    sta tmp
    jmp JMPBank

fx_multisprite_vblank_3d:
    ;slow down a bit
    lda framecnt
    and #1
    bne norotate
    ;rotate sprites
    ldy spriteidx
    iny
    cpy #25
    bne .ok
    ldy #0
.ok:
    sty spriteidx
norotate:
    ;fall into normal vblank
fx_multisprite_vblank:
XPOS equ 56
    lda #XPOS
    ldx #0
    jsr PositionObject
    lda #XPOS+8
    inx
    jsr PositionObject
    lda #XPOS-39
    inx
    jsr PositionObject
    lda #XPOS+41
    inx
    jsr PositionObject

    sta WSYNC
    sta HMOVE

    lda #$33
    sta NUSIZ0
    sta NUSIZ1
    ;sta VDELP0
    sta VDELP1
    sta ENAM0
    sta ENAM1

    ;CopyKernelLoop is split between here and init
    ;we're running out of cycles D:
COPYSPLIT = 50
    ldx #SPRITEKERNELSZ-1
CopyKernelLoop
    lda Sprite48x3colorsKernelLoop,X
    sta spritekernel,X
    dex
    cpx #COPYSPLIT
    bne CopyKernelLoop

    ;patch in sprite
    SET_POINTER tmp, spritestructs
    ldy spriteidx
    beq done_spriteidx
add20:
    lda tmp
    clc
    adc #20
    sta tmp
    lda tmp+1
    adc #0
    sta tmp+1
    dey
    bne add20
done_spriteidx:

    ;Y = 0
    clc
    lda (tmp),Y
    iny
    sta spriteh
    lda (tmp),Y
    iny
    sta COLUP0
    sta COLUP1
    sta COLUBK
    sta COLUPF
    sta patch_spritebk_1
    sta patch_spritebk_2
    lda (tmp),Y
    iny
    adc spritecrop
    sta patch_sprite0_1
    sta patch_sprite0_2
    lda (tmp),Y
    iny
    sta patch_sprite0_1+1
    sta patch_sprite0_2+1
    lda (tmp),Y
    iny
    adc spritecrop
    sta patch_sprite1_1
    sta patch_sprite1_2
    lda (tmp),Y
    iny
    sta patch_sprite1_1+1
    sta patch_sprite1_2+1
    lda (tmp),Y
    iny
    adc spritecrop
    sta patch_sprite2_1
    sta patch_sprite2_2
    lda (tmp),Y
    iny
    sta patch_sprite2_1+1
    sta patch_sprite2_2+1
    lda (tmp),Y
    iny
    adc spritecrop
    sta patch_sprite3_1
    sta patch_sprite3_2
    lda (tmp),Y
    iny
    sta patch_sprite3_1+1
    sta patch_sprite3_2+1
    lda (tmp),Y
    iny
    adc spritecrop
    sta patch_sprite4_1
    sta patch_sprite4_2
    lda (tmp),Y
    iny
    sta patch_sprite4_1+1
    sta patch_sprite4_2+1
    lda (tmp),Y
    iny
    adc spritecrop
    sta patch_attr0
    lda (tmp),Y
    iny
    sta patch_attr0+1
    lda (tmp),Y
    iny
    adc spritecrop
    sta patch_attr1
    lda (tmp),Y
    iny
    sta patch_attr1+1
    lda (tmp),Y
    iny
    adc spritecrop
    sta patch_col1_1
    sta patch_col1_2
    lda (tmp),Y
    iny
    sta patch_col1_1+1
    sta patch_col1_2+1
    lda (tmp),Y
    iny
    adc spritecrop
    sta patch_col2_1
    sta patch_col2_2
    lda (tmp),Y
    ;iny
    sta patch_col2_1+1
    sta patch_col2_2+1

    ;bob up and down a bit when transitioned in
    lda spriteout
    cmp #2
    bcc hold_spritesin
    inc spritesin
    inc spritesin
    ;inc spritesin
hold_spritesin:
    lda #0
    ldx spriteidx
    lda spritesin
    bpl positive_spritesin
    eor #$FF
positive_spritesin:
    lsr
    cpx #25
    bcc longbob
    lsr
    ;lsr
longbob:
    clc
    adc spritetop
    sta spriteburn

done_spriteburn:

    lda spriteh
    sec
    sbc spritecrop
    bpl sprithok
    lda #0
sprithok:
    sta spriteh
    lda #0
    sta CTRLPF
    sta PF0
    sta PF1
    sta PF2

    ldx spriteout
    beq handle_fadein
    cpx #1        ;>=2 ?
    beq handle_fadeout

    ;only touch spriteout every fourth frame, to extend its range
    lda framecnt
    and #3
    bne setup_fadeout

    dex
    beq setup_fadeout ;don't let it fall to zero
    stx spriteout
setup_fadeout:
    jmp done_transitions

handle_fadein:
    ;transition logic
    ;first bring the fade top->bottom
    lda spritecrop
    beq zero_spritecrop
    dec spritecrop
    jmp done_transitions
zero_spritecrop:
    ;bring the full picture on bottom->top
    lda spritefade
    beq done_transitions
    inc spritefade
    bne done_transitions
    ;spritefade = 0
    ;done - start counting down
    lda spritehold
    sta spriteout
    jmp done_transitions

handle_fadeout:
    lda spritefade
    cmp #32
    bpl done_spritefade
    clc
    adc #2
    sta spritefade
done_spritefade:
    lda spritecrop
    cmp #128
    bpl done_spritecrop
    inc spritecrop
    inc spritecrop
done_spritecrop:

done_transitions:

    jmp RTSBank
    

fx_multisprite_3d:
    lda #210        ;suitable for 6 pats
    sta spritehold
    lda #(LINES-64-frame01SPRITEH*2)/2
    sta spritetop

    lda #0
    jmp fx_multisprite_init_common

fx_multisprite_bushnell:
    lda #110        ;suitable for 4 pats
    sta spritehold
    lda #(LINES-32-bushnellSPRITEH*2)/2
    sta spritetop

    lda #25
    jmp fx_multisprite_init_common

fx_multisprite_candle:
    lda #110        ;suitable for 4 pats
    sta spritehold
    lda #(LINES-32-candlesSPRITEH*2)/2
    sta spritetop

    lda #26

fx_multisprite_init_common:
    sta spriteidx
    lda #0
    sta spriteout
    lda #128
    sta spritefade
    ;lda #SPRITEH
    sta spritecrop
    lsr
    sta spritesin

    ldx #COPYSPLIT
CopyKernelLoop2
    lda Sprite48x3colorsKernelLoop,X
    sta spritekernel,X
    dex
    bpl CopyKernelLoop2

fx_multisprite_overscan:   ;re-use RTS
    jmp RTSBank

    ;20 bytes per entry
spritestructs:
    MAC tabframe
    .byte frame{1}SPRITEH
    .byte frame{1}SPRITEBK
    .word frame{1}Sprite0
    .word frame{1}Sprite1
    .word frame{1}Sprite2
    .word frame{1}Sprite3
    .word frame{1}Sprite4
    .word frame{1}Attr0
    .word frame{1}Attr1
    .word frame{1}Col1
    .word frame{1}Col2
    ENDM
    tabframe 01
    tabframe 02
    tabframe 03
    tabframe 04
    tabframe 05
    tabframe 06
    tabframe 07
    tabframe 08
    tabframe 09
    tabframe 10
    tabframe 11
    tabframe 12
    tabframe 13
    tabframe 14
    tabframe 15
    tabframe 16
    tabframe 17
    tabframe 18
    tabframe 19
    tabframe 20
    tabframe 21
    tabframe 22
    tabframe 23
    tabframe 24
    tabframe 25

    .byte bushnellSPRITEH
    .byte bushnellSPRITEBK
    .word bushnellSprite0
    .word bushnellSprite1
    .word bushnellSprite2
    .word bushnellSprite3
    .word bushnellSprite4
    .word bushnellAttr0
    .word bushnellAttr1
    .word bushnellCol1
    .word bushnellCol2

    .byte candlesSPRITEH
    .byte candlesSPRITEBK
    .word candlesSprite0
    .word candlesSprite1
    .word candlesSprite2
    .word candlesSprite3
    .word candlesSprite4
    .word candlesAttr0
    .word candlesAttr1
    .word candlesCol1
    .word candlesCol2
