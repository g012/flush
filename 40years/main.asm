;;;-----------------------------------------------------------------------------
;;; Header

	PROCESSOR 6502
	INCLUDE "vcs.h"		; Provides RIOT & TIA memory map
	INCLUDE "macro.h"		; This file includes some helper macros
  include "sleep2.h"  ; more ROM efficient SLEEP2 macro


;;;-----------------------------------------------------------------------------
;;; RAM segment

	SEG.U ram
	ORG $0080

    include "zik/TarasBulbaLight_variables.asm"
    include "zik/Tu_Ricanes_loop_variables.asm"

PATTERN_LEN = TT_SPEED*32 ; Most patterns are 32 notes long, each note lasts TT_SPEED frames

    ;re-use player temp variables
tmp         equ tt_ptr
tmp2        equ tt_ptr+1
tmp3        ds	1
framecnt    ds  1
curpart     ds  1 ; Index of current part (FX)
patternidx  ds  1 ; Index of current pattern
patternfrm  ds  1 ; Count frames for current pattern
audv_buf   ds  2 ; Keeps the value of AUDV0 & AUDV1 to be able to override the volume

    ;part-specific RAM starts here
PARTRAM equ *
    ;4 bytes of stack used
RAMEND  equ $FC
    echo "RAM available for parts:", (RAMEND-PARTRAM)d, "bytes"

seed	DS.B	1
rndswitch DS.B      1
rndthres  DS.B	1

scrawlbg  DS.B      1
scrawlfg  DS.B      1
scrawlidx DS.B	1
scrawlbas DS.W	1
scrawlptr DS.W      6
buffer	DS.B	6
    echo "fx:", (RAMEND-*)d, "bytes left"

    org PARTRAM
scroll		ds.b	1
scroll_end	ds.b	1
scroll_dir	ds.b	1
time		ds.b	1
bgtime      ds.b    1
haircolor   ds.b    1
colptr        ds  2
    echo "fx_visy:", (RAMEND-*)d, "bytes left"

    org PARTRAM
ptr            DS.B 2 ; Temporary pointer
part           DS.B 1 ; part index
state          DS.B 1 ; state used inside each part
rsprite_idx    DS.B 1 ; Index in the right sprite table
rsprite_offset DS.B 1 ; Sprite offset, enables moving sprites
; Pointers to sprites (current & origin)
missile_optr  DS.B 2 ; Origin Pointer to the missile
lsprite_optr  DS.B 2 ; Origin Pointer to left sprite
missile_cptr  DS.B 2 ; Current Pointer to the missile
lsprite_cptr  DS.B 2 ; Current Pointer to left sprite
; abscisse sprites positions
miss_pos_x    DS.B 1
rsprite_pos_x DS.B 1
lsprite_pos_x DS.B 1
; buffers to uncompress right sprite
rsprite_buf   DS.B 24
rcolor_buf    DS.B 24
; moon patrol
patrol_offset ds.b 1
patrol_step   ds.b 1
patrol_offy   ds.b 1
ground_frame  ds.b 1
mountain_ram  ds.b 18
    echo "fx_shooter:", (RAMEND-*)d, "bytes left"

    org PARTRAM
spriteidx    ds 1
spriteburn   ds 1
spritecrop   ds 1
spriteh      ds 1
spritefade   ds 1
spriteout    ds 1 ;how long until the sprite should start fading out
spritehold   ds 1 ;init value for spriteout (different for nolan and 3d)
spritetop    ds 1
spritesin    ds 1
spritekernel ds SPRITEKERNELSZ
    echo "fx_multisprite:", (RAMEND-*)d, "bytes left"

    org PARTRAM
bg_ptr       ds 2
    echo "fx_40years:", (RAMEND-*)d, "bytes left"

;;;-----------------------------------------------------------------------------
;;; ROM segment

    echo "--- ROM follows ---"

RTSBank equ $1FD9
JMPBank equ $1FE6

    ;39 byte bootstrap macro
    ;Includes RTSBank, JMPBank routines and JMP to Start in Bank 7
    MAC END_SEGMENT_CODE
;RTSBank
;Perform a long RTS
    tsx
    lda $02,X
    ;decode bank
    ;bank 0: $1000-$1FFF
    ;bank 1: $3000-$3FFF
    ;...
    ;bank 7: $F000-$FFFF
    lsr
    lsr
    lsr
    lsr
    lsr
    tax
    nop $1FF4,X     ;3 B
    rts
;JMPBank
;Perform a long jmp to (tmp)
;The bank number is stored in the topmost three bits of (tmp)
;Example usage:
;   SET_POINTER tmp, Address
;   jmp JMPBank
;
    ;$1FE6-$1FED
    lda tmp+1
    lsr
    lsr
    lsr
    lsr
    lsr
    tax
    ;$1FEE-$1FF3
    nop $1FF4,X     ;3 B
    jmp (tmp)     ;3 B
    ENDM
    MAC END_SEGMENT
.BANK   SET {1}
    echo "Bank",(.BANK)d,":", ((RTSBank + (.BANK * 8192)) - *)d, "free"

    org RTSBank + (.BANK * 4096)
    rorg RTSBank + (.BANK * 8192)
    END_SEGMENT_CODE
    ;$1FF4-$1FFB
    .byte 0,0,0,0
    .byte 0,0,0,$4C ;JMP Start (reading the instruction jumps to bank 7, where Start's address is)
    ;$1FFC-1FFF
    .word $1FFB
.Delay14
    nop
.Delay12
    rts
    ;Bank .BANK+1
    org $1000 + ((.BANK + 1) * 4096)
    rorg $1000 + ((.BANK + 1) * 8192)
    ENDM


;;;-----------------------------------------------------------------------------
;;; Code segment

    include "bushnell.asm"
    include "candle.asm"
    include "visy_anim/frame01.asm"
    include "visy_anim/frame02.asm"
    include "visy_anim/frame03.asm"
    include "visy_anim/frame04.asm"
    include "visy_anim/frame05.asm"
    include "visy_anim/frame06.asm"
    include "visy_anim/frame07.asm"
    include "visy_anim/frame08.asm"
    include "visy_anim/frame09.asm"
    include "visy_anim/frame10.asm"
    include "visy_anim/frame11.asm"
    include "visy_anim/frame12.asm"
    include "visy_anim/frame13.asm"
    include "visy_anim/frame14.asm"
    include "visy_anim/frame15.asm"
    include "visy_anim/frame16.asm"
    include "visy_anim/frame17.asm"
    include "visy_anim/frame18.asm"
    include "visy_anim/frame19.asm"
    include "visy_anim/frame20.asm"
    include "visy_anim/frame21.asm"
    include "visy_anim/frame22.asm"
    include "visy_anim/frame23.asm"
    include "visy_anim/frame24.asm"
    include "visy_anim/frame25.asm"

	SEG code

    ;Bank 0
    org $1000
    rorg $1000

    MAC HANDLEFADE
    sta COLUBK
    sta COLUPF
    cpy spritefade
    bpl .nofade
    SLEEP2 57
    jmp handlefaderet2
.nofade:
    SLEEP2 7
    jmp handlefaderet
    ENDM

handlefade:
    HANDLEFADE  ;must be the first thing in any bank used by the multisprite code

    include "zik/TarasBulbaLight_trackdata.asm"
    include "zik/Tu_Ricanes_loop_trackdata.asm"

    ;do player, then RTS across banks
    include "zik/TarasBulbaLight_player.asm"
    jmp RTSBank
    include "zik/Tu_Ricanes_loop_player.asm"
    jmp RTSBank

    align 128
    candlesSPRITE0
    align 128
    candlesSPRITE1
    align 128
    candlesSPRITE2
    align 128
    candlesSPRITE3
    align 128
    candlesSPRITE4
    align 128
    candlesATTR0
    align 128
    candlesATTR1
    align 128
    candlesCOL2
    align 128
    candlesCOL1

    END_SEGMENT 0

    ;the bulk of a sprite (240 bytes)
    MAC insertsprite_bulk
    align 256
    frame{1}SPRITE0
    frame{1}SPRITE1
    frame{1}SPRITE2
    frame{1}SPRITE3
    frame{1}SPRITE4
    frame{1}COL1
    ENDM

    ;slop (120 bytes)
    MAC insertsprite_slop
    align 128
    frame{1}COL2
    frame{1}ATTR0
    frame{1}ATTR1
    ENDM

    HANDLEFADE  ;must be the first thing in any bank used by the multisprite code

    insertsprite_bulk 22
    insertsprite_bulk 23

    insertsprite_slop 22
    insertsprite_slop 23


PARTSTART1 equ *
	INCLUDE "fx_visy.asm"
    echo "fx_visy:", (*-PARTSTART1)d, "B"

    END_SEGMENT 1

    HANDLEFADE  ;must be the first thing in any bank used by the multisprite code

    align 128
    bushnellSPRITE0
    align 128
    bushnellSPRITE1
    align 128
    bushnellSPRITE2
    align 128
    bushnellSPRITE3
    align 128
    bushnellSPRITE4
    align 128
    bushnellATTR0
    align 128
    bushnellATTR1
    align 128
    bushnellCOL2
    align 128
    bushnellCOL1

    insertsprite_bulk 24
    insertsprite_bulk 25
    insertsprite_bulk 21

    insertsprite_slop 24
    insertsprite_slop 25
    insertsprite_slop 21

    include "fx_multisprite.asm"

    END_SEGMENT 2

PARTSTART_SHOOTER equ *
    include "fx_shooter.asm"
    echo "fx_shooter:", (*-PARTSTART_SHOOTER)d, "B"

    END_SEGMENT 3

PARTSTART_40YEARS equ *
    include "fx_40years.asm"
    echo "fx_40years:", (*-PARTSTART_40YEARS)d, "B"

    END_SEGMENT 4

    HANDLEFADE  ;must be the first thing in any bank used by the multisprite code

    insertsprite_slop 01

    insertsprite_bulk 01
    insertsprite_bulk 02
    insertsprite_bulk 03
    insertsprite_bulk 04
    insertsprite_bulk 05
    insertsprite_bulk 06
    insertsprite_bulk 07
    insertsprite_bulk 08
    insertsprite_bulk 09
    insertsprite_bulk 10

    insertsprite_slop 02
    insertsprite_slop 03
    insertsprite_slop 04
    insertsprite_slop 05
    insertsprite_slop 06
    insertsprite_slop 07
    insertsprite_slop 08
    insertsprite_slop 09
    insertsprite_slop 10

    END_SEGMENT 5

    HANDLEFADE  ;must be the first thing in any bank used by the multisprite code

    insertsprite_slop 11

    insertsprite_bulk 11
    insertsprite_bulk 12
    insertsprite_bulk 13
    insertsprite_bulk 14
    insertsprite_bulk 15
    insertsprite_bulk 16
    insertsprite_bulk 17
    insertsprite_bulk 18
    insertsprite_bulk 19
    insertsprite_bulk 20

    insertsprite_slop 12
    insertsprite_slop 13
    insertsprite_slop 14
    insertsprite_slop 15
    insertsprite_slop 16
    insertsprite_slop 17
    insertsprite_slop 18
    insertsprite_slop 19
    insertsprite_slop 20

    END_SEGMENT 6

    ;Bank 7
PARTTABS    equ *
vblanks:
    .word   fx_vblank
    .word   fx_visy_vblank
    .word   fx_vblank
    .word   fx_shooter_vblank
    .word   fx_vblank
    .word   fx_multisprite_vblank
    .word   fx_multisprite_vblank
    .word   fx_vblank
    .word   fx_multisprite_vblank_3d
    .word   fx_vblank
    .word   fx_40years_vblank
    .word   fx_vblank
    .word   fx_40years_vblank

kernels:
    .word   fx_kernel
    .word   fx_visy_kernel
    .word   fx_kernel
    .word   fx_shooter_kernel
    .word   fx_kernel
    .word   fx_multisprite_kernel
    .word   fx_multisprite_kernel
    .word   fx_kernel
    .word   fx_multisprite_kernel
    .word   fx_kernel
    .word   fx_40years_kernel
    .word   fx_kernel
    .word   fx_40years_kernel

overscans:
    .word   fx_overscan_slow
    .word   fx_visy_overscan
    .word   fx_overscan_slow
    .word   fx_shooter_overscan
    .word   fx_overscan_slow
    .word   fx_multisprite_overscan
    .word   fx_multisprite_overscan
    .word   fx_overscan_slow
    .word   fx_multisprite_overscan
    .word   fx_overscan_slow
    .word   fx_40years_overscan
    .word   fx_overscan_fast
    .word   fx_overscan_fast
    .word   fx_40years_overscan

    ;specifies on which patterns to switch parts
    ;could use frame counters instead..
partswitch:
    .byte   4 ; 0 - intro - 4 pats
    .byte  10 ; 1 - dancer - 8 pats
    .byte  15 ; 2 - racing the beam and invading screens - 5 pats
    .byte  23 ; 3 - shooter - 8 pats
    .byte  26 ; 4 - babes - 3 pats
    .byte  30 ; 5 - multi-sprites bushnell - 4 pats
    .byte  34 ; 5 - multi-sprites candle - 4 pats
    .byte  37 ; 6 - stella lives - 3 pats
    .byte  43 ; 7 - multi-sprites - 6 pats
    .byte  46 ; 8 - burstday - 3 pats
PATTERN_GREETZ = 54 ; Pattern index used for music transition
    .byte PATTERN_GREETZ ; 9 - 40 years - 8 pats
    .byte  66 ; 10 - greetz - 12 pats
    .byte 256 ; 12 - 40 years loop after 256 patterns i.e 6 minutes
NPARTS equ *-partswitch

inits:
    .word   fx_visy_init
    .word   fx_init_invading
    .word   fx_shooter_init
    .word   fx_init_babes
    .word   fx_multisprite_bushnell
    .word   fx_multisprite_candle
    .word   fx_init_stella
    .word   fx_multisprite_3d
    .word   fx_init_burstday
    .word   fx_40years_init
    .word   fx_init_greetz
    .word   fx_40years_init

    if <inits < 2
        echo "inits must start at least two bytes into page:",inits
        err
    endif

    ;keeping all these tables on the same page make the code several bytes smaller
    if >PARTTABS != >*
        echo "PARTTABS not aligned"
        err
    endif


init	CLEAN_START		; Initializes Registers & Memory

    include "zik/TarasBulbaLight_init.asm"

          ; Initialize the pattern counter
          lda #PATTERN_LEN
          sta patternfrm

	jsr fx_init_intro

; Play the music according to current timeline
    MAC PLAY_THE_MUSIC
    lda patternidx
    cmp #PATTERN_GREETZ
    bpl .endsong
    SET_POINTER tmp, tt_PlayerStart
    jsr JMPBank
    lda patternidx
    cmp #(PATTERN_GREETZ - 1)
    bne .end_firstzik
    ; Fading out the music
    lda patternfrm
    and #$c0
    bne .end_firstzik
    lda patternfrm
    REPEAT 4
    lsr
    REPEND ; value of A is between 0 and 3
    sta tmp
    sec
    lda #3
    sbc tmp ; Switch the number to have a value of 3 when patternfrm reaches 0
    sta tmp
    ldx #1
.fadeout:
    lda audv_buf,x
    and #$0f
    ldy tmp
.fadeshift:
    lsr
    dey
    bpl .fadeshift
    sta audv_buf,x
    dex
    bpl .fadeout
.end_firstzik
    lda audv_buf
    sta AUDV0
    lda audv_buf+1
    sta AUDV1
    jmp .end
.endsong
    SET_POINTER tmp, Tu_Ricanes_loop_tt_PlayerStart
    jsr JMPBank
.end
    ENDM

    ; Start directly from FX #4
    ; Comment that for the release
    ;lda #23
    ;sta patternidx
    ;lda #3
    ;sta curpart
    ;jmp skippart

main_loop SUBROUTINE

	VERTICAL_SYNC		; 4 scanlines Vertical Sync signal

	; 34 VBlank lines (76 cycles/line)
	lda #39			; (/ (* 34.0 76) 64) = 40.375
	sta TIM64T

    lda #<vblanks
    jsr indirect_jsr
	jsr wait_timint

	; 248 Kernel lines
	lda #19			; (/ (* 248.0 76) 1024) = 18.40
	sta T1024T
    lda #0          ; scanline 33 - cycle 23
    sta VBLANK      ; beam on

    lda #<kernels
    jsr indirect_jsr
	jsr wait_timint		; scanline 289 - cycle 30

	; 26 Overscan lines
	lda #22			; (/ (* 26.0 76) 64) = 30.875
    sta VBLANK      ; beam off
	sta TIM64T

    ; framecnt is useful for all parts
    inc framecnt

    PLAY_THE_MUSIC

    ; Detect pattern change
    dec patternfrm
    bne no_new_pattern
    ; New pattern
    inc patternidx
    lda #PATTERN_LEN
    sta patternfrm
    ;see if we should switch part
    ldx curpart
    lda partswitch,X
    cmp patternidx
    bne no_new_pattern
skippart:
    ;new part - call its init
    inc curpart
    lda #<inits-2
    jmp end_check_pattern

no_new_pattern:
    lda #<overscans
end_check_pattern:
    jsr indirect_jsr

no_overscan:
	jsr wait_timint

	jmp main_loop		; scanline 308 - cycle 15

    ;call with low byte of start of address table
    ;effectively does jsr ( (>vblanks) + A + curpart*2 )
indirect_jsr:
    sta tmp2
    lda #>vblanks
    sta tmp2+1
    lda curpart
    asl
    tay
    lda (tmp2),Y
    sta tmp
    iny
    lda (tmp2),Y
    sta tmp+1   ;tmp2
    jmp JMPBank


; X register must contain the number of scanlines to skip
; X register will have value 0 on exit
wait_timint:
	lda TIMINT
	beq wait_timint
	rts
    echo "framework:", (*-$1000)d, "B"

PARTSTART2 equ *
	INCLUDE "fx.asm"
    echo "fx:", (*-PARTSTART2)d, "B"

;;;-----------------------------------------------------------------------------
;;; Reset Vector


    echo "Bank 7 :", ((RTSBank + $E000) - *)d, "free"

    org RTSBank + $7000
    rorg RTSBank + $E000
    END_SEGMENT_CODE
    ;$1FF4-$1FFB
    .byte 0,0,0,0
    .byte 0,0,0,$4C
    ;$1FFC-1FFF
    .word init
Delay14
    nop
Delay12
    rts
