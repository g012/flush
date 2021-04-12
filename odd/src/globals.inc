
; configuration parameters

.define splashtype 2; 0=off,palette correction:1=no,2=svolli,3=omegamatrix eor,4=omegamatrix ora

; timer values for vblank and overscan are for TIM64TI, screen is for TIM1KTI
; PAL values, determined by trial an error
.define TIMER_VBLANK   $2a
.define TIMER_SCREEN   $13
.define TIMER_OVERSCAN $14

; all symbols visible to other source files

; 0pglobal.s
.globalzp schedule
.globalzp temp8
.globalzp temp16 ; 2 bytes
.globalzp psmkAttenuation
.globalzp psmkBeatIdx
.globalzp psmkPatternIdx
.globalzp psmkTempoCount
.globalzp localramstart

; fx_squares.s
.global   fx_squares

; main.s
.global   reset
.global   waitvblank   ; called with jsr; x,y untouched
.global   waitscreen   ; called with jsr; x,y untouched
.global   waitoverscan ; called with jmp; y untouched

   ;fx_xxx-1, \
.linecont +
   .define partsaddrlist \
   fx_squares-1
.linecont -

