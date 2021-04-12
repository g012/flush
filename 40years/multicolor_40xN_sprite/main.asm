    processor 6502
    include vcs.h
    include sleep.h
    include macro.h

;FPS = 50 or 60
;PAL = 0 or 1
#if FPS==50         ;PAL
VBLNK   equ 48
LINES   equ 228
OVERSCN equ 36
#else               ;NTSC
VBLNK   equ 40
LINES   equ 192
OVERSCN equ 30
#endif

BPM     equ 140
TEMPO   equ (128*8*BPM)/(60*FPS)
SONGDBG equ 0

    ;RAM
    SEG.U VARS
    org $80

frame   ds  1
temp    ds  5

spritekernel equ *

    echo "RAM:", ($100 - *)d, "bytes left"

    include sprite48x3colors.asm
    include build/40x96.asm

    ;ROM
    SEG CODE
BASE equ $1800  ;2K

    ;use a layout that doesn't depend on SPRITEH
    ;this makes the .bin generator in bmpconv simpler
    org BASE
    SPRITE0
    org BASE+$080
    SPRITE1
    org BASE+$100
    SPRITE2
    org BASE+$180
    SPRITE3
    org BASE+$200
    SPRITE4
    org BASE+$280
    ATTR0
    org BASE+$300
    ATTR1
    org BASE+$380
    COL2
    org BASE+$400
    COL1
    org BASE+$480
    include utils.asm
    SPRITE48X3COLORS_LOGIC
    org BASE+$500 ;align
    SPRITE48X3COLORS_KERNEL

Start
    CLEAN_START

main_loop:
	VERTICAL_SYNC		; 4 scanlines Vertical Sync signal

	; 34 VBlank lines (76 cycles/line)
	lda #39			; (/ (* 34.0 76) 64) = 40.375
	sta TIM64T

    inc frame

    jsr sprite48x3colorsLogic
	jsr wait_timint

	; 248 Kernel lines
	lda #19			; (/ (* 248.0 76) 1024) = 18.40
	sta T1024T

    lda #0
    sta WSYNC
    sta HMOVE
    sta VBLANK

    jsr sprite48x3colorsKernel		; scanline 33 - cycle 23
	jsr wait_timint		; scanline 289 - cycle 30

	; 26 Overscan lines
	lda #22			; (/ (* 26.0 76) 64) = 30.875
	sta TIM64T
	;jsr fx_overscan
	jsr wait_timint

	jmp main_loop		; scanline 308 - cycle 15


; X register must contain the number of scanlines to skip
; X register will have value 0 on exit
wait_timint:
	lda TIMINT
	beq wait_timint
	rts

    echo "ROM:", ($1FFC - *)d, "bytes left"

    org $1FFC
    .word Start
Delay14
    nop
Delay12
    rts
