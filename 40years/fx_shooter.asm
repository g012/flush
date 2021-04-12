; Parameters
SEED = 1 ; This seed determines the stars positions
SPRITES_ZONE_HEIGHT = 32
SPRITES_HEIGHT = 16

; pointers addition
; 3 = 1 + 2
          MAC ptr_add
          clc
          lda {1}
          adc {2}
          sta {3}
          lda {1}+1
          adc {2}+1
          sta {3}+1
          ENDM
; end


; A must contain the previous value of the xor_shift
; A contains the new xor_shift value on return
; Note: tmp is overwritten
          MAC xor_shift
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
          ENDM
; end


; Macro to horizontally (x)  position missile or sprite
; {1} is the object enable register (i.e ENAM0, ENAM1, ENAP0)
; {2} is the object reset position probe (i.e RESM0, RESM1, RESP0)
; {3} is the object horizontal move register (i.e HMM0, HMM1, HMP0)
; A register must contain the position (integer)
; Y is used (thus overriden)
          MAC m_x_position_ms
          sta WSYNC
          ldy #$00
          sty {1} ; Turn off missile or sprite

          sleep 15 ; Center sprites
          sec
.rough_loop:
          ; The pos_star loop consumes 15 (5*3) pixels
          sbc #$0F        ; 2 cycles
          bcs .rough_loop ; 3 cycles
          sta {2} ; Roughly position missile or sprite
          sta WSYNC ; Next line to recover a deterministic behavior

          ; A register has value is in [-15 .. -1]
          adc #$07 ; A in [-8 .. 6]
          eor #$ff ; A in [-7 .. 7]
          REPEAT 4
          asl
          REPEND
          sta {3} ; Fine position of missile or sprite
          ENDM
; end


; next_star Macro
; tmp contains the offset of the next star
; {1} is the color of next star
          MAC m_next_star
          sec
          lda $01,X ; Load horizontal position of next_star
          sbc tmp   ; Substract offset (to move the stars)
          and #$7f  ; module 128

          m_x_position_ms ENAM0, RESM0, HMM0

          ; We have some cycles there to do some computation
          ; So Updating random position of next star
          lda $01,X
          xor_shift
          sta $01,X

          ; Display star
          sta WSYNC
          sta HMOVE
          lda #$02
          sta ENAM0
          lda {1}
          sta COLUP0
          ENDM
;end


; Drawing stars macro
          MAC draw_stars
          lda framecnt
          sta tmp
          m_next_star #$9e

          lda $02,X
          sta tmp
          m_next_star #$94
          ENDM
; end


; Fill zone with stars.
; X must be equal to stack pointer (i.e tsx being performed prior this call).
; Fetchs the number of stars to draw in the stack $03,X.
; The number of stars drawn is $03,X * 2, cause 2 stars are drawn at
; each loop.
          MAC fill_stars
          sta WSYNC
.stars_loop:
          draw_stars ; This doesn't overwrite X
          ldy $03,X
          dey
          sty $03,X
          beq .end_loop
          jmp .stars_loop
.end_loop
          sta WSYNC
          ENDM
; end


; fill buffer with sprite pointed at by ptr
; {1} is the buffer to fill
; (rsprite or rcolor)
          MAC fill_buffer
          ldx #23
.load_loop:
          txa
          lsr
          tay
          lda (ptr),Y
          sta {1}_buf,X
          dex
          bpl .load_loop
          ENDM
;end


; The type of data to load passed as {1}
; (rsprite or rcolor)
          MAC load_data
          lda rsprite_idx
          and #$07
          tay
          clc
          lda rsprite_table,Y
          adc rsprite_offset
          tay
          lda {1}_ptrl,Y
          sta ptr
          lda {1}_ptrh,Y
          sta ptr + 1
          fill_buffer {1}
          ENDM
; end


; Update rsprite according to rsprite_idx
          MAC update_rsprite
          load_data rsprite
          load_data rcolor
          ENDM
; end


; Reinitialize missile position
          MAC init_missile_position
          ; Missile start at the end of left sprite
          clc
          lda lsprite_pos_x
          adc #6
          sta miss_pos_x

          ; get lsprite_cptr offset and add it to missile
          sec
          lda lsprite_cptr
          sbc #<atari_sprite
          sta ptr
          lda lsprite_cptr+1
          sbc #>atari_sprite
          sta ptr+1
          ptr_add ptr, missile_optr, missile_cptr
          ENDM
; end

; Initialize right sprite position
          MAC init_rsprite_position
          ; Right sprite start at the right of the screen
          lda #$7f-8
          sta rsprite_pos_x
          ENDM
; end


; Sprites scene
; 1st sprite is always Atari
; sprite_ptr variable should contain the address of 2nd sprite
          MAC sprites_scene

          ; Position sprites and missiles
          lda rsprite_pos_x
          m_x_position_ms ENAM0, RESP0, HMP0
          lda lsprite_pos_x
          m_x_position_ms ENAM0, RESP1, HMP1
          lda miss_pos_x
          m_x_position_ms ENAM0, RESM1, HMM1

          ; Set sprite colors
          lda #$0e
          sta COLUP1

          ; Sync and position players and missile
          sta WSYNC
          sta HMOVE

          ; 32 pixels height - sprite zone
          ldx #3
          ldy #31
.upper_loop:
          lda (lsprite_cptr),Y
          sta GRP1
          lda (missile_cptr),Y
          sta ENAM1
          sta WSYNC
          dey
          dex
          bpl .upper_loop

          ldx #23
.center_loop:
          lda (lsprite_cptr),Y
          sta GRP1
          lda (missile_cptr),Y
          sta ENAM1
          lda rsprite_buf,X
          sta GRP0
          lda rcolor_buf,X
          sta COLUP0
          sta WSYNC
          dey
          dex
          bpl .center_loop

          lda #0
          sta GRP0
.lower_loop:
          lda (lsprite_cptr),Y
          sta GRP1
          lda (missile_cptr),Y
          sta ENAM1
          sta WSYNC
          dey
          bpl .lower_loop

          lda #$00
          sta GRP1
          sta GRP0
          ENDM
;end


; Move shooter sprite macro
          MAC move_shooter
          lda #0
          sta ptr + 1
          lda framecnt
          and #$3f
          tax
          lda atari_offset,X
          lsr
          sta ptr
          ptr_add lsprite_optr, ptr, lsprite_cptr

          lda framecnt
          and #$7f
          lsr
          tax
          lda atari_offset,X
          sta lsprite_pos_x
          ENDM
; end


; Update state machine
          MAC update_state
          ; Check for collision
          lda CXM1P
          and #$80
          beq .no_collision
          ; Collision
          sta state ; a = #$80
          sta CXCLR
          jmp .end
.no_collision

          ; Check end of explosion
          lda state
          cmp #$97 ; $80 + 6*4 - 1
          bne .no_endofexplosion
          lda #$00
          sta state
          jmp .end
.no_endofexplosion

          ; By default increase state
          inc state
.end:
          ENDM
; end


; Initialize new right sprite
          MAC new_rsprite
          ; rsprite = (rsprite+1) % 8
          inc rsprite_idx
          nop ; TODO: nasty code alignment issue to fix

          update_rsprite
          init_rsprite_position
          ENDM
; end


; Update sprite according to state
          MAC update_sprite_vs_state
          lda state
          bne .no_newsprite
          ; New sprite
          lda #0
          sta rsprite_offset
          new_rsprite
          jmp .end
.no_newsprite

          and #$80
          beq .no_explosion
          ; During explosion missile disappears
          init_missile_position
          ; Get appropriate explosion sprite
          lda state
          and #$7f
          lsr
          lsr
          sta tmp

          ; Update rsprite
          ldx tmp
          lda esprite_ptrl,X
          sta ptr
          lda esprite_ptrh,X
          sta ptr+1
          fill_buffer rsprite

          ; Update rcolor
          ldx tmp
          lda ecolor_ptrl,X
          sta ptr
          lda ecolor_ptrh,X
          sta ptr+1
          fill_buffer rcolor

          jmp .end
.no_explosion

          ; no new sprite nor explosion
          lda state
          and #$07
          bne .no_spriteupdate
          lda state
          REPEAT 3
          lsr
          REPEND
          and #$01 ; Sprite offset
          sta rsprite_offset
          update_rsprite
.no_spriteupdate
.end
          ENDM
; end


; Main kernel top half
          MAC main_kernel_top
          lda #0
          sta COLUPF

          sta WSYNC ; Sync to avoid jitter

          lda #SEED
          pha ; Stars iterator
          pha ; slow counter
          pha ; pseudo-rnd value

          tsx ; move stack pointer to X
          ; Compute slow counter
          lda framecnt
          lsr
          sta $02,X
          ; Load the number of stars to display
          lda #13 ; 17
          sta $03,X
          fill_stars

          lda #$00
          sta ENAM0
          ENDM
; end

; bottom half
          MAC main_kernel_bottom
          tsx
          lda #8 ; 17
          sta $03,X
          fill_stars

          pla ; Remove temp variables from stack
          pla
          pla

          jsr moonpatrol
          ENDM
; end

moonpatrol SUBROUTINE
          lda #$00
          sta ENAM0
          sta ENAM1

          lda #0
          sta PF0
          sta PF1
          sta PF2
          lda #$c2
          sta COLUPF

          lda patrol_offset
          m_x_position_ms ENAM0, RESP0, HMP0
          lda patrol_offset
          clc
          adc #8
          m_x_position_ms ENAM1, RESP1, HMP1
          sta WSYNC
          sta HMOVE

          ldx #0
.mountaintop
          sta WSYNC
          lda mountain_ram,x
          inx
          sta PF0
          lda mountain_ram,x
          inx
          sta PF1
          lda mountain_ram,x
          inx
          sta PF2
          sta WSYNC
          cpx #18
          bne .mountaintop

          lda #$ff
          sta WSYNC
          sta PF0
          sta PF1
          sta PF2

          ldx #20
.mountain
          sta WSYNC
          dex
          bne .mountain

          lda #$8A
          sta COLUP0
          sta COLUP1

          lda ground_frame
          and #$f0
          ora #15
          tay
          ldx #15
.groundspr:
          sta WSYNC
          lda ground_sprite1_grp0,y
          sta GRP0
          lda ground_sprite1_grp1,y
          sta GRP1
          dey
          dex
          bpl .groundspr

          sta WSYNC
          lda #$36
          sta COLUPF
          lda #0
          sta GRP0
          sta GRP1

          rts


fx_shooter_init:
          ; Initialize sprites pointers
          lda <#atari_sprite
          sta lsprite_optr
          lda >#atari_sprite
          sta lsprite_optr+1

          lda <#missile_sprite
          sta missile_optr
          lda >#missile_sprite
          sta missile_optr+1

          lda #$ff
          sta rsprite_idx
          update_rsprite

          ; Number and size of sprites and missiles
          lda #$00 ; one copy small p0 ; 1 clock stars
          sta NUSIZ0
          lda #$10 ; one copy small p1 ; 2 clocks missile
          sta NUSIZ1

          ; Initialize Playfield for background
          lda #$00 ; 01
          sta CTRLPF ; NO Mirror mode
          lda #$00
          sta PF0
          lda #$ff
          sta PF1
          sta PF2

          ; Initialize part & state
          lda #0
          sta part
          sta state
          sta ground_frame
          sta patrol_offset
          sta patrol_offy

          ; Initialize sprites and missile
          update_sprite_vs_state
          move_shooter
          init_missile_position

          ; Initialize the mountain
          ldx #6*3-1
.copymountain
          lda mountain,x
          sta mountain_ram,x
          dex
          bpl .copymountain

          jmp RTSBank


; Goto next part
          MAC goto_next_part
          inc part
          lda #0
          sta state
          ENDM
; end

; Scroll the mountain left
          MAC fx_shooter_move_mountain
          ldx #6*3-1
.rotate
          stx tmp
          clc
          ror mountain_ram,x
          dex
          rol mountain_ram,x
          dex
          lda mountain_ram,x
          ror
          sta mountain_ram,x
          and #8
          beq .nocarry
          ldy tmp
          lda #$80
          ora mountain_ram,y
          sta mountain_ram,y
.nocarry
          dex
          bpl .rotate
          ENDM
; end

fx_shooter_main_vblank:
          lda #$00
          sta COLUPF
          update_sprite_vs_state
          lda rsprite_idx
          cmp #$0c
          bmi .no_nextpart_main
          goto_next_part
.no_nextpart_main:
          jmp RTSBank

fx_shooter_main_kernel:
          main_kernel_top
          sprites_scene
          main_kernel_bottom
          jmp RTSBank

fx_shooter_main_overscan:
          ; Move sprites, missile and update state
          inc miss_pos_x
          dec rsprite_pos_x
          move_shooter
          update_state
          jmp RTSBank


fx_shooter_flash_vblank:
          lda #$00
          sta COLUPF
          lda state
          and #$c0
          beq .no_nextpart_flash
          goto_next_part
          jmp RTSBank
.no_nextpart_flash:
          ; Flash
          lda state
          lsr
          lsr
          tay
          lda flash_colors,Y
          sta COLUPF
          inc state
          jmp RTSBank

fx_shooter_starfield_vblank:
          lda #$00
          sta COLUPF
          lda state
          and #$80
          beq .no_nextpart_starfield
          goto_next_part
          jmp RTSBank
.no_nextpart_starfield:
          ; Empty playfield
          inc state
          jmp RTSBank

fx_shooter_infstarfield_vblank:
          ; Infinite Empty playfield
          lda #$00
          sta COLUPF
          inc state
          jmp RTSBank

; Wait for framecnt full loop
fx_shooter_sync_vblank:
          lda #$00
          sta COLUPF
          lda framecnt
          cmp #$60 ; When the ship if against the border
          bne .no_nextpart_sync
          move_shooter
          goto_next_part
          jmp RTSBank
.no_nextpart_sync:
          ; Empty playfield
          inc state
          jmp RTSBank

fx_shooter_starfield_kernel:
          main_kernel_top
          ldy #38
.intro_loop:
          sta WSYNC
          dey
          bpl .intro_loop
          main_kernel_bottom
          jmp RTSBank


fx_shooter_blink_kernel:
          main_kernel_top
          ; position Atari sprite
          lda #$00 ; Sprite position
          m_x_position_ms ENAM0, RESP1, HMP1
          ; Set sprite colors
          lda state
          lsr
          lsr
          and #$0f
          tax
          lda blink_colors,X
          sta COLUP1
          ; Sync and position players and missile
          sta WSYNC
          sta HMOVE

          ; Skip a couple of lines
          ldy #3
.blink_skip_loop:
          sta WSYNC
          dey
          bpl .blink_skip_loop

          ; Draw sprite
          ldy #31
.blink_loop:
          lda (lsprite_cptr),Y
          sta GRP1
          sta WSYNC
          dey
          bpl .blink_loop

          main_kernel_bottom
          jmp RTSBank

fx_shooter_empty_overscan:
          jmp RTSBank


; FX entry point - Jump to the appropriate part

fx_shooter_vblank:
          lda #$00
          sta COLUPF
          lda framecnt
          and #1
          bne .mountain_static
          fx_shooter_move_mountain
.mountain_static

          inc ground_frame
          lda ground_frame
          and #$f
          cmp #6
          bne .keep_ground_frame
          lda ground_frame
          clc
          adc #$10
          and #$f0
          cmp #$30
          bne .valid_frame
          lda #0
.valid_frame
          sta ground_frame
.keep_ground_frame

          lda part
          cmp #5
          bcs .step2
          lda #0
          cmp patrol_step
          bne .step1
          inc patrol_offset
          lda patrol_offset
          cmp #115
          lda patrol_step
          adc #0
          sta patrol_step
          inc patrol_offy
          jmp .steps_end
.step1
          dec patrol_offset
          lda patrol_offy
          and #3
          tay
          lda patrol_offset
          cmp patrol_offset_low,y
          lda patrol_step
          sbc #0
          sta patrol_step
          jmp .steps_end
.step2
          lda patrol_offset
          cmp #10
          bcc .steps_end
          dec patrol_offset
.steps_end

          ldx part
          lda parts_vblank_tableh,X
          pha
          lda parts_vblank_tablel,X
          pha
          rts

fx_shooter_kernel:
          ldx part
          lda parts_kernel_tableh,X
          pha
          lda parts_kernel_tablel,X
          pha
          rts

fx_shooter_overscan:
          ldx part
          lda parts_overscan_tableh,X
          pha
          lda parts_overscan_tablel,X
          pha
          rts

;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Data

; Parts pointers
parts_vblank_tablel:
          dc.b #<(fx_shooter_flash_vblank-1)
          dc.b #<(fx_shooter_starfield_vblank-1)
          dc.b #<(fx_shooter_starfield_vblank-1)
          dc.b #<(fx_shooter_sync_vblank-1)
          dc.b #<(fx_shooter_main_vblank-1)
          dc.b #<(fx_shooter_flash_vblank-1)
          dc.b #<(fx_shooter_infstarfield_vblank-1)
parts_vblank_tableh:
          dc.b #>(fx_shooter_flash_vblank-1)
          dc.b #>(fx_shooter_starfield_vblank-1)
          dc.b #>(fx_shooter_starfield_vblank-1)
          dc.b #>(fx_shooter_sync_vblank-1)
          dc.b #>(fx_shooter_main_vblank-1)
          dc.b #>(fx_shooter_flash_vblank-1)
          dc.b #>(fx_shooter_infstarfield_vblank-1)

parts_kernel_tablel:
          dc.b #<(fx_shooter_starfield_kernel-1)
          dc.b #<(fx_shooter_starfield_kernel-1)
          dc.b #<(fx_shooter_blink_kernel-1)
          dc.b #<(fx_shooter_blink_kernel-1)
          dc.b #<(fx_shooter_main_kernel-1)
          dc.b #<(fx_shooter_starfield_kernel-1)
          dc.b #<(fx_shooter_starfield_kernel-1)
parts_kernel_tableh:
          dc.b #>(fx_shooter_starfield_kernel-1)
          dc.b #>(fx_shooter_starfield_kernel-1)
          dc.b #>(fx_shooter_blink_kernel-1)
          dc.b #>(fx_shooter_blink_kernel-1)
          dc.b #>(fx_shooter_main_kernel-1)
          dc.b #>(fx_shooter_starfield_kernel-1)
          dc.b #>(fx_shooter_starfield_kernel-1)

parts_overscan_tablel:
          dc.b #<(fx_shooter_empty_overscan-1)
          dc.b #<(fx_shooter_empty_overscan-1)
          dc.b #<(fx_shooter_empty_overscan-1)
          dc.b #<(fx_shooter_empty_overscan-1)
          dc.b #<(fx_shooter_main_overscan-1)
          dc.b #<(fx_shooter_empty_overscan-1)
          dc.b #<(fx_shooter_empty_overscan-1)
parts_overscan_tableh:
          dc.b #>(fx_shooter_empty_overscan-1)
          dc.b #>(fx_shooter_empty_overscan-1)
          dc.b #>(fx_shooter_empty_overscan-1)
          dc.b #>(fx_shooter_empty_overscan-1)
          dc.b #>(fx_shooter_main_overscan-1)
          dc.b #>(fx_shooter_empty_overscan-1)
          dc.b #>(fx_shooter_empty_overscan-1)

rsprite_table:
          dc.b $00, $02, $04, $06, $08, $0c, $04, $06

rsprite_ptrl:
          dc.b #<nvdr4_sprt ; 0
          dc.b #<nvdr4b_sprt
          dc.b #<nvdr5_sprt ; 2
          dc.b #<nvdr5b_sprt
          dc.b #<nvdr1_sprt ; 4
          dc.b #<nvdr1b_sprt
          dc.b #<nvdr2_sprt ; 6
          dc.b #<nvdr2b_sprt
          dc.b #<nvdr3_sprt ; 8
          dc.b #<nvdr3b_sprt
          dc.b #<commodore_sprt ; a
          dc.b #<commodore_sprt
          dc.b #<nvdr6_sprt ; c
          dc.b #<nvdr6b_sprt
rsprite_ptrh:
          dc.b #>nvdr4_sprt
          dc.b #>nvdr4b_sprt
          dc.b #>nvdr5_sprt
          dc.b #>nvdr5b_sprt
          dc.b #>nvdr1_sprt
          dc.b #>nvdr1b_sprt
          dc.b #>nvdr2_sprt
          dc.b #>nvdr2b_sprt
          dc.b #>nvdr3_sprt
          dc.b #>nvdr3b_sprt
          dc.b #>commodore_sprt
          dc.b #>commodore_sprt
          dc.b #>nvdr6_sprt
          dc.b #>nvdr6b_sprt
rcolor_ptrl:
          dc.b #<nvdr4_colr
          dc.b #<nvdr4b_colr
          dc.b #<nvdr5_colr
          dc.b #<nvdr5b_colr
          dc.b #<nvdr1_colr
          dc.b #<nvdr1_colr
          dc.b #<nvdr2_colr
          dc.b #<nvdr2_colr
          dc.b #<nvdr3_colr
          dc.b #<nvdr3_colr
          dc.b #<commodore_colr
          dc.b #<commodore_colr
          dc.b #<nvdr6_colr
          dc.b #<nvdr6b_colr
rcolor_ptrh:
          dc.b #>nvdr4_colr
          dc.b #>nvdr4b_colr
          dc.b #>nvdr5_colr
          dc.b #>nvdr5b_colr
          dc.b #>nvdr1_colr
          dc.b #>nvdr1_colr
          dc.b #>nvdr2_colr
          dc.b #>nvdr2_colr
          dc.b #>nvdr3_colr
          dc.b #>nvdr3_colr
          dc.b #>commodore_colr
          dc.b #>commodore_colr
          dc.b #>nvdr6_colr
          dc.b #>nvdr6b_colr

; Explosion table
esprite_ptrl:
          dc.b: #<explo1_sprt
          dc.b: #<explo2_sprt
          dc.b: #<explo3_sprt
          dc.b: #<explo4_sprt
          dc.b: #<explo5_sprt
          dc.b: #<explo6_sprt
esprite_ptrh:
          dc.b: #>explo1_sprt
          dc.b: #>explo2_sprt
          dc.b: #>explo3_sprt
          dc.b: #>explo4_sprt
          dc.b: #>explo5_sprt
          dc.b: #>explo6_sprt
ecolor_ptrl:
          dc.b: #<explo1_colr
          dc.b: #<explo2_colr
          dc.b: #<explo3_colr
          dc.b: #<explo4_colr
          dc.b: #<explo5_colr
          dc.b: #<explo6_colr
ecolor_ptrh:
          dc.b: #>explo1_colr
          dc.b: #>explo2_colr
          dc.b: #>explo3_colr
          dc.b: #>explo4_colr
          dc.b: #>explo5_colr
          dc.b: #>explo6_colr

flash_colors:
          dc.b $9e, $9c, $9a, $98, $96, $94, $92, $90
          dc.b $00, $00, $00, $00, $00, $00, $00, $00

blink_colors:
          dc.b $00, $02, $04, $06, $08, $0a, $0c, $0e
          dc.b $0e, $0c, $0a, $08, $06, $04, $02, $00

; Shooter and missile can have a variable height
; We need some filler.
; Displaying in a 32 pixels height zone
; Max 16 pixels sprites + 16 pixels filler
atari_sprite:
          dc.b $00, $00, $00, $00, $00, $00, $00, $00
          dc.b $00, $00, $00, $00, $80, $80, $80, $40
          dc.b $40, $60, $30, $1f, $00, $ff, $ff, $00
          dc.b $1f, $30, $60, $40, $40, $80, $80, $80
missile_sprite:
          dc.b $00, $00, $00, $00, $00, $00, $00, $00
          dc.b $00, $00, $00, $00, $00, $00, $00, $00
          dc.b $00, $00, $00, $00, $00, $00, $02, $00
          dc.b $00, $00, $00, $00, $00, $00, $00, $00
_filler:
          dc.b $00, $00, $00, $00, $00, $00, $00, $00
          dc.b $00, $00, $00, $00, $00, $00, $00, $00
atari_offset:
          dc.b $0c, $0d, $0e, $10, $11, $12, $13, $14
          dc.b $15, $16, $16, $17, $18, $18, $18, $18
          dc.b $18, $18, $18, $18, $18, $17, $16, $16
          dc.b $15, $14, $13, $12, $11, $10, $0e, $0d
          dc.b $0c, $0b, $0a, $08, $07, $06, $05, $04
          dc.b $03, $02, $02, $01, $00, $00, $00, $00
          dc.b $00, $00, $00, $00, $00, $01, $02, $02
          dc.b $03, $04, $05, $06, $07, $08, $0a, $0b

; frame 1
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000110110110000
;          dc.w %0000100110010000
;          dc.w %0001100110011000
;          dc.w %0011000110001100
;          dc.w %0110000110000110
;          dc.w %1100000110000011
;          dc.w %0000000000000000
;          dc.w %0110000000000110
;          dc.w %0000000110000000
; frame 2
;          dc.w %0000000000000000
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000110110110000
;          dc.w %0000100110010000
;          dc.w %0001100110011000
;          dc.w %0011000110001100
;          dc.w %0110000110000110
;          dc.w %1100000110000011
;          dc.w %0000000000000000
;          dc.w %0000001100001100
; frame 3
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000010110100000
;          dc.w %0000110110110000
;          dc.w %0000100110010000
;          dc.w %0001100110011000
;          dc.w %0011000110001100
;          dc.w %0110000110000110
;          dc.w %1100000110000011
;          dc.w %0000000000000000
;          dc.w %0000000000000000
;          dc.w %0000110000110000
ground_sprite1_grp0:
          dc.b %00000001
          dc.b %01100000
          dc.b %00000000
          dc.b %11000001
          dc.b %01100001
          dc.b %00110001
          dc.b %00011001
          dc.b %00001001
          dc.b %00001101
          dc.b %00000101
          dc.b %00000101
          dc.b %00000101
          dc.b %00000101
          dc.b %00000101
          dc.b %00000101
          dc.b %00000101
ground_sprite2_grp0:
          dc.b %00000011
          dc.b %00000000
          dc.b %11000001
          dc.b %01100001
          dc.b %00110001
          dc.b %00011001
          dc.b %00001001
          dc.b %00001101
          dc.b %00000101
          dc.b %00000101
          dc.b %00000101
          dc.b %00000101
          dc.b %00000101
          dc.b %00000101
          dc.b %00000101
          dc.b %00000000
ground_sprite3_grp0:
          dc.b %00001100
          dc.b %00000000
          dc.b %00000000
          dc.b %11000001
          dc.b %01100001
          dc.b %00110001
          dc.b %00011001
          dc.b %00001001
          dc.b %00001101
          dc.b %00000101
          dc.b %00000101
          dc.b %00000101
          dc.b %00000101
          dc.b %00000101
          dc.b %00000101
          dc.b %00000101
ground_sprite1_grp1:
          dc.b %10000000
          dc.b %00000110
          dc.b %00000000
          dc.b %10000011
          dc.b %10000110
          dc.b %10001100
          dc.b %10011000
          dc.b %10010000
          dc.b %10110000
          dc.b %10100000
          dc.b %10100000
          dc.b %10100000
          dc.b %10100000
          dc.b %10100000
          dc.b %10100000
          dc.b %10100000
ground_sprite2_grp1:
          dc.b %00001100
          dc.b %00000000
          dc.b %10000011
          dc.b %10000110
          dc.b %10001100
          dc.b %10011000
          dc.b %10010000
          dc.b %10110000
          dc.b %10100000
          dc.b %10100000
          dc.b %10100000
          dc.b %10100000
          dc.b %10100000
          dc.b %10100000
          dc.b %10100000
          dc.b %00000000
ground_sprite3_grp1:
          dc.b %00110000
          dc.b %00000000
          dc.b %00000000
          dc.b %10000011
          dc.b %10000110
          dc.b %10001100
          dc.b %10011000
          dc.b %10010000
          dc.b %10110000
          dc.b %10100000
          dc.b %10100000
          dc.b %10100000
          dc.b %10100000
          dc.b %10100000
          dc.b %10100000
          dc.b %10100000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Explosion

explo1_sprt:
          dc.b $00, $00, $00, $00, $00, $18, $18, $00
          dc.b $00, $00, $00, $00
explo1_colr
          dc.b $00, $00, $00, $00, $00, $0e, $0e, $00
          dc.b $00, $00, $00, $00
explo2_sprt:
          dc.b $00, $00, $00, $00, $18, $3c, $3c, $18
          dc.b $00, $00, $00, $00
explo2_colr
          dc.b $00, $00, $00, $00, $2e, $2e, $2e, $2e
          dc.b $00, $00, $00, $00
explo3_sprt:
          dc.b $00, $00, $00, $3c, $7e, $7e, $7e, $7e
          dc.b $3c, $00, $00, $00
explo3_colr
          dc.b $00, $00, $00, $4e, $4e, $4e, $4e, $4e
          dc.b $4e, $00, $00, $00
explo4_sprt:
          dc.b $00, $00, $3c, $66, $c3, $c1, $c1, $e3
          dc.b $7e, $3c, $00, $00
explo4_colr
          dc.b $00, $00, $6e, $6e, $6e, $6e, $6e, $6e
          dc.b $6e, $6e, $00, $00
explo5_sprt:
          dc.b $00, $00, $78, $c0, $80, $81, $81, $c1
          dc.b $e3, $7e, $00, $00
explo5_colr
          dc.b $00, $00, $68, $68, $68, $68, $68, $68
          dc.b $68, $68, $00, $00
explo6_sprt:
          dc.b $00, $00, $00, $00, $00, $00, $80, $80
          dc.b $c1, $7e, $00, $00
explo6_colr
          dc.b $00, $00, $00, $00, $00, $00, $64, $64
          dc.b $64, $64, $00, $00


;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Right sprite data

yars_sprt:
          dc.b $00, $00, $02, $0e, $99, $67, $67, $99
          dc.b $0e, $02, $00, $00
yars_colr:
          dc.b $00, $00, $24, $26, $28, $2a, $2c, $2c
          dc.b $2c, $2c, $00, $00

missile_sprt:
          dc.b $00, $00, $00, $02, $06, $7f, $ff, $7f
          dc.b $06, $02, $00, $00
missile_colr:
          dc.b $00, $00, $00, $ba, $ba, $be, $be, $be
          dc.b $ba, $ba, $00, $00

apple_sprt:
          dc.b $3c, $7e, $ff, $fc, $fc, $fc, $ff, $66
          dc.b $10, $18, $08, $00
apple_colr:
          dc.b $96, $a6, $88, $64, $48, $2e, $3a, $54
          dc.b $54, $54, $54, $00

commodore_sprt:
          dc.b $00, $00, $38, $78, $e7, $c6, $c0, $c6
          dc.b $e7, $78, $38, $00
commodore_colr:
          dc.b $00, $00, $b8, $b8, $b8, $b8, $b8, $b8
          dc.b $b8, $b8, $b8, $00

nvdr1_sprt:
          dc.b $00, $00, $81, $5a, $24, $ff, $db, $7e
          dc.b $3c, $18, $00, $00
nvdr1b_sprt:
          dc.b $00, $00, $42, $81, $5a, $ff, $db, $7e
          dc.b $3c, $18, $00, $00
nvdr1_colr:
          dc.b $00, $00, $34, $36, $38, $3a, $3c, $3c
          dc.b $3c, $3c, $00, $00

nvdr2_sprt:
          dc.b $00, $00, $81, $42, $3c, $ff, $db, $7e
          dc.b $24, $24, $00, $00
nvdr2b_sprt:
          dc.b $00, $00, $24, $42, $7e, $ff, $db, $7e
          dc.b $24, $42, $00, $00
nvdr2_colr:
          dc.b $00, $00, $58, $5a, $5c, $5e, $5e, $5e
          dc.b $5e, $5e, $00, $00

nvdr3_sprt:
          dc.b $00, $00, $81, $5a, $24, $ff, $99, $ff
          dc.b $7e, $3c, $00, $00
nvdr3b_sprt:
          dc.b $00, $00, $42, $99, $66, $e7, $ff, $99
          dc.b $7e, $3c, $00, $00
nvdr3_colr:
          dc.b $00, $00, $c6, $c8, $ca, $cc, $ce, $5ce
          dc.b $ce, $ce, $00, $00

nvdr4_sprt:
    dc.b $00, $00, $81, $e7, $3c, $ff, $5a, $7e
    dc.b $3c, $24, $00, $00
nvdr4_colr:
    dc.b $00, $00, $46, $26, $28, $2A, $2A, $2A
    dc.b $2A, $46, $00, $00
nvdr4b_sprt:
    dc.b $00, $00, $66, $42, $42, $7e, $ff, $5a
    dc.b $7e, $3c, $42, $00
nvdr4b_colr:
    dc.b $00, $00, $46, $46, $26, $28, $2A, $2A
    dc.b $2A, $2A, $46, $00

nvdr5_sprt:
    dc.b $00, $00, $81, $5a, $24, $7e, $5a, $ff
    dc.b $7e, $e7, $00, $00
nvdr5_colr:
    dc.b $00, $00, $88, $6C, $28, $2A, $2C, $2C
    dc.b $2C, $2C, $00, $00
nvdr5b_sprt:
    dc.b $00, $00, $24, $42, $7e, $42, $7e, $db
    dc.b $7e, $7e, $e7, $00
nvdr5b_colr:
    dc.b $00, $00, $88, $88, $6C, $2A, $2C, $2C
    dc.b $2C, $2C, $2C, $00

nvdr6_sprt:
    dc.b $00, $24, $42, $66, $3c, $ff, $db, $ff
    dc.b $3c, $42, $42, $00
nvdr6_colr:
    dc.b $00, $68, $68, $6A, $6C, $6C, $6C, $6C
    dc.b $6C, $66, $64, $00
nvdr6b_sprt:
    dc.b $00, $66, $c3, $7e, $ff, $db, $ff, $3c
    dc.b $42, $81, $00, $00
nvdr6b_colr:
    dc.b $00, $68, $6A, $6C, $6C, $6C, $6C, $6C
    dc.b $66, $64, $00, $00

;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Mountain

mountain:
          dc.b $00, $01, $01
          dc.b $01, $03, $17
          dc.b $03, $07, $3f
          dc.b $07, $1F, $7f
          dc.b $0f, $bf, $ff
          dc.b $df, $ff, $ff

patrol_offset_low:
          dc.b 77, 55, 39, 94

