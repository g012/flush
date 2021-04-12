;;;-----------------------------------------------------------------------------
;;; Header

	PROCESSOR 6502
	INCLUDE "vcs.h"		; Provides RIOT & TIA memory map
	INCLUDE "macro.h"		; This file includes some helper macros

;;; Globals
LINES_COUNT = 24

;;;-----------------------------------------------------------------------------
;;; RAM segment

	SEG.U ram
	ORG $0080
tmp       DS.B 1
ptr       DS.B 2

frame_cnt    DS.B 1 ; Frame counter to keep track of time
lsprite_cptr DS.B 2 ; Pointer to left sprite
missile_optr DS.B 2 ; Pointer to the missile
rsprite_optr DS.B 2 ; Pointer to right sprite
missile_cptr DS.B 2 ; Pointer to the missile
rsprite_cptr DS.B 2 ; Pointer to right sprite

; Fuji logo
fuji_delta_x DS.B 1 ; Direction of Fuji logo along X axis (1 or -1)
fuji_delta_y DS.B 1 ; Direction of Fuji logo along Y axis (1 or -1)

miss_pos_x    DS.B 1
rsprite_pos_x DS.B 1
lsprite_pos_x DS.B 1

;;;-----------------------------------------------------------------------------
;;; Code segment

	SEG code
	ORG $F000
init	CLEAN_START		; Initializes Registers & Memory
	jsr fx_init

main_loop:
	VERTICAL_SYNC		; 4 scanlines Vertical Sync signal

	; 34 VBlank lines (76 cycles/line)
	lda #39			; (/ (* 34.0 76) 64) = 40.375
	sta TIM64T
	jsr fx_vblank
	jsr wait_timint

	; 248 Kernel lines
	lda #19			; (/ (* 248.0 76) 1024) = 18.40
	sta T1024T
	jsr fx_kernel		; scanline 33 - cycle 23
	jsr wait_timint		; scanline 289 - cycle 30

	; 26 Overscan lines
	lda #22			; (/ (* 26.0 76) 64) = 30.875
	sta TIM64T
	jsr fx_overscan
	jsr wait_timint

	jmp main_loop		; scanline 308 - cycle 15


wait_timint:
	lda TIMINT
	beq wait_timint
	rts

	INCLUDE "../fx_shooter.asm"

;;;-----------------------------------------------------------------------------
;;; Reset Vector

	SEG reset
	ORG $FFFC
	DC.W init
	DC.W init
