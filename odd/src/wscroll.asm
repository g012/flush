;
; wscroll.asm
;
; Copyright (c) 2004 Alex Herbert
;



        processor       6502



; TIA Registers (Write)
VSYNC   equ     $00
VBLANK  equ     $01
WSYNC   equ     $02
RSYNC   equ     $03
NUSIZ0  equ     $04
NUSIZ1  equ     $05
COLUP0  equ     $06
COLUP1  equ     $07
COLUPF  equ     $08
COLUBK  equ     $09
CTRLPF  equ     $0a
REFP0   equ     $0b
REFP1   equ     $0c
PF0     equ     $0d
PF1     equ     $0e
PF2     equ     $0f
RESP0   equ     $10
RESP1   equ     $11
RESM0   equ     $12
RESM1   equ     $13
RESBL   equ     $14
AUDC0   equ     $15
AUDC1   equ     $16
AUDF0   equ     $17
AUDF1   equ     $18
AUDV0   equ     $19
AUDV1   equ     $1a
GRP0    equ     $1b
GRP1    equ     $1c
ENAM0   equ     $1d
ENAM1   equ     $1e
ENABL   equ     $1f
HMP0    equ     $20
HMP1    equ     $21
HMM0    equ     $22
HMM1    equ     $23
HMBL    equ     $24
VDELP0  equ     $25
VDELP1  equ     $26
VDELBL  equ     $27
RESMP0  equ     $28
RESMP1  equ     $29
HMOVE   equ     $2a
HMCLR   equ     $2b
CXCLR   equ     $2c


; TIA Registers (Read)
CXM0P   equ     $00
CXM1P   equ     $01
CXP0FB  equ     $02
CXP1FB  equ     $03
CXM0FB  equ     $04
CXM1FB  equ     $05
CXBLPF  equ     $06
CXPPMM  equ     $07
INPT0   equ     $08
INPT1   equ     $09
INPT2   equ     $0a
INPT3   equ     $0b
INPT4   equ     $0c
INPT5   equ     $0d


; RIOT Registers
SWCHA   equ     $0280
SWACNT  equ     $0281

SWCHB   equ     $0282
SWBCNT  equ     $0283

INTIM   equ     $0284
TIMINT  equ     $0285

TIM1T   equ     $0294
TIM8T   equ     $0295
TIM64T  equ     $0296
T1024T  equ     $0297








; Macros

        mac     WAIT_TIMINT
.1      bit     TIMINT
        bpl     .1
        sta     WSYNC
        endm



        mac     WAIT_HBLS
        ldx     {1}
.1      dex
        sta     WSYNC
        bne     .1
        endm




; Variables

        seg.u   bss
        org     $0080


frame           ds      1       ; general purpose frame counter
temp            ds      1       ; temporary scratchpad

scroll_pf0      ds      8       ; playfield bitmap
scroll_pf1      ds      8
scroll_pf2      ds      8
scroll_pf3      ds      8
scroll_pf4      ds      8
scroll_pf5      ds      8

scroll_colubk   ds      8       ; background colour
scroll_colupf   ds      1       ; reflection colour

text_addr       ds      2       ; pointer to next character in text
char_addr       ds      2       ; pointer to character bitmap for next column

refl_addr       ds      2       ; pointer into reflection sin() table

music_pos       ds      1       ; song position counter




; Code/Data

        seg     code
        org     $f000,$ff


; Boot Code

boot
        sei
        cld

        ; set the stack
        ldx     #$ff
        txs

        ; wipe zero-page
        inx
        txa
boot_loop
        pha
        dex
        bne     boot_loop


        ; set pointer high bytes
        lda     #>char_data
        sta     char_addr+1

        lda     #>reflect_data
        sta     refl_addr+1

        ; set text string pointer
        lda     #<scroll_text
        sta     text_addr
        lda     #>scroll_text
        sta     text_addr+1



; Frame Loop

vertical_sync
        ; start vsync
        lda     #$02
        sta     WSYNC
        sta     VSYNC

        inc     frame

        sta     WSYNC

        ; set timer for vblank
        lda     #(36*76)>>6
        sta     WSYNC
        sta     TIM64T

        ; end vsync
        lda     #$00
        sta     WSYNC
        sta     VSYNC



vblank_start
        ; get next column of char pixels
        ldy     #$00
        lda     (char_addr),y
        sta     temp

        ldx     #$06            ; for 7 playfield rows
scrollshift_loop
        ; shift pixel into carry
        lsr     temp

        ; rotate into playfield row
        ror     scroll_pf5,x
        rol     scroll_pf4,x
        ror     scroll_pf3,x
        lda     scroll_pf3,x
        lsr
        lsr
        lsr
        lsr
        ror     scroll_pf2,x
        rol     scroll_pf1,x
        ror     scroll_pf0,x

        dex
        bpl     scrollshift_loop


        ; move char pointer to next column of pixels
        inc     char_addr

        ; end of character?
        lda     temp
        beq     textscroll_done

        ; get next character
        lda     (text_addr),y
        asl
        asl
        asl
        sta     char_addr

        ; move text pointer to next character in string
        inc     text_addr
        bne     textscroll_skip1
        inc     text_addr+1
textscroll_skip1

        ; end of string?
        lda     (text_addr),y
        bpl     textscroll_done

        ; back to start of text string
        lda     #<scroll_text
        sta     text_addr
        lda     #>scroll_text
        sta     text_addr+1
textscroll_done


        ; move reflection pointer
        ldx     refl_addr
        dex
        txa
        and     #$7f
        sta     refl_addr


        ; color/bw switch selects NTSC/PAL palette
        lda     SWCHB
        eor     #$ff
        and     #$08
        asl
        asl
        ora     #$90
        sta     scroll_colubk
        sta     scroll_colubk+1
        ora     #$02
        sta     scroll_colupf


        ; set colours
        lda     #$0a
        sta     COLUPF
        lda     #$00
        sta     COLUBK

        ; clear playfield registers
        sta     PF0
        sta     PF1
        sta     PF2


        ; wait for end of vblank
        WAIT_TIMINT


display_start
        ; enable display output
        lda     #$00
        sta     WSYNC
        sta     VBLANK

        ; start timer for display period
        lda     #(191*76)>>6
        sta     TIM64T


        ; some blank lines
        WAIT_HBLS       #$28


        ; draw scroll text

        ldy     #$3f            ; for 64 lines
dscroll_loop
        ; get row index for scroll bitmap (x = y/8)
        tya                     ; 2
        lsr                     ; 2
        lsr                     ; 2
        lsr                     ; 2
        sta     WSYNC           ; 3 67

        tax                     ; 2

        ; background colour
        lda     scroll_colubk,x ; 4
        sta     COLUBK          ; 3 9

        ; playfield left
        lda     scroll_pf0,x    ; 4
        sta     PF0             ; 3 16
        lda     scroll_pf1,x    ; 4
        sta     PF1             ; 3 23
        lda     scroll_pf2,x    ; 4
        sta     PF2             ; 3 30

        ; playfield right
        lda     scroll_pf3,x    ; 4
        sta     PF0             ; 3 37
        lda     scroll_pf4,x    ; 4
        sta     PF1             ; 3 44
        lda     scroll_pf5,x    ; 4
        sta     PF2             ; 3 51

        dey                     ; 2
        bpl     dscroll_loop    ; 3 56


        lda     #$00
        sta     WSYNC
        sta     PF0
        sta     PF1
        sta     PF2


        ; draw reflection

        ; playfield colour
        lda     scroll_colupf
        sta     COLUPF

dscroll_loop2
        ; calculate row index for scroll bitmap
        iny                     ; 2 61
        tya                     ; 2 63
        clc                     ; 2 65
        adc     (refl_addr),y   ; 5 70
        sta     WSYNC           ; 3 73

        lsr                     ; 2
        lsr                     ; 2
        lsr                     ; 2
        and     #$07            ; 2
        tax                     ; 2 10

        ; playefield left
        lda     scroll_pf0,x    ; 4
        sta     PF0             ; 3 17
        lda     scroll_pf1,x    ; 4
        sta     PF1             ; 3 24
        lda     scroll_pf2,x    ; 4
        sta     PF2             ; 3 31

        ; playfield right
        lda     scroll_pf3,x    ; 4
        sta     PF0             ; 3 38
        lda     scroll_pf4,x    ; 4
        sta     PF1             ; 3 45
        lda     scroll_pf5,x    ; 4
        sta     PF2             ; 3 52

        ; display timeout?
        bit     TIMINT          ; 4
        bpl     dscroll_loop2   ; 3 59


        ; disable display output
        lda     #$02
        sta     WSYNC
        sta     VBLANK



overscan_start
        ; set timer for overscan
        lda     #(30*76)>>6
        sta     WSYNC
        sta     TIM64T


        ; music (experimental = ugly mess!)

        lda     music_pos
        and     #$03
        sta     temp

        lda     music_pos
        lsr
        lsr
        cmp     #$38
        and     #$07
        bcc     testtune_skip0a
        ora     #$08
testtune_skip0a
        tax
        lda     test_seq0,x
        asl
        asl
        ora     temp
        tax

        lda     test_audcf0,x
        sec
        rol
        rol
        rol
        rol
        sta     AUDC0

        lda     test_audcf0,x
        sta     AUDF0

        txa
        lsr
        tax
        lda     test_audv0,x
        bcs     testtune_skip0b
        lsr
        lsr
        lsr
        lsr
testtune_skip0b
        sta     AUDV0


        lda     music_pos
        cmp     #$f0
        bcs     testtune_skip1a
        lda     #$00
testtune_skip1a
        and     #$0f
        tax
        lda     test_audf1,x
        sta     AUDF1

        lda     #$0a
        sta     AUDC1

        lda     music_pos
        cmp     #$f0
        and     #$0f
        bcc     testtune_skip1b
        ora     #$10
testtune_skip1b
        lsr
        tax
        lda     test_audv1,x
        bcs     testtune_skip1c
        lsr
        lsr
        lsr
        lsr
testtune_skip1c
        sta     AUDV1


        lda     frame
        lsr
        bcc     testtune_skip2
        inc     music_pos
testtune_skip2


        ; wait for end of overscan
        WAIT_TIMINT

        jmp     vertical_sync



; Char data

        align   $100

char_data
        ; " "
        dc.b    %00000000
        dc.b    %00000000
        dc.b    %00000000
        dc.b    %00000000
        dc.b    %00000000
        dc.b    %00000000
        dc.b    %00000000
        dc.b    %10000000
        ; "A"
        dc.b    %00100000
        dc.b    %01110100
        dc.b    %01010100
        dc.b    %01010100
        dc.b    %01111100
        dc.b    %01111000
        dc.b    %10000000
        dc.b    %10000000
        ; "B"
        dc.b    %01111111
        dc.b    %01111111
        dc.b    %01000100
        dc.b    %01000100
        dc.b    %01111100
        dc.b    %00111000
        dc.b    %10000000
        dc.b    %10000000
        ; "C"
        dc.b    %00111000
        dc.b    %01111100
        dc.b    %01000100
        dc.b    %01000100
        dc.b    %01000100
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        ; "D"
        dc.b    %00111000
        dc.b    %01111100
        dc.b    %01000100
        dc.b    %01000100
        dc.b    %01111111
        dc.b    %01111111
        dc.b    %10000000
        dc.b    %10000000
        ; "E"
        dc.b    %00111000
        dc.b    %01111100
        dc.b    %01010100
        dc.b    %01010100
        dc.b    %01011100
        dc.b    %00001000
        dc.b    %10000000
        dc.b    %10000000
        ; "F"
        dc.b    %00001000
        dc.b    %01111110
        dc.b    %01111111
        dc.b    %00001001
        dc.b    %00000001
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        ; "G"
        dc.b    %00001000
        dc.b    %01011100
        dc.b    %01010100
        dc.b    %01010100
        dc.b    %01111100
        dc.b    %00111100
        dc.b    %10000000
        dc.b    %10000000
        ; "H"
        dc.b    %01111111
        dc.b    %01111111
        dc.b    %00000100
        dc.b    %00000100
        dc.b    %01111100
        dc.b    %01111000
        dc.b    %10000000
        dc.b    %10000000
        ; "I"
        dc.b    %01000100
        dc.b    %01111101
        dc.b    %01111101
        dc.b    %01000000
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        ; "J"
        dc.b    %01000000
        dc.b    %01000100
        dc.b    %01111101
        dc.b    %00111101
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        ; "K"
        dc.b    %01111111
        dc.b    %01111111
        dc.b    %00010000
        dc.b    %00111000
        dc.b    %01101100
        dc.b    %01000100
        dc.b    %10000000
        dc.b    %10000000
        ; "L"
        dc.b    %01000001
        dc.b    %01111111
        dc.b    %01111111
        dc.b    %01000000
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        ; "M"
        dc.b    %01111100
        dc.b    %01111100
        dc.b    %00000100
        dc.b    %00111000
        dc.b    %00000100
        dc.b    %01111100
        dc.b    %01111000
        dc.b    %10000000
        ; "N"
        dc.b    %01111100
        dc.b    %01111100
        dc.b    %00000100
        dc.b    %00000100
        dc.b    %01111100
        dc.b    %01111000
        dc.b    %10000000
        dc.b    %10000000
        ; "O"
        dc.b    %00111000
        dc.b    %01111100
        dc.b    %01000100
        dc.b    %01000100
        dc.b    %01111100
        dc.b    %00111000
        dc.b    %10000000
        dc.b    %10000000
        ; "P"
        dc.b    %01111100
        dc.b    %01111100
        dc.b    %00010100
        dc.b    %00010100
        dc.b    %00011100
        dc.b    %00001000
        dc.b    %10000000
        dc.b    %10000000
        ; "Q"
        dc.b    %00001000
        dc.b    %00011100
        dc.b    %00010100
        dc.b    %00010100
        dc.b    %01111100
        dc.b    %01111100
        dc.b    %01000000
        dc.b    %10000000
        ; "R"
        dc.b    %01111100
        dc.b    %01111100
        dc.b    %00001000
        dc.b    %00000100
        dc.b    %00001100
        dc.b    %00001000
        dc.b    %10000000
        dc.b    %10000000
        ; "S"
        dc.b    %00001000
        dc.b    %01011100
        dc.b    %01010100
        dc.b    %01010100
        dc.b    %01110100
        dc.b    %00100000
        dc.b    %10000000
        dc.b    %10000000
        ; "T"
        dc.b    %00000100
        dc.b    %00111110
        dc.b    %01111110
        dc.b    %01000100
        dc.b    %01000000
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        ; "U"
        dc.b    %00111100
        dc.b    %01111100
        dc.b    %01000000
        dc.b    %01000000
        dc.b    %01111100
        dc.b    %01111100
        dc.b    %10000000
        dc.b    %10000000
        ; "V"
        dc.b    %00011100
        dc.b    %00111100
        dc.b    %01100000
        dc.b    %01100000
        dc.b    %00111100
        dc.b    %00011100
        dc.b    %00000000
        dc.b    %10000000
        ; "W"
        dc.b    %00111100
        dc.b    %01111100
        dc.b    %01000000
        dc.b    %01111000
        dc.b    %01000000
        dc.b    %01111100
        dc.b    %00111100
        dc.b    %10000000
        ; "X"
        dc.b    %01000100
        dc.b    %01101100
        dc.b    %00111000
        dc.b    %00010000
        dc.b    %00111000
        dc.b    %01101100
        dc.b    %01000100
        dc.b    %10000000
        ; "Y"
        dc.b    %00001100
        dc.b    %01011100
        dc.b    %01010000
        dc.b    %01010000
        dc.b    %01111100
        dc.b    %00111100
        dc.b    %00000000
        dc.b    %10000000
        ; "Z"
        dc.b    %01000100
        dc.b    %01100100
        dc.b    %01110100
        dc.b    %01011100
        dc.b    %01001100
        dc.b    %01000100
        dc.b    %10000000
        dc.b    %10000000
        ; "."
        dc.b    %00000000
        dc.b    %01000000
        dc.b    %01000000
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        ; "!"
        dc.b    %00000000
        dc.b    %01000000
        dc.b    %01011100
        dc.b    %00011111
        dc.b    %00001111
        dc.b    %00000011
        dc.b    %10000000
        dc.b    %10000000
        ; "(:"
        dc.b    %00011100
        dc.b    %00101110
        dc.b    %01011011
        dc.b    %01011111
        dc.b    %01011011
        dc.b    %00101110
        dc.b    %00011100
        dc.b    %10000000
        ; "'"
        dc.b    %00000010
        dc.b    %00000011
        dc.b    %00000001
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        ; "?"
        dc.b    %00000010
        dc.b    %00000011
        dc.b    %01011001
        dc.b    %01011101
        dc.b    %00001111
        dc.b    %00000110
        dc.b    %10000000
        dc.b    %10000000



; Reflection data

        align   $100

reflect_data
        repeat  2

        ; sine wave
        dc.b    0
        dc.b    2
        dc.b    4
        dc.b    6
        dc.b    9
        dc.b    11
        dc.b    13
        dc.b    15
        dc.b    16
        dc.b    18
        dc.b    19
        dc.b    21
        dc.b    22
        dc.b    22
        dc.b    23
        dc.b    23
        dc.b    24
        dc.b    23
        dc.b    23
        dc.b    22
        dc.b    22
        dc.b    21
        dc.b    19
        dc.b    18
        dc.b    16
        dc.b    15
        dc.b    13
        dc.b    11
        dc.b    9
        dc.b    6
        dc.b    4
        dc.b    2
        dc.b    0
        dc.b    -2
        dc.b    -4
        dc.b    -6
        dc.b    -9
        dc.b    -11
        dc.b    -13
        dc.b    -15
        dc.b    -16
        dc.b    -18
        dc.b    -19
        dc.b    -21
        dc.b    -22
        dc.b    -22
        dc.b    -23
        dc.b    -23
        dc.b    -24
        dc.b    -23
        dc.b    -23
        dc.b    -22
        dc.b    -22
        dc.b    -21
        dc.b    -19
        dc.b    -18
        dc.b    -16
        dc.b    -15
        dc.b    -13
        dc.b    -11
        dc.b    -9
        dc.b    -6
        dc.b    -4
        dc.b    -2

        ; shorter sine wave (twice)
        repeat  2

        dc.b    0
        dc.b    4
        dc.b    9
        dc.b    13
        dc.b    16
        dc.b    19
        dc.b    22
        dc.b    23
        dc.b    24
        dc.b    23
        dc.b    22
        dc.b    19
        dc.b    16
        dc.b    13
        dc.b    9
        dc.b    4
        dc.b    0
        dc.b    -4
        dc.b    -9
        dc.b    -13
        dc.b    -16
        dc.b    -19
        dc.b    -22
        dc.b    -23
        dc.b    -24
        dc.b    -23
        dc.b    -22
        dc.b    -19
        dc.b    -16
        dc.b    -13
        dc.b    -9
        dc.b    -4

        repend
        repend



; Music data

        align   $100

test_seq0
        dc.b    0,1,1,3,2,3,3,1
        dc.b    0,2,1,3,2,1,3,1

test_audcf0
        dc.b    $00+$1f,$40+$10,$40+$12,$40+$14
        dc.b    $20+$03,$20+$01,$20+$00,$20+$00
        dc.b    $00+$07,$00+$03,$80+$14,$80+$16
        dc.b    $20+$07,$20+$03,$20+$01,$20+$00

test_audv0
        dc.b    $cb,$a9
        dc.b    $42,$10
        dc.b    $b9,$75
        dc.b    $42,$10


test_audf1
        dc.b    $0f,$0f,$0f,$0f
        dc.b    $10,$10,$11,$11
        dc.b    $12,$12,$13,$13
        dc.b    $14,$14,$15,$15

test_audv1
        dc.b    $34,$45
        dc.b    $56,$67
        dc.b    $87,$65
        dc.b    $43,$21

        dc.b    $01,$23
        dc.b    $45,$67
        dc.b    $89,$ab
        dc.b    $cc,$dd



; Scroll text

        align   $100

scroll_text
        dc.b    "            "
        dc.b    "hello"
        dc.b    "            "
        dc.b    "whoa\"
        dc.b    "            "
        dc.b    "did you see that?"
        dc.b    "            "
        dc.b    "water\"
        dc.b    "            "
        dc.b    "ripples\\\"
        dc.b    "            "
        dc.b    "an old effect but i haven^t seen it done on "
        dc.b    "the vcs before;"
        dc.b    "            "
        dc.b    "sorry the music is so short;;;"
        dc.b    "        "
        dc.b    "just experimenting;"
        dc.b    "            "
        dc.b    "that^s all;"
        dc.b    "            "
        dc.b    "nothing more to see here;"
        dc.b    "            "
        dc.b    "bye\"
        dc.b    "            "
        dc.b    "]"
        dc.b    "            "
        dc.b    "            "



; CPU Vectors

        org     $fffa
        dc.w    boot,boot,boot

