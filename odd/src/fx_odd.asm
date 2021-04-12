posa     = fxdata 
tempo    = fxdata + 8
fxtime   = fxdata + 16
fxtimend = fxdata + 32

            MAC SLEEP            ;usage: SLEEP n (n>1)
.CYCLES     SET {1}

                IF .CYCLES < 2
                    ECHO "MACRO ERROR: 'SLEEP': Duration must be > 1"
                    ERR
                ENDIF

                IF .CYCLES & 1
                    IFNCONST NO_ILLEGAL_OPCODES
                        nop 0
                    ELSE
                        bit VSYNC
                    ENDIF
.CYCLES             SET .CYCLES - 3
                ENDIF
            
                REPEAT .CYCLES / 2
                    nop
                REPEND
            ENDM


fx_odd_setup SUBROUTINE
  
                lda #$0
                sta posa
                lda #$8E
                sta COLUP0
                lda #$CE
                sta COLUP1
                LDA #$FA
                STA HMP1
                STA HMOVE
                LDA #$0
                STA HMP0
                
                ;lda #%00000001
                ;sta CTRLPF              ; reflect playfield
                
                lda #5
                sta NUSIZ0
                sta NUSIZ1
                jmp MainLoop

fx_odd_kernel:

    jsr WaitForVBlankEnd
                
                ldx #0
VerticalBlank   sta WSYNC
                inx
                cpx #8
                bne VerticalBlank

meMiddleLines     
 
                SLEEP 21
                sta RESP0    

                SLEEP 2
                sta RESP1
                TYA
                STA tempo
                lda posa
                tay
                lda title,Y+1
                tax
                stx GRP0                
                lda title,Y
                tax
                stx GRP1
                lda tempo
                tay
                sta WSYNC
                
                inc posa
                inc posa

                iny
                cpy #110 ;184
                bne meMiddleLines
                lda #$FA
                sta HMOVE     
                lda #$0
                tax 
                stx GRP0
                stx GRP1
                
                lda #0
                sta posa
                inc fxtime
                lda fxtime
                cmp #$FF
                beq .mefin
                
                jsr WaitForDisplayEnd
                jmp MainLoop
                
.mefin
                inc fxtimend
                lda fxtimend
                cmp #$3
                beq .thefin
                jsr WaitForDisplayEnd
                jmp MainLoop
            
            
.thefin                
                jmp FXNext    
                
                
                
title: ; 96 entries
        byte $00, $00, $00, $02, $00, $06, $08, $04, $10, $04, $20, $08
        byte $20, $08, $18, $06, $00, $00, $80, $01, $00, $00, $00, $00
        byte $20, $00, $20, $00, $20, $00, $20, $00, $20, $00, $20, $00
        byte $40, $00, $80, $00, $00, $01, $00, $02, $00, $08, $0e, $20
        byte $68, $30, $20, $04, $10, $02, $08, $00, $00, $00, $60, $00
        byte $80, $01, $00, $00, $00, $00, $e0, $07, $f0, $0f, $18, $18
        byte $0c, $30, $0c, $30, $0c, $30, $18, $18, $f0, $0f, $e0, $07
        byte $00, $00, $00, $00, $00, $00, $80, $01, $00, $00, $00, $04
        byte $00, $18, $00, $04, $80, $00, $40, $00, $10, $03, $1c, $04
        byte $24, $00, $40, $04, $00, $08, $00, $00, $00, $00, $f0, $1f
        byte $38, $18, $0c, $18, $0c, $18, $0c, $18, $0c, $18, $38, $18
        byte $f0, $1f, $00, $00, $20, $00, $c0, $00, $00, $18, $00, $10
        byte $00, $0c, $00, $02, $20, $00, $20, $00, $60, $00, $40, $00
        byte $00, $01, $30, $01, $00, $01, $08, $01, $08, $01, $00, $03
        byte $00, $00, $00, $00, $00, $00, $f8, $0f, $1c, $0c, $06, $0c
        byte $06, $0c, $06, $0c, $06, $0c, $1c, $0c, $f8, $0f, $00, $00
        byte $00, $00, $00, $00, $80, $03, $00, $06, $00, $08, $00, $08
        byte $00, $10, $40, $10, $00, $10, $10, $18, $20, $00, $a0, $00
        byte $c0, $00, $c0, $00, $00, $06, $00, $08, $80, $10, $38, $00
        byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
    