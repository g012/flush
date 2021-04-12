
.include "globals.inc"

.segment "ZEROPAGE"

; must be first, at $80
schedule:
   .byte 0
temp8:
   .byte 0
temp16:
   .word 0
psmkAttenuation:
   .byte 0
psmkBeatIdx:
   .byte 0
psmkPatternIdx:
   .byte 0
psmkTempoCount:
   .byte 0
   
localramstart:
