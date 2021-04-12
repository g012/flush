    MAC SPRITE48X3COLORS_LOGIC
sprite48x3colorsLogic
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
    lda #$33
    sta NUSIZ0
    sta NUSIZ1
    ;sta VDELP0
    sta VDELP1
    sta ENAM0
    sta ENAM1
    lda #SPRITEBK
    sta COLUP0
    sta COLUP1

    ldx #SPRITEKERNELSZ-1
CopyKernelLoop
    lda Sprite48x3colorsKernelLoop,X
    sta spritekernel,X
    dex
    bpl CopyKernelLoop

    rts
    ENDM

LINECOUNT equ $2d   ;magic

    MAC SPRITE48X3COLORS_KERNEL
sprite48x3colorsKernel
    ldx #(LINES-2*SPRITEH)/2
burn
    sta WSYNC
    dex
    bne burn
    
    ldy #SPRITEH-1

    SLEEP 55

Sprite48x3colorsKernelLoop
    lda Attr0,Y
    sta PF0
    lda Attr1,Y
    sta PF2
    lda Sprite1,Y
    sta GRP1
    lda Sprite0,Y
    sta GRP0
    lda Sprite3,Y
    sta GRP1
    ldx Sprite4,Y
    lda Col2,Y
    sta COLUPF
    lda Col1,Y
    sta COLUBK
    lda Sprite2,Y
    sta GRP0
    stx GRP0
    lda #SPRITEBK
    sta.w COLUBK
    sta COLUPF

    SLEEP 18

    lda Sprite1,Y
    sta GRP1
    lda Sprite0,Y
    sta GRP0
    lda Sprite3,Y
    sta GRP1
    ldx Sprite4,Y
    lda Col2,Y
    sta COLUPF
    lda Col1,Y
    sta COLUBK
    lda Sprite2,Y
    sta GRP0
    stx GRP0
    lda #SPRITEBK
    dey
    sta COLUBK
    sta COLUPF

    bpl Sprite48x3colorsKernelLoop
    rts
SPRITEKERNELSZ equ *-Sprite48x3colorsKernelLoop
    echo "Sprite48x3colorsKernelLoop:",*-Sprite48x3colorsKernelLoop

    ENDM


    ;1-line kernel, for maximum vertical resolution
    MAC SPRITE48X3COLORS_KERNEL_1LINE
sprite48x3colorsKernel
    sta WSYNC

    ldy #SPRITEH-1

    SLEEP 59

Sprite48x3colorsKernelLoop
    lda Attr0,Y
    sta PF0
    lda Attr1,Y
    sta PF2
    lda Sprite1,Y
    sta GRP1
    lda Sprite0,Y
    sta GRP0
    lda Sprite3,Y
    sta GRP1
    ldx Sprite4,Y
    lda Col2,Y
    sta COLUPF
    lda Col1,Y
    sta COLUBK
    lda Sprite2,Y
    sta GRP0
    stx GRP0
    lda #SPRITEBK
    dey
    sta COLUBK
    sta COLUPF

    bpl Sprite48x3colorsKernelLoop
    rts
SPRITEKERNELSZ equ *-Sprite48x3colorsKernelLoop
    echo "Sprite48x3colorsKernelLoop:",*-Sprite48x3colorsKernelLoop

    ENDM
