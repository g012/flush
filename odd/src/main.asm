        processor 6502
        include "vcs.h"
        
; TV format switches
PAL             = 1
NTSC            = 0


; HBlank:  68
; HDraw : 160
;         228
        IF PAL
; <338 scanlines>
; [  3]  VSYNC
; [ 40]  VBLANK
; [256] HB HDRAW
; [ 36]  OVERSCAN
TIM_VBLANK      = 43
TIM_OVERSCAN    = 36
TIM_KERNEL      = 19 ; 256
DISP_SCANLINES  = 242
        ELSE
; <288 scanlines>
; [  3]  VSYNC
; [ 42]  VBLANK
; [202] HB HDRAW
; [ 38]  OVERSCAN
TIM_VBLANK      = 45
TIM_OVERSCAN    = 38
TIM_KERNEL      = 15 ; 202
DISP_SCANLINES  = 192
        ENDIF


; =====================================================================
; Variables
; =====================================================================

        SEG.U   variables
        ORG     $80

        include "song_variables.asm"

; index of current fx
demofxix    ds 1
; frame counter
time        ds 2
; fx ram start
fxdata      ds 1

; =====================================================================
; Start of code
; =====================================================================

        SEG     Bank0
        ORG     $f000

Start   SUBROUTINE

        ; Clear zeropage        
        cld
        ldx #0
        txa
.clearLoop:
        dex
        txs
        pha
        bne .clearLoop

        include "song_init.asm"

        sta WSYNC
        lda #2
        sta VBLANK
        lda #TIM_OVERSCAN
        sta TIM64T

        dec demofxix
        jmp FXNext

; =====================================================================
; MAIN LOOP
; =====================================================================

MainLoop:

; ---------------------------------------------------------------------
; Overscan
; ---------------------------------------------------------------------

; wait for beam to finish overscan and start vsync
WaitForOverscanEnd:
        lda INTIM
        bne WaitForOverscanEnd

        inc time
        bne VBlank
        inc time+1

; ---------------------------------------------------------------------
; VBlank
; ---------------------------------------------------------------------

VBlank  SUBROUTINE
        ; get new frame by setting VSYNC:D1 during 3 scanlines then disable it
        lda #%1110
.vsyncLoop:
        sta WSYNC
        sta VSYNC
        lsr
        bne .vsyncLoop 
        lda #%10
        sta VBLANK      ; turn beam off (VBLANK:D1=1)
        lda #TIM_VBLANK ; set vblank duration into timer
        sta TIM64T

        include "song_player.asm"
        
        ; call current fx, at beginning of VBlank
        ldx demofxix
        lda demofxhi,x
        pha
        lda demofxlo,x
        pha
        rts

; wait for the current VBlank to end, after which visible scanlines start
WaitForVBlankEnd:
        lda INTIM
        bne WaitForVBlankEnd
        sta WSYNC
        sta VBLANK      ; turn beam on (VBLANK:D1=0)
        lda #TIM_KERNEL ; set horizontal draw duration into timer
        sta T1024T
        rts

; wait for the end of visible scanlines and start of overscan
WaitForDisplayEnd:
        lda INTIM
        bne WaitForDisplayEnd
        sta WSYNC
        lda #%10
        sta VBLANK      ; turn beam off (VBLANK:D1=1)
        lda #TIM_OVERSCAN ; set overscan duration into timer
        sta TIM64T
        rts

FXNext:
        inc demofxix
        ldx demofxix
        lda demofxsetuphi,x
        pha
        lda demofxsetuplo,x
        pha
        rts

        include "fx_cr.asm"
        include "fx_odd.asm"
	include "fx_scroll.asm"


; =====================================================================
; Data
; =====================================================================

; fx kernel functor table
demofxlo:
        .byte    #<(fx_cr_kernel-1) 
        .byte    #<(fx_odd_kernel-1)
        .byte    #<(fx_scroll_kernel-1) 
demofxhi:
        .byte    #>(fx_cr_kernel-1)
        .byte    #>(fx_odd_kernel-1)
        .byte    #>(fx_scroll_kernel-1)

; fx setup functor table
demofxsetuplo:
        .byte    #<(fx_cr_setup-1) 
        .byte    #<(fx_odd_setup-1) 
        .byte    #<(fx_scroll_setup-1) 
demofxsetuphi:
        .byte    #>(fx_cr_setup-1)
        .byte    #>(fx_odd_setup-1)
        .byte    #>(fx_scroll_setup-1)


        include "song_trackdata.asm"

; =====================================================================
; Vectors
; =====================================================================

        echo "ROM left: ", ($fffc - *)

        ORG             $fffc
        .word   Start
        .word   Start
