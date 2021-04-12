    ;Positions object X to horizontal position in accumulator
    ; 0 = P0
    ; 1 = P1
    ; 2 = M0
    ; 3 = M1
    ; 4 = BL
    ;
    ;This takes one full scanline
PositionObject
    clc
    sta WSYNC
DivideLoop
    sbc #15
    bcs DivideLoop
#if >DivideLoop - >*
    echo "DivideLoop not aligned"
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
