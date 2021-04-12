LINE_WIDTH = 16
TEXT_SPEED = 5  ; 10 refresh per move

; Memory pointers to playfield framebuffer
pf0_fb = fxdata
pf1_fb = fxdata + 8
pf2_fb = fxdata + 16
pf3_fb = fxdata + 24
pf4_fb = fxdata + 32
pf5_fb = fxdata + 40

; Pointer to the text
text_pt = fxdata + 48
char_off = fxdata + 50	
text_timer = fxdata + 51

;;;;;;;;;;;;;;;;
;
; Setup scroller
;
;;;;;;;;;;;;;;;;

fx_scroll_setup:
    lda #$00
    sta ENABL       ; Turn off ball, missiles and players
    sta ENAM0
    sta ENAM1
    sta GRP0
    sta GRP1
    sta COLUBK      ; Background color (black)
    sta PF0         ; Initializing PFx to 0
    sta PF1
    sta PF2
    lda #$FF        ; Playfield collor (yellow-ish)
    sta COLUPF
    lda #$01        ; Ensure we will duplicate (and not reflect) PF
    sta CTRLPF

    ; Clear frame buffer
    lda #$00
    ldx #$80
clear_loop:
    ;sta fxdata,X
    inx
    cpx #$b0
    bne clear_loop

    ; Initialize text pointer and char offset
    lda #<scroll_text
    sta text_pt
    lda #>scroll_text
    sta text_pt + 1
    lda #0
    sta char_off

    ; Initialize text_timer
    lda #TEXT_SPEED
    sta text_timer

    jmp MainLoop


;;;;;;;;;;;;;;;;;;
;
; Display scroller
;
;;;;;;;;;;;;;;;;;;

Display_scroller:
    ldx #0 ; Index on line to be displayed
FatLine:
    ldy #LINE_WIDTH ; Fat lines are composed of LINE_WIDTH scanlines
Scanline:
    cpx #8; Only one char
    ; cpx #174        ; "HELLO WORLD" = (11 chars x 8 lines - 1) x 2 scanlines =
    bcs ScanlineEnd ;   174 (0 to 173). After that, skip drawing code

    lda pf0_fb,X
    sta PF0
    lda pf1_fb,X
    sta PF1
    lda pf2_fb,X
    sta PF2
ScanlineEnd:
    sta WSYNC       ; Wait for scanline end
    dey
    bne Scanline
    inx             ; Increase counter; repeat untill we got all kernel scanlines
    cpx #191/LINE_WIDTH ;
    bne FatLine
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Scroller logic (Computes the frame buffer)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fx_scroll_kernel:
    lda text_timer
    beq Scroll_text
    jmp Next_frame

Scroll_text:
    ldx #$0
shift_framebuffer:
    ; shift pf0_fb
    lda pf1_fb,X
    and #$80
    lsr pf0_fb,X
    ora pf0_fb,X
    sta pf0_fb,X

    ; shift pf1_fb
    lda pf2_fb,X
    and #$01
    asl pf1_fb,X
    ora pf1_fb,X
    sta pf1_fb,X
    inx
    cpx #8
    bne shift_framebuffer
    
    ; Fetching new line to display
    ldy #0
    lda (text_pt),Y ; Load character to display
    asl           ; Extract offset (without 3 first bits)
    asl           ; And multiply by 8 (8 lines per character)
    asl
    adc char_off  ; Add line offset (within character)
    tay

    ; Load line and move it to PF2 frame buffers
    lda char_data,Y
    tay
    ldx #$00

    ; shift pf2_fb
    ;REPEAT 8
    and #$80
    lsr pf2_fb,X
    ora pf2_fb,X
    sta pf2_fb,X
    inx
    tya
    asl
    tay
    and #$80
    lsr pf2_fb,X
    ora pf2_fb,X
    sta pf2_fb,X
    inx
    tya
    asl
    tay
    and #$80
    lsr pf2_fb,X
    ora pf2_fb,X
    sta pf2_fb,X
    inx
    tya
    asl
    tay
    and #$80
    lsr pf2_fb,X
    ora pf2_fb,X
    sta pf2_fb,X
    inx
    tya
    asl
    tay
    and #$80
    lsr pf2_fb,X
    ora pf2_fb,X
    sta pf2_fb,X
    inx
    tya
    asl
    tay
    and #$80
    lsr pf2_fb,X
    ora pf2_fb,X
    sta pf2_fb,X
    inx
    tya
    asl
    tay
    and #$80
    lsr pf2_fb,X
    ora pf2_fb,X
    sta pf2_fb,X
    inx
    tya
    asl
    tay
    and #$80
    lsr pf2_fb,X
    ora pf2_fb,X
    sta pf2_fb,X
    inx
    tya
    asl
    tay
    ;REPEND

    ; Set pointers to the good character line
    lda char_off
    cmp #$7
    beq .next_character
    inc char_off
    jmp .end_of_chars_setup
.next_character:
    lda #$0
    sta char_off
    ; move text pointer to next character in string
    inc text_pt
    bne .end_of_chars_setup
    inc text_pt+1
.end_of_chars_setup:
    lda #TEXT_SPEED
    sta text_timer

Next_frame:
    dec text_timer
    jsr WaitForVBlankEnd
    jsr Display_scroller 
    jsr WaitForDisplayEnd
    jmp MainLoop


char_data
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %00000110
    dc.b %01111000
    dc.b %10001000
    dc.b %10001000
    dc.b %01111000
    dc.b %00000110
    dc.b %00000000

    dc.b %00000000
    dc.b %11111110
    dc.b %10010010
    dc.b %10010010
    dc.b %01110010
    dc.b %00001100
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %00111000
    dc.b %01000100
    dc.b %10000010
    dc.b %10000010
    dc.b %10000010
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %11111110
    dc.b %10000010
    dc.b %10000010
    dc.b %01000100
    dc.b %00111000
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %11111110
    dc.b %10010010
    dc.b %10010010
    dc.b %10010010
    dc.b %10000010
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %11111111
    dc.b %10010000
    dc.b %10010000
    dc.b %10010000
    dc.b %10000000
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %01111100
    dc.b %10000010
    dc.b %10000010
    dc.b %10010010
    dc.b %00011100
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %11111111
    dc.b %00010000
    dc.b %00010000
    dc.b %00010000
    dc.b %11111111
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %10000010
    dc.b %10000010
    dc.b %11111110
    dc.b %10000010
    dc.b %10000010
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %00000100
    dc.b %10000010
    dc.b %10000010
    dc.b %11111100
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %11111111
    dc.b %00010000
    dc.b %00101000
    dc.b %01000100
    dc.b %10000010
    dc.b %00000001
    dc.b %00000000

    dc.b %00000000
    dc.b %11111110
    dc.b %00000010
    dc.b %00000010
    dc.b %00000010
    dc.b %00000010
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %11111111
    dc.b %01000000
    dc.b %00100000
    dc.b %00010000
    dc.b %00100000
    dc.b %01000000
    dc.b %11111111

    dc.b %00000000
    dc.b %11111111
    dc.b %00100000
    dc.b %00010000
    dc.b %00001000
    dc.b %11111111
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %01111100
    dc.b %10000010
    dc.b %10000010
    dc.b %10000010
    dc.b %01111100
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %11111111
    dc.b %10001000
    dc.b %10001000
    dc.b %10001000
    dc.b %01110000
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %01111000
    dc.b %10000100
    dc.b %10000100
    dc.b %10000110
    dc.b %01111010
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %11111111
    dc.b %10010000
    dc.b %10011000
    dc.b %10010100
    dc.b %01100010
    dc.b %00000001
    dc.b %00000000

    dc.b %00000000
    dc.b %01100100
    dc.b %10010010
    dc.b %10010010
    dc.b %10010010
    dc.b %01001100
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %10000000
    dc.b %10000000
    dc.b %11111111
    dc.b %10000000
    dc.b %10000000
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %11111100
    dc.b %00000010
    dc.b %00000010
    dc.b %00000010
    dc.b %11111100
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %11100000
    dc.b %00011000
    dc.b %00000111
    dc.b %00011000
    dc.b %11100000
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %11100000
    dc.b %00011000
    dc.b %00000111
    dc.b %00011000
    dc.b %00000111
    dc.b %00011000
    dc.b %11100000

    dc.b %00000000
    dc.b %10000010
    dc.b %01101100
    dc.b %00010000
    dc.b %01101100
    dc.b %10000010
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %11000000
    dc.b %00110000
    dc.b %00001111
    dc.b %00110000
    dc.b %11000000
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %10000110
    dc.b %10001010
    dc.b %10010010
    dc.b %10100010
    dc.b %11000010
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %11111010
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %01111100
    dc.b %10000010
    dc.b %10000010
    dc.b %10000010
    dc.b %01111100
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %00000010
    dc.b %01000010
    dc.b %11111110
    dc.b %00000010
    dc.b %00000010
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %01000110
    dc.b %10001010
    dc.b %10010010
    dc.b %01100010
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %01000100
    dc.b %10010010
    dc.b %10010010
    dc.b %01101100
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %00011000
    dc.b %00101000
    dc.b %01001000
    dc.b %11111111
    dc.b %00001000
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %11110100
    dc.b %10010010
    dc.b %10010010
    dc.b %10001100
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %01111100
    dc.b %10010010
    dc.b %10010010
    dc.b %10010010
    dc.b %00001100
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %10000000
    dc.b %10000111
    dc.b %10011000
    dc.b %11100000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %01101100
    dc.b %10010010
    dc.b %10010010
    dc.b %10010010
    dc.b %01101100
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %01100100
    dc.b %10010010
    dc.b %10010010
    dc.b %10010010
    dc.b %01111100
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %00000010
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %00000100
    dc.b %00000100
    dc.b %00000100
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000

    dc.b %00000000
    dc.b %00000100
    dc.b %00001110
    dc.b %00000100
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000



scroll_text
        dc.b    "HELLO VIP[[  "
	dc.b    "GREETS  "
        dc.b    "            "
