
.include "globals.inc"

.segment "VECTORS"
; nmi removed, because it will never happen on an 6507
.addr reset ; RESET
.addr reset ; IRQ: will only occur with brk

