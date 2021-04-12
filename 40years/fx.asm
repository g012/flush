; Display one line of graph
	MAC m_one_picline
	lda scrawlbg
	sta WSYNC
	sta COLUBK
	lda scrawlfg
	sta COLUPF
	lda (scrawlptr),Y
	sta PF0
	lda (scrawlptr+2),Y
	sta PF1
	lda (scrawlptr+4),Y
	sta PF2
	lda (scrawlptr+6),Y
	sta PF0
	lda (scrawlptr+8),Y
	sta PF1
	lda (scrawlptr+10),Y
	sta PF2
	ENDM

; Display one line of graph
	MAC m_one_noiseline
	lda buffer+4
	sta COLUBK
	lda buffer+3
	sta COLUPF
	lda buffer+2
	sta PF0
	lda buffer+1
	sta PF1
	lda buffer
	sta PF2
	ENDM

; A must contain the previous value of the xor_shift
; A contains the new xor_shift value on return
; Note: tmp is overwritten
xor_shift SUBROUTINE
	sta tmp
	asl
	eor tmp
	sta tmp
	lsr
	eor tmp
	sta tmp
	asl
	asl
	eor tmp
	rts

; Uses first element of buffer as last xor_shift value
; Fills the buffer with new pseudo-random values
; Note: Uses X register
          MAC fillbuffer
	lda buffer
	jsr xor_shift
	sta buffer+2
	jsr xor_shift
	sta buffer+1
	jsr xor_shift
	sta buffer
	jsr xor_shift
	and #$03
	tax
	lda palette_noise_fg,X
	sta buffer+3 ; COLUPF
	lda palette_noise_bg,X
	sta buffer+4 ; COLUBK
	ENDM

scrawl_update SUBROUTINE
	; Update Scrawl colors
	lda scrawlidx
	jsr xor_shift
	and #$03
	tay
	lda palette_scrawl_bg,Y
	sta scrawlbg
	lda palette_scrawl_fg,Y
	sta scrawlfg

	; Update Scrawl pointers
	lda scrawlidx
	asl
	tay
	lda (scrawlbas),Y
	sta scrawlptr
	iny
	lda (scrawlbas),Y
	sta scrawlptr+1

	ldx #0
	ldy #2
.scrawlptr_init:
	clc
	lda scrawlptr,X
	adc #30
	sta scrawlptr,Y
	lda scrawlptr+1,X
	adc #0
	sta scrawlptr+1,Y
	REPEAT 2
	inx
	iny
	REPEND
	cpy #12
	bne .scrawlptr_init
	rts

fx_init_common SUBROUTINE
	lda #$00
	sta CTRLPF ; No playfield reflection
	sta VDELP0 ; Don't delay players & missiles
	sta VDELP1
	sta VDELBL ; Don't delay ball
	sta ENAM0 ; No missile 0
	sta ENAM1 ; No missile 1
	sta ENABL ; No ball
	sta GRP0 ; No player 0
	sta GRP1 ; No player 1
	sta COLUBK ; Black background

	lda #1
	sta seed
	lda #0
	sta scrawlidx
	jsr scrawl_update
	jmp RTSBank

fx_init_intro SUBROUTINE
	lda #<scrawl_intro
	sta scrawlbas
	lda #>scrawl_intro
	sta scrawlbas+1
	jmp fx_init_common

fx_init_babes SUBROUTINE
	lda #<scrawl_babes
	sta scrawlbas
	lda #>scrawl_babes
	sta scrawlbas+1
	jmp fx_init_common

fx_init_invading SUBROUTINE
	lda #<scrawl_invading
	sta scrawlbas
	lda #>scrawl_invading
	sta scrawlbas+1
	jmp fx_init_common

fx_init_stella SUBROUTINE
	lda #<scrawl_stella
	sta scrawlbas
	lda #>scrawl_stella
	sta scrawlbas+1
	jmp fx_init_common

fx_init_burstday SUBROUTINE
	lda #<scrawl_burstday
	sta scrawlbas
	lda #>scrawl_burstday
	sta scrawlbas+1
	jmp fx_init_common

fx_init_greetz SUBROUTINE
	include "zik/Tu_Ricanes_loop_init.asm"
	lda #<scrawl_greetz
	sta scrawlbas
	lda #>scrawl_greetz
	sta scrawlbas+1
	jmp fx_init_common

fx_vblank SUBROUTINE
	lda seed
	sta rndswitch
	; Random noise data
	sta buffer
	fillbuffer
	jmp RTSBank

fx_kernel SUBROUTINE
	ldy #30 ; 30 stripes
.next_line
	sta WSYNC
	lda #0
	sta COLUPF
	sta COLUBK
	dey
	bpl .not_end
	jmp .end_frame
.not_end:
	; Update rndswitch (used to determine noise/scrawls switch)
	lda rndswitch
	jsr xor_shift
	sta rndswitch
	cmp rndthres
	bcc .picline
	jmp .noiseline
.picline:
	REPEAT 7
	m_one_picline
	REPEND
	jmp .next_line
.noiseline:
          sta WSYNC
	m_one_noiseline
          REPEAT 4
	sta WSYNC
	REPEND
          fillbuffer
	jmp .next_line
.end_frame:
	lda #0
	sta WSYNC
	sta COLUBK
	sta COLUPF
	jmp RTSBank


	MAC state_update_slow
	lda seed
	and #$3F
	bne .no_nextscrawl
	inc scrawlidx
	jsr scrawl_update
.no_nextscrawl:
	lda seed
	and #$3F
	lsr
	tay
	lda scrawl_dynamic,Y
	sta rndthres
	ENDM

	MAC state_update_fast
	lda seed
	and #$1F
	bne .no_nextscrawl
	inc scrawlidx
	jsr scrawl_update
.no_nextscrawl:
	lda seed
	and #$1F
	tay
	lda scrawl_dynamic,Y
	sta rndthres
	ENDM

fx_overscan_slow SUBROUTINE
	lda framecnt
	and #$07
	bne .endos
	inc seed
	state_update_slow
.endos
	jmp RTSBank

fx_overscan_fast SUBROUTINE
	lda framecnt
	and #$07
	bne .endos
	inc seed
	state_update_fast
.endos
	jmp RTSBank


palette_scrawl_bg:
    dc.b $00, $02, $04, $02
palette_scrawl_fg:
    dc.b $06, $08, $0A, $08
palette_noise_bg:
    dc.b $64, $C4, $46, $B6
palette_noise_fg:
    dc.b $6A, $DC, $2A, $9A

scrawl_intro:
    dc.b #<scr_flush_pf0
    dc.b #>scr_flush_pf0
    dc.b #<scr_creds_pf0
    dc.b #>scr_creds_pf0

scrawl_invading:
    dc.b #<scr_racing_pf0
    dc.b #>scr_racing_pf0
    dc.b #<scr_invading_pf0
    dc.b #>scr_invading_pf0

scrawl_babes:
    dc.b #<scr_babes_pf0
    dc.b #>scr_babes_pf0

scrawl_stella:
    dc.b #<scr_stella_pf0
    dc.b #>scr_stella_pf0

scrawl_burstday:
    dc.b #<scr_burst_pf0
    dc.b #>scr_burst_pf0

scrawl_greetz:
    dc.b #<scr_greetz1_pf0
    dc.b #>scr_greetz1_pf0
    dc.b #<scr_greetz2_pf0
    dc.b #>scr_greetz2_pf0
    dc.b #<scr_greetz3_pf0
    dc.b #>scr_greetz3_pf0
    dc.b #<scr_greetz4_pf0
    dc.b #>scr_greetz4_pf0
    dc.b #<scr_greetz5_pf0
    dc.b #>scr_greetz5_pf0
    dc.b #<scr_greetz6_pf0
    dc.b #>scr_greetz6_pf0
    dc.b #<scr_greetz7_pf0
    dc.b #>scr_greetz7_pf0
    dc.b #<scr_greetz8_pf0
    dc.b #>scr_greetz8_pf0
    dc.b #<scr_greetz9_pf0
    dc.b #>scr_greetz9_pf0
;    dc.b #<scr_love_pf0
;    dc.b #>scr_love_pf0

scrawl_dynamic:
    dc.b $00, $00, $20, $40, $60, $80, $A0, $C0
    dc.b $E0, $F0, $F8, $F8, $F8, $F8, $F8, $F8
    dc.b $F8, $F8, $F8, $F8, $F8, $F8, $F0, $E0
    dc.b $C0, $A0, $80, $60, $40, $20, $00, $00

; Scrawl Flush
scr_flush_pf0:
    dc.b $70, $10, $10, $20, $40, $30, $00, $b0
    dc.b $e0, $00, $20, $40, $60, $20, $40, $00
    dc.b $e0, $b0, $e0, $00, $30, $30, $30, $30
    dc.b $30, $30, $f0, $30, $f0, $e0
scr_flush_pf1:
    dc.b $c5, $a5, $a4, $a4, $a4, $6d, $00, $f7
    dc.b $9c, $00, $92, $a4, $a4, $a5, $a5, $00
    dc.b $ff, $55, $ff, $00, $39, $7b, $63, $63
    dc.b $63, $63, $63, $63, $63, $63
scr_flush_pf2:
    dc.b $80, $40, $59, $59, $42, $83, $00, $95
    dc.b $ff, $00, $11, $31, $51, $52, $52, $00
    dc.b $ff, $ac, $ff, $00, $39, $73, $62, $62
    dc.b $62, $72, $3a, $1a, $1a, $72
scr_flush_pf3:
    dc.b $80, $50, $50, $90, $00, $10, $00, $90
    dc.b $f0, $00, $a0, $90, $b0, $90, $a0, $00
    dc.b $f0, $50, $f0, $00, $b0, $b0, $b0, $b0
    dc.b $b0, $b0, $f0, $b0, $b0, $b0
scr_flush_pf4:
    dc.b $1a, $aa, $aa, $9b, $88, $b1, $00, $5e
    dc.b $f3, $00, $49, $52, $52, $5a, $92, $00
    dc.b $ff, $ca, $ff, $00, $56, $27, $53, $21
    dc.b $50, $20, $50, $20, $50, $20
scr_flush_pf5:
    dc.b $a5, $a9, $a9, $64, $a4, $a8, $00, $df
    dc.b $79, $00, $44, $25, $65, $25, $49, $00
    dc.b $7f, $d5, $7f, $00, $c4, $e4, $75, $35
    dc.b $15, $15, $15, $15, $15, $15

; Scrawl Credits
scr_creds_pf0:
    dc.b $f0, $90, $f0, $90, $f0, $00, $f0, $50
    dc.b $a0, $50, $f0, $00, $40, $20, $60, $20
    dc.b $40, $00, $20, $20, $20, $20, $70, $00
    dc.b $10, $90, $b0, $90, $b0, $00
scr_creds_pf1:
    dc.b $fe, $22, $fc, $25, $fd, $00, $ff, $ab
    dc.b $24, $ab, $ff, $00, $a4, $aa, $4a, $aa
    dc.b $a4, $00, $84, $4a, $4a, $4a, $e4, $00
    dc.b $96, $25, $34, $24, $14, $00
scr_creds_pf2:
    dc.b $a2, $25, $25, $a8, $28, $00, $33, $aa
    dc.b $ab, $8a, $b3, $00, $92, $89, $99, $89
    dc.b $d2, $00, $11, $11, $33, $55, $33, $00
    dc.b $ad, $b5, $a5, $a5, $a5, $00
scr_creds_pf3:
    dc.b $30, $40, $30, $00, $70, $00, $50, $40
    dc.b $c0, $40, $80, $00, $00, $00, $c0, $00
    dc.b $10, $00, $a0, $90, $b0, $90, $a0, $00
    dc.b $50, $60, $40, $40, $40, $00
scr_creds_pf4:
    dc.b $27, $24, $23, $52, $8b, $00, $a2, $a5
    dc.b $b5, $a5, $32, $00, $46, $45, $67, $55
    dc.b $63, $00, $5f, $56, $5b, $56, $9f, $00
    dc.b $0d, $15, $d5, $11, $0c, $00
scr_creds_pf5:
    dc.b $ff, $92, $ff, $92, $ff, $00, $a4, $aa
    dc.b $6a, $aa, $aa, $00, $4a, $2a, $66, $2a
    dc.b $4a, $00, $ff, $db, $b6, $db, $ff, $00
    dc.b $e9, $2a, $6b, $8a, $6b, $00

; Scrawl Happy Burstday
scr_burst_pf0:
    dc.b $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0
    dc.b $00, $40, $40, $70, $50, $70, $00, $f0
    dc.b $10, $50, $50, $10, $50, $50, $10, $f0
    dc.b $00, $50, $50, $70, $50, $50
scr_burst_pf1:
    dc.b $c7, $e7, $e7, $27, $27, $c7, $27, $c7
    dc.b $00, $ff, $00, $ee, $a8, $ae, $0a, $ee
    dc.b $20, $b7, $d5, $17, $d4, $b4, $20, $e8
    dc.b $08, $ee, $aa, $ee, $20, $ef
scr_burst_pf2:
    dc.b $cf, $c1, $c1, $c1, $c1, $cf, $c1, $8f
    dc.b $00, $ff, $00, $57, $51, $77, $05, $f7
    dc.b $10, $fe, $00, $2e, $2a, $ea, $00, $71
    dc.b $41, $77, $55, $57, $00, $ff
scr_burst_pf3:
    dc.b $30, $30, $30, $30, $30, $f0, $30, $f0
    dc.b $00, $f0, $00, $e0, $a0, $e0, $00, $f0
    dc.b $80, $f0, $00, $e0, $80, $e0, $20, $e0
    dc.b $00, $f0, $10, $d0, $10, $f0
scr_burst_pf4:
    dc.b $9e, $9e, $9e, $9e, $9e, $9e, $9f, $1e
    dc.b $00, $ff, $18, $5a, $42, $67, $40, $6f
    dc.b $09, $ff, $00, $27, $25, $77, $01, $7d
    dc.b $44, $d7, $10, $ff, $00, $ff
scr_burst_pf5:
    dc.b $e4, $e4, $04, $e4, $e4, $e5, $e6, $e4
    dc.b $00, $ff, $00, $ea, $2a, $ee, $aa, $ea
    dc.b $00, $ef, $80, $ee, $aa, $ae, $08, $ee
    dc.b $20, $bf, $80, $ff, $00, $ff

; Greetings
scr_greetz1_pf0:
    dc.b $10, $90, $b0, $80, $00, $00, $00, $f0
    dc.b $10, $50, $10, $f0, $00, $00, $f0, $00
    dc.b $f0, $00, $f0, $00, $00, $f0, $00, $60
    dc.b $50, $50, $10, $70, $00, $f0
scr_greetz1_pf1:
    dc.b $b3, $28, $99, $0a, $89, $00, $00, $ab
    dc.b $aa, $bb, $a8, $a8, $00, $00, $fb, $02
    dc.b $fb, $02, $fa, $00, $00, $ff, $00, $8d
    dc.b $89, $6d, $09, $0d, $00, $ff
scr_greetz1_pf2:
    dc.b $68, $25, $6c, $04, $09, $00, $00, $dd
    dc.b $55, $dd, $00, $00, $00, $00, $24, $55
    dc.b $64, $44, $34, $00, $00, $ff, $00, $49
    dc.b $48, $5d, $00, $01, $00, $ff
scr_greetz1_pf3:
    dc.b $20, $20, $70, $00, $00, $00, $00, $d0
    dc.b $50, $50, $50, $50, $00, $00, $30, $50
    dc.b $30, $10, $10, $00, $00, $f0, $00, $50
    dc.b $50, $30, $00, $00, $00, $f0
scr_greetz1_pf4:
    dc.b $48, $a8, $ac, $a0, $40, $00, $00, $74
    dc.b $55, $57, $00, $00, $00, $00, $93, $a8
    dc.b $9b, $88, $b3, $00, $00, $ff, $00, $6c
    dc.b $a2, $ae, $88, $e6, $00, $ff
scr_greetz1_pf5:
    dc.b $d5, $55, $dd, $00, $01, $00, $00, $fa
    dc.b $8a, $ab, $88, $f8, $00, $00, $ff, $00
    dc.b $ff, $00, $ff, $00, $00, $ff, $00, $c4
    dc.b $a4, $ae, $a0, $60, $00, $ff

scr_greetz2_pf0:
    dc.b $00, $f0, $00, $f0, $00, $f0, $00, $f0
    dc.b $10, $50, $90, $d0, $50, $90, $10, $f0
    dc.b $00, $f0, $f0, $00, $f0, $f0, $00, $f0
    dc.b $00, $70, $40, $70, $50, $70
scr_greetz2_pf1:
    dc.b $00, $ee, $01, $ef, $08, $e7, $00, $ff
    dc.b $00, $32, $44, $74, $54, $22, $00, $ff
    dc.b $00, $45, $48, $2d, $09, $04, $00, $ff
    dc.b $c0, $dd, $11, $9d, $95, $dd
scr_greetz2_pf2:
    dc.b $00, $24, $5a, $42, $42, $42, $00, $ff
    dc.b $00, $22, $52, $52, $52, $27, $00, $ff
    dc.b $00, $14, $a5, $b5, $90, $a1, $00, $ef
    dc.b $28, $bb, $80, $93, $92, $bb
scr_greetz2_pf3:
    dc.b $00, $50, $50, $50, $c0, $50, $00, $f0
    dc.b $00, $50, $50, $30, $50, $30, $00, $f0
    dc.b $00, $90, $40, $90, $00, $c0, $00, $b0
    dc.b $a0, $e0, $00, $a0, $a0, $e0
scr_greetz2_pf4:
    dc.b $00, $27, $69, $ab, $28, $27, $00, $ff
    dc.b $00, $09, $15, $15, $14, $08, $00, $ff
    dc.b $00, $29, $aa, $91, $80, $00, $00, $fe
    dc.b $06, $77, $10, $76, $52, $73
scr_greetz2_pf5:
    dc.b $00, $fe, $00, $fe, $00, $fe, $00, $ff
    dc.b $80, $b2, $8a, $b9, $a8, $90, $80, $ff
    dc.b $00, $f4, $f2, $06, $f2, $f4, $00, $c0
    dc.b $c0, $ff, $03, $eb, $a8, $fc

scr_greetz3_pf0:
    dc.b $00, $f0, $90, $70, $f0, $f0, $f0, $00
    dc.b $00, $f0, $00, $f0, $00, $f0, $00, $00
    dc.b $f0, $e0, $e0, $f0, $00, $f0, $00, $60
    dc.b $50, $50, $10, $70, $00, $f0
scr_greetz3_pf1:
    dc.b $00, $fc, $fc, $7c, $9c, $e5, $fc, $00
    dc.b $00, $d2, $12, $d3, $12, $bb, $00, $00
    dc.b $c2, $c2, $c2, $df, $00, $ff, $00, $8d
    dc.b $89, $6d, $09, $0d, $00, $ff
scr_greetz3_pf2:
    dc.b $00, $26, $21, $21, $c1, $03, $01, $00
    dc.b $00, $55, $55, $dc, $55, $48, $00, $00
    dc.b $08, $88, $88, $fb, $00, $ff, $00, $49
    dc.b $48, $5d, $00, $01, $00, $ff
scr_greetz3_pf3:
    dc.b $00, $c0, $20, $e0, $20, $20, $20, $00
    dc.b $00, $90, $90, $80, $90, $d0, $00, $00
    dc.b $80, $80, $80, $f0, $00, $f0, $00, $50
    dc.b $50, $30, $00, $00, $00, $f0
scr_greetz3_pf4:
    dc.b $00, $1b, $a2, $23, $23, $23, $23, $00
    dc.b $00, $1a, $2a, $2b, $2a, $b3, $00, $00
    dc.b $40, $7f, $40, $7f, $00, $ff, $00, $6c
    dc.b $a2, $ae, $88, $e6, $00, $ff
scr_greetz3_pf5:
    dc.b $00, $ff, $fe, $f9, $e7, $9f, $ff, $00
    dc.b $00, $fd, $01, $fc, $01, $fc, $00, $00
    dc.b $fc, $7d, $7d, $fd, $00, $ff, $00, $c4
    dc.b $a4, $ae, $a0, $60, $00, $ff

scr_greetz4_pf0:
    dc.b $00, $70, $40, $f0, $f0, $40, $70, $00
    dc.b $f0, $00, $e0, $00, $e0, $00, $e0, $00
    dc.b $c0, $40, $40, $00, $00, $00, $00, $f0
    dc.b $00, $70, $40, $70, $50, $70
scr_greetz4_pf1:
    dc.b $00, $63, $36, $1c, $1c, $36, $63, $00
    dc.b $ff, $00, $f9, $00, $f9, $01, $f9, $00
    dc.b $ab, $aa, $bb, $00, $00, $00, $00, $ff
    dc.b $c0, $dd, $11, $9d, $95, $dd
scr_greetz4_pf2:
    dc.b $00, $c0, $c0, $de, $de, $c0, $c0, $00
    dc.b $ff, $00, $bb, $8a, $bb, $80, $83, $00
    dc.b $dd, $45, $dd, $15, $dd, $00, $00, $ef
    dc.b $28, $bb, $80, $93, $92, $bb
scr_greetz4_pf3:
    dc.b $00, $80, $80, $a0, $f0, $d0, $80, $00
    dc.b $f0, $00, $b0, $80, $b0, $20, $30, $00
    dc.b $d0, $50, $d0, $10, $10, $00, $00, $b0
    dc.b $a0, $e0, $00, $a0, $a0, $e0
scr_greetz4_pf4:
    dc.b $00, $7b, $63, $63, $7b, $63, $7b, $00
    dc.b $ff, $00, $5d, $51, $dd, $14, $1c, $00
    dc.b $9f, $80, $9f, $80, $9f, $00, $00, $fe
    dc.b $06, $77, $10, $76, $52, $73
scr_greetz4_pf5:
    dc.b $00, $e4, $24, $f4, $f6, $25, $e4, $00
    dc.b $ff, $00, $38, $20, $3b, $08, $38, $00
    dc.b $7f, $00, $7f, $00, $7f, $00, $00, $c0
    dc.b $c0, $ff, $03, $eb, $a8, $fc

scr_greetz5_pf0:
    dc.b $00, $70, $00, $70, $00, $70, $00, $00
    dc.b $70, $70, $70, $70, $70, $00, $00, $b0
    dc.b $90, $b0, $80, $80, $00, $f0, $00, $60
    dc.b $50, $50, $10, $70, $00, $f0
scr_greetz5_pf1:
    dc.b $00, $f9, $f9, $f9, $c1, $f9, $00, $00
    dc.b $45, $29, $10, $28, $44, $00, $00, $76
    dc.b $52, $53, $00, $00, $00, $ff, $00, $8d
    dc.b $89, $6d, $09, $0d, $00, $ff
scr_greetz5_pf2:
    dc.b $00, $cf, $8f, $8f, $89, $cf, $00, $00
    dc.b $88, $88, $87, $45, $22, $00, $00, $b6
    dc.b $92, $b6, $12, $32, $00, $ff, $00, $49
    dc.b $48, $5d, $00, $01, $00, $ff
scr_greetz5_pf3:
    dc.b $00, $30, $10, $10, $10, $30, $00, $00
    dc.b $80, $80, $00, $10, $20, $00, $00, $00
    dc.b $80, $90, $80, $00, $00, $f0, $00, $50
    dc.b $50, $30, $00, $00, $00, $f0
scr_greetz5_pf4:
    dc.b $00, $c9, $c9, $c9, $c9, $f9, $00, $00
    dc.b $14, $12, $e1, $a2, $44, $00, $00, $19
    dc.b $95, $95, $95, $19, $00, $ff, $00, $6c
    dc.b $a2, $ae, $88, $e6, $00, $ff
scr_greetz5_pf5:
    dc.b $00, $ef, $01, $ef, $09, $ef, $00, $00
    dc.b $f2, $f1, $f0, $f1, $f2, $00, $00, $a8
    dc.b $a8, $ea, $ad, $48, $00, $ff, $00, $c4
    dc.b $a4, $ae, $a0, $60, $00, $ff

scr_greetz6_pf0:
    dc.b $00, $30, $70, $f0, $b0, $30, $30, $00
    dc.b $00, $f0, $d0, $b0, $70, $f0, $00, $00
    dc.b $f0, $00, $f0, $00, $f0, $00, $00, $f0
    dc.b $00, $70, $40, $70, $50, $70
scr_greetz6_pf1:
    dc.b $00, $6c, $ee, $ef, $6d, $6c, $67, $00
    dc.b $00, $92, $92, $93, $92, $bb, $00, $00
    dc.b $f9, $01, $f9, $01, $f9, $00, $00, $ff
    dc.b $c0, $dd, $11, $9d, $95, $dd
scr_greetz6_pf2:
    dc.b $00, $36, $37, $b7, $f6, $76, $33, $00
    dc.b $00, $65, $15, $14, $15, $14, $00, $00
    dc.b $ba, $aa, $aa, $aa, $bb, $00, $00, $ef
    dc.b $28, $bb, $80, $93, $92, $bb
scr_greetz6_pf3:
    dc.b $00, $60, $60, $60, $70, $70, $60, $00
    dc.b $00, $30, $50, $50, $50, $60, $00, $00
    dc.b $e0, $20, $20, $20, $e0, $00, $00, $b0
    dc.b $a0, $e0, $00, $a0, $a0, $e0
scr_greetz6_pf4:
    dc.b $00, $c6, $c6, $d6, $fe, $ee, $c6, $00
    dc.b $00, $c9, $a9, $c9, $a9, $cb, $00, $00
    dc.b $73, $40, $73, $50, $73, $00, $00, $fe
    dc.b $06, $77, $10, $76, $52, $73
scr_greetz6_pf5:
    dc.b $00, $63, $77, $7f, $6b, $63, $3e, $00
    dc.b $00, $fc, $dc, $ac, $f4, $fd, $00, $00
    dc.b $ff, $00, $ff, $00, $ff, $00, $00, $c0
    dc.b $c0, $ff, $03, $eb, $a8, $fc

scr_greetz7_pf0:
    dc.b $f0, $10, $d0, $10, $f0, $10, $f0, $00
    dc.b $70, $70, $70, $70, $70, $00, $70, $70
    dc.b $70, $70, $70, $70, $00, $f0, $00, $60
    dc.b $50, $50, $10, $70, $00, $f0
scr_greetz7_pf1:
    dc.b $ec, $2c, $af, $af, $ad, $2f, $e7, $00
    dc.b $97, $91, $e7, $95, $95, $00, $e6, $f6
    dc.b $36, $37, $36, $33, $00, $ff, $00, $8d
    dc.b $89, $6d, $09, $0d, $00, $ff
scr_greetz7_pf2:
    dc.b $38, $7c, $6c, $7d, $7d, $7d, $38, $00
    dc.b $ee, $22, $e2, $a2, $e2, $00, $72, $1a
    dc.b $1a, $1b, $1a, $71, $00, $ff, $00, $49
    dc.b $48, $5d, $00, $01, $00, $ff
scr_greetz7_pf3:
    dc.b $b0, $b0, $b0, $b0, $b0, $f0, $f0, $00
    dc.b $e0, $a0, $e0, $80, $e0, $00, $10, $00
    dc.b $90, $90, $10, $10, $00, $f0, $00, $50
    dc.b $50, $30, $00, $00, $00, $f0
scr_greetz7_pf4:
    dc.b $b6, $b6, $b4, $b8, $b8, $b4, $36, $00
    dc.b $47, $45, $47, $41, $77, $00, $1a, $1a
    dc.b $9a, $9a, $1c, $1a, $00, $ff, $00, $6c
    dc.b $a2, $ae, $88, $e6, $00, $ff
scr_greetz7_pf5:
    dc.b $ff, $81, $bf, $a1, $bd, $81, $ff, $00
    dc.b $ea, $ea, $ea, $ea, $ee, $00, $eb, $eb
    dc.b $eb, $eb, $e7, $eb, $00, $ff, $00, $c4
    dc.b $a4, $ae, $a0, $60, $00, $ff

scr_greetz8_pf0:
    dc.b $00, $f0, $00, $f0, $00, $f0, $00, $f0
    dc.b $00, $f0, $00, $f0, $00, $f0, $00, $f0
    dc.b $00, $f0, $00, $f0, $00, $f0, $00, $f0
    dc.b $00, $70, $40, $70, $50, $70
scr_greetz8_pf1:
    dc.b $00, $ff, $00, $fd, $01, $fd, $01, $fb
    dc.b $00, $dd, $04, $dd, $15, $dd, $01, $fd
    dc.b $00, $ff, $00, $ff, $00, $ff, $00, $ff
    dc.b $c0, $dd, $11, $9d, $95, $dd
scr_greetz8_pf2:
    dc.b $00, $ff, $00, $94, $54, $4c, $54, $4d
    dc.b $00, $ff, $00, $ca, $4a, $db, $42, $43
    dc.b $00, $b7, $a0, $b7, $10, $b7, $00, $ef
    dc.b $28, $bb, $80, $93, $92, $bb
scr_greetz8_pf3:
    dc.b $00, $f0, $00, $80, $50, $50, $50, $90
    dc.b $00, $f0, $00, $50, $50, $d0, $40, $c0
    dc.b $00, $a0, $20, $60, $00, $e0, $00, $b0
    dc.b $a0, $e0, $00, $a0, $a0, $e0
scr_greetz8_pf4:
    dc.b $00, $ff, $00, $57, $60, $57, $50, $57
    dc.b $00, $bb, $08, $bb, $aa, $bb, $82, $83
    dc.b $00, $ff, $00, $ff, $00, $ff, $00, $fe
    dc.b $06, $77, $10, $76, $52, $73
scr_greetz8_pf5:
    dc.b $00, $ff, $00, $ff, $00, $ff, $00, $ff
    dc.b $00, $ff, $00, $fd, $00, $fd, $01, $fd
    dc.b $00, $ff, $00, $ff, $00, $ff, $00, $df
    dc.b $c0, $ff, $03, $eb, $a8, $fc

scr_greetz9_pf0:
    dc.b $70, $f0, $00, $f0, $00, $f0, $00, $f0
    dc.b $00, $e0, $20, $a0, $20, $e0, $00, $b0
    dc.b $b0, $b0, $30, $f0, $00, $f0, $00, $60
    dc.b $50, $50, $10, $70, $00, $f0
scr_greetz9_pf1:
    dc.b $3c, $7e, $73, $77, $76, $70, $7c, $3e
    dc.b $00, $f8, $05, $55, $05, $f9, $00, $dd
    dc.b $51, $d9, $50, $5d, $01, $ff, $00, $8d
    dc.b $89, $6d, $09, $0d, $00, $ff
scr_greetz9_pf2:
    dc.b $ec, $ee, $ee, $7e, $3e, $ce, $4e, $3e
    dc.b $00, $7f, $80, $aa, $80, $aa, $00, $92
    dc.b $92, $93, $10, $bb, $03, $ff, $00, $49
    dc.b $48, $5d, $00, $01, $00, $ff
scr_greetz9_pf3:
    dc.b $c0, $e0, $e0, $e0, $e0, $e0, $e0, $c0
    dc.b $00, $a0, $20, $20, $e0, $20, $00, $20
    dc.b $20, $60, $20, $e0, $00, $f0, $00, $50
    dc.b $50, $30, $00, $00, $00, $f0
scr_greetz9_pf4:
    dc.b $e1, $e1, $e3, $07, $ef, $ee, $0e, $e6
    dc.b $00, $44, $1d, $e5, $05, $54, $00, $8b
    dc.b $8a, $eb, $00, $7f, $7f, $ff, $00, $6c
    dc.b $a2, $ae, $88, $e6, $00, $ff
scr_greetz9_pf5:
    dc.b $f3, $03, $f3, $07, $f6, $06, $f6, $e2
    dc.b $00, $7f, $00, $57, $00, $7f, $00, $dd
    dc.b $c4, $ed, $c4, $dd, $01, $ff, $00, $c4
    dc.b $a4, $ae, $a0, $60, $00, $ff

;; We love VCS
;scr_love_pf0:
;    dc.b $f0, $b0, $f0, $b0, $b0, $b0, $30, $70
;    dc.b $70, $70, $10, $f0, $00, $60, $a0, $60
;    dc.b $20, $20, $00, $e0, $00, $20, $60, $a0
;    dc.b $20, $20, $20, $20, $20, $00
;scr_love_pf1:
;    dc.b $80, $a2, $a2, $b3, $aa, $b2, $80, $b1
;    dc.b $8a, $9b, $aa, $91, $00, $24, $54, $54
;    dc.b $04, $0e, $00, $ff, $00, $5e, $d0, $50
;    dc.b $50, $5e, $50, $50, $5e, $00
;scr_love_pf2:
;    dc.b $00, $65, $15, $15, $11, $15, $00, $95
;    dc.b $54, $4d, $54, $8d, $00, $55, $40, $40
;    dc.b $00, $40, $00, $ff, $00, $20, $70, $f8
;    dc.b $fc, $fc, $fe, $de, $8c, $00
;scr_love_pf3:
;    dc.b $00, $90, $50, $90, $00, $d0, $00, $40
;    dc.b $50, $50, $50, $c0, $00, $30, $40, $20
;    dc.b $10, $60, $00, $f0, $00, $00, $00, $00
;    dc.b $10, $10, $30, $30, $10, $00
;scr_love_pf4:
;    dc.b $0c, $00, $8c, $8f, $80, $3f, $00, $91
;    dc.b $92, $92, $92, $39, $00, $a2, $a2, $ca
;    dc.b $02, $07, $00, $ff, $00, $20, $21, $52
;    dc.b $52, $52, $8a, $89, $88, $00
;scr_love_pf5:
;    dc.b $fc, $ec, $fc, $ed, $ed, $ed, $8c, $bc
;    dc.b $bd, $bd, $85, $fc, $00, $24, $24, $24
;    dc.b $20, $74, $00, $7f, $00, $3b, $40, $40
;    dc.b $40, $30, $08, $08, $73, $00

scr_babes_pf0:
    dc.b $00, $e0, $20, $20, $20, $20, $20, $20
    dc.b $20, $20, $e0, $00, $e0, $20, $e0, $00
    dc.b $f0, $00, $60, $a0, $60, $20, $20, $80
    dc.b $00, $20, $20, $60, $a0, $60
scr_babes_pf1:
    dc.b $00, $ff, $00, $d3, $d6, $d6, $d6, $f6
    dc.b $e3, $00, $ff, $00, $ff, $00, $ff, $00
    dc.b $ff, $00, $22, $54, $56, $04, $00, $ff
    dc.b $00, $55, $55, $76, $55, $26
scr_babes_pf2:
    dc.b $00, $ff, $00, $b8, $8d, $8d, $8d, $8d
    dc.b $0c, $00, $ff, $00, $ff, $00, $ff, $00
    dc.b $ff, $00, $28, $54, $44, $00, $00, $ff
    dc.b $00, $44, $44, $e4, $a4, $ae
scr_babes_pf3:
    dc.b $00, $f0, $00, $50, $50, $70, $70, $50
    dc.b $30, $00, $f0, $00, $f0, $00, $f0, $00
    dc.b $f0, $00, $60, $50, $30, $00, $00, $f0
    dc.b $00, $00, $c0, $00, $c0, $00
scr_babes_pf4:
    dc.b $07, $fc, $01, $d1, $d0, $d1, $d1, $f0
    dc.b $e0, $07, $f7, $13, $f0, $00, $ff, $00
    dc.b $ff, $00, $45, $85, $c1, $84, $00, $ff
    dc.b $00, $06, $c8, $08, $c8, $08
scr_babes_pf5:
    dc.b $ef, $a8, $ab, $8b, $90, $93, $a3, $a7
    dc.b $ae, $ac, $ae, $a7, $e0, $00, $7f, $40
    dc.b $7f, $00, $54, $01, $b8, $a9, $a8, $ef
    dc.b $00, $55, $55, $57, $55, $32

scr_stella_pf0:
    dc.b $00, $20, $40, $80, $40, $20, $40, $80
    dc.b $40, $20, $00, $e0, $b0, $50, $b0, $50
    dc.b $b0, $50, $e0, $00, $e0, $00, $c0, $00
    dc.b $c0, $20, $a0, $20, $c0, $00
scr_stella_pf1:
    dc.b $00, $3a, $42, $42, $42, $42, $52, $52
    dc.b $42, $42, $00, $ff, $55, $aa, $55, $aa
    dc.b $55, $aa, $ff, $00, $e0, $10, $d2, $12
    dc.b $e2, $02, $e2, $00, $f7, $00
scr_stella_pf2:
    dc.b $00, $84, $4a, $51, $51, $d1, $55, $55
    dc.b $51, $91, $00, $ff, $aa, $55, $aa, $55
    dc.b $aa, $55, $ff, $00, $c1, $21, $a5, $25
    dc.b $e5, $25, $a5, $21, $cf, $00
scr_stella_pf3:
    dc.b $00, $f0, $00, $30, $00, $70, $00, $30
    dc.b $00, $f0, $00, $f0, $a0, $50, $a0, $50
    dc.b $a0, $50, $f0, $00, $70, $00, $10, $00
    dc.b $30, $00, $10, $00, $70, $00
scr_stella_pf4:
    dc.b $00, $7e, $01, $3d, $01, $3e, $40, $5e
    dc.b $40, $3f, $00, $ff, $55, $aa, $55, $aa
    dc.b $55, $aa, $ff, $00, $f7, $84, $84, $84
    dc.b $84, $a5, $a5, $84, $84, $00
scr_stella_pf5:
    dc.b $00, $44, $20, $14, $24, $44, $24, $14
    dc.b $24, $44, $00, $7f, $aa, $d5, $aa, $d5
    dc.b $aa, $d5, $7f, $00, $55, $54, $54, $44
    dc.b $7c, $44, $54, $44, $38, $00

scr_racing_pf0:
    dc.b $f0, $70, $30, $10, $10, $b0, $f0, $00
    dc.b $60, $80, $40, $20, $c0, $10, $f0, $00
    dc.b $00, $c0, $20, $20, $60, $20, $00, $00
    dc.b $00, $00, $00, $00, $00, $00
scr_racing_pf1:
    dc.b $ff, $f7, $66, $32, $26, $77, $ff, $00
    dc.b $55, $55, $5d, $00, $4f, $1a, $ff, $00
    dc.b $00, $53, $54, $76, $45, $42, $00, $eb
    dc.b $eb, $f3, $eb, $71, $00, $00
scr_racing_pf2:
    dc.b $ff, $de, $b3, $a9, $a5, $d2, $7f, $00
    dc.b $33, $08, $1b, $a8, $91, $c7, $ff, $00
    dc.b $00, $3c, $5c, $3c, $5c, $38, $00, $e5
    dc.b $75, $77, $75, $e7, $00, $00
scr_racing_pf3:
    dc.b $f0, $20, $d0, $f0, $00, $60, $60, $60
    dc.b $60, $70, $60, $40, $10, $f0, $f0, $00
    dc.b $00, $f0, $70, $f0, $70, $e0, $00, $e0
    dc.b $e0, $e0, $00, $e0, $00, $00
scr_racing_pf4:
    dc.b $ff, $4f, $f8, $03, $73, $f9, $19, $78
    dc.b $db, $db, $70, $03, $ff, $a4, $ff, $00
    dc.b $00, $ba, $3a, $3e, $3a, $9e, $00, $75
    dc.b $75, $75, $75, $38, $00, $00
scr_racing_pf5:
    dc.b $ff, $c3, $da, $98, $30, $31, $61, $7b
    dc.b $fb, $07, $f0, $3f, $6e, $22, $ff, $00
    dc.b $00, $47, $47, $57, $6f, $46, $00, $0f
    dc.b $0b, $0b, $03, $0f, $00, $00

scr_invading_pf0:
    dc.b $f0, $30, $30, $70, $f0, $f0, $f0, $f0
    dc.b $f0, $f0, $10, $f0, $10, $f0, $10, $f0
    dc.b $50, $70, $50, $70, $50, $70, $50, $f0
    dc.b $10, $f0, $10, $f0, $10, $f0
scr_invading_pf1:
    dc.b $ff, $d9, $51, $53, $57, $57, $57, $57
    dc.b $57, $ff, $20, $ee, $22, $ee, $28, $ee
    dc.b $00, $a9, $aa, $ba, $00, $b8, $38, $fb
    dc.b $0a, $fb, $08, $fb, $08, $ff
scr_invading_pf2:
    dc.b $ff, $9f, $eb, $0b, $03, $27, $0f, $df
    dc.b $ef, $ff, $00, $17, $11, $77, $00, $00
    dc.b $00, $dc, $55, $dd, $10, $1c, $00, $d5
    dc.b $55, $dd, $01, $7d, $7c, $ff
scr_invading_pf3:
    dc.b $f0, $c0, $b0, $80, $00, $20, $80, $d0
    dc.b $b0, $f0, $00, $70, $10, $70, $50, $70
    dc.b $00, $50, $50, $50, $10, $50, $00, $d0
    dc.b $50, $d0, $50, $d0, $40, $f0
scr_invading_pf4:
    dc.b $ff, $f0, $75, $72, $75, $f2, $f5, $f2
    dc.b $f0, $ff, $00, $ea, $8a, $ee, $a0, $ee
    dc.b $02, $ae, $aa, $ee, $00, $ff, $80, $ff
    dc.b $00, $ff, $00, $ff, $00, $ff
scr_invading_pf5:
    dc.b $ff, $e0, $ee, $eb, $ea, $ef, $ea, $ef
    dc.b $e0, $ff, $90, $f7, $94, $f7, $91, $f7
    dc.b $90, $ff, $81, $ff, $81, $ff, $80, $ff
    dc.b $80, $ff, $80, $ff, $80, $ff
