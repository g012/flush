; TIATracker music player
; Copyright 2016 Andre "Kylearan" Wichmann
; Website: https://bitbucket.org/kylearan/tiatracker
; Email: andre.wichmann@gmx.de
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;   http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

; Song author: 
; Song name: 

; =====================================================================
; TIATracker melodic and percussion instruments, patterns and sequencer
; data.
; =====================================================================
Tu_Ricanes_loop_tt_TrackDataStart:

; =====================================================================
; Melodic instrument definitions (up to 7). tt_envelope_index_c0/1 hold
; the index values into these tables for the current instruments played
; in channel 0 and 1.
; 
; Each instrument is defined by:
; - Tu_Ricanes_loop_tt_InsCtrlTable: the AUDC value
; - Tu_Ricanes_loop_tt_InsADIndexes: the index of the start of the ADSR envelope as
;       defined in Tu_Ricanes_loop_tt_InsFreqVolTable
; - Tu_Ricanes_loop_tt_InsSustainIndexes: the index of the start of the Sustain phase
;       of the envelope
; - Tu_Ricanes_loop_tt_InsReleaseIndexes: the index of the start of the Release phase
; - Tu_Ricanes_loop_tt_InsFreqVolTable: The AUDF frequency and AUDV volume values of
;       the envelope
; =====================================================================

; Instrument master CTRL values
Tu_Ricanes_loop_tt_InsCtrlTable:
        dc.b $04, $0c, $06, $04, $0c, $04, $0c


; Instrument Attack/Decay start indexes into ADSR tables.
Tu_Ricanes_loop_tt_InsADIndexes:
        dc.b $00, $00, $0b, $13, $13, $1f, $1f


; Instrument Sustain start indexes into ADSR tables
Tu_Ricanes_loop_tt_InsSustainIndexes:
        dc.b $07, $07, $0f, $19, $19, $35, $35


; Instrument Release start indexes into ADSR tables
; Caution: Values are stored with an implicit -1 modifier! To get the
; real index, add 1.
Tu_Ricanes_loop_tt_InsReleaseIndexes:
        dc.b $08, $08, $10, $1c, $1c, $36, $36


; AUDVx and AUDFx ADSR envelope values.
; Each byte encodes the frequency and volume:
; - Bits 7..4: Freqency modifier for the current note ([-8..7]),
;       8 means no change. Bit 7 is the sign bit.
; - Bits 3..0: Volume
; Between sustain and release is one byte that is not used and
; can be any value.
; The end of the release phase is encoded by a 0.
Tu_Ricanes_loop_tt_InsFreqVolTable:
; 0+1: Sine
        dc.b $88, $88, $88, $87, $86, $84, $81, $80
        dc.b $00, $80, $00
; 2: bassline
        dc.b $8f, $8f, $8f, $8f, $85, $00, $80, $00
; 3+4: IntroSynth
        dc.b $80, $71, $82, $73, $84, $75, $87, $77
        dc.b $87, $00, $77, $00
; 5+6: SineLead2
        dc.b $87, $77, $87, $77, $87, $77, $87, $77
        dc.b $87, $77, $86, $76, $85, $75, $84, $74
        dc.b $83, $73, $82, $72, $81, $71, $80, $00
        dc.b $80, $00



; =====================================================================
; Percussion instrument definitions (up to 15)
;
; Each percussion instrument is defined by:
; - Tu_Ricanes_loop_tt_PercIndexes: The index of the first percussion frame as defined
;       in Tu_Ricanes_loop_tt_PercFreqTable and Tu_Ricanes_loop_tt_PercCtrlVolTable
; - Tu_Ricanes_loop_tt_PercFreqTable: The AUDF frequency value
; - Tu_Ricanes_loop_tt_PercCtrlVolTable: The AUDV volume and AUDC values
; =====================================================================

; Indexes into percussion definitions signifying the first frame for
; each percussion in Tu_Ricanes_loop_tt_PercFreqTable.
; Caution: Values are stored with an implicit +1 modifier! To get the
; real index, subtract 1.
Tu_Ricanes_loop_tt_PercIndexes:
        dc.b $01, $0c


; The AUDF frequency values for the percussion instruments.
; If the second to last value is negative (>=128), it means it's an
; "overlay" percussion, i.e. the player fetches the next instrument note
; immediately and starts it in the sustain phase next frame. (Needs
; TT_USE_OVERLAY)
Tu_Ricanes_loop_tt_PercFreqTable:
; 0: Snarer
        dc.b $05, $1b, $08, $05, $05, $05, $05, $05
        dc.b $05, $05, $00
; 1: Kick
        dc.b $02, $05, $05, $03, $04, $05, $06, $07
        dc.b $08, $09, $0a, $0b, $0c, $0d, $00


; The AUDCx and AUDVx volume values for the percussion instruments.
; - Bits 7..4: AUDC value
; - Bits 3..0: AUDV value
; 0 means end of percussion data.
Tu_Ricanes_loop_tt_PercCtrlVolTable:
; 0: Snarer
        dc.b $8f, $cf, $6e, $8c, $8a, $88, $86, $85
        dc.b $84, $81, $00
; 1: Kick
        dc.b $ef, $ef, $ee, $eb, $e9, $e8, $e8, $e6
        dc.b $e6, $e6, $e4, $e4, $e2, $e2, $00


        
; =====================================================================
; Track definition
; The track is defined by:
; - tt_PatternX (X=0, 1, ...): Pattern definitions
; - Tu_Ricanes_loop_tt_PatternPtrLo/Hi: Pointers to the tt_PatternX tables, serving
;       as index values
; - Tu_Ricanes_loop_tt_SequenceTable: The order in which the patterns should be played,
;       i.e. indexes into Tu_Ricanes_loop_tt_PatternPtrLo/Hi. Contains the sequences
;       for all channels and sub-tracks. The variables
;       tt_cur_pat_index_c0/1 hold an index into Tu_Ricanes_loop_tt_SequenceTable for
;       each channel.
;
; So Tu_Ricanes_loop_tt_SequenceTable holds indexes into Tu_Ricanes_loop_tt_PatternPtrLo/Hi, which
; in turn point to pattern definitions (tt_PatternX) in which the notes
; to play are specified.
; =====================================================================

; ---------------------------------------------------------------------
; Pattern definitions, one table per pattern. tt_cur_note_index_c0/1
; hold the index values into these tables for the current pattern
; played in channel 0 and 1.
;
; A pattern is a sequence of notes (one byte per note) ending with a 0.
; A note can be either:
; - Pause: Put melodic instrument into release. Must only follow a
;       melodic instrument.
; - Hold: Continue to play last note (or silence). Default "empty" note.
; - Slide (needs TT_USE_SLIDE): Adjust frequency of last melodic note
;       by -7..+7 and keep playing it
; - Play new note with melodic instrument
; - Play new note with percussion instrument
; - End of pattern
;
; A note is defined by:
; - Bits 7..5: 1-7 means play melodic instrument 1-7 with a new note
;       and frequency in bits 4..0. If bits 7..5 are 0, bits 4..0 are
;       defined as:
;       - 0: End of pattern
;       - [1..15]: Slide -7..+7 (needs TT_USE_SLIDE)
;       - 8: Hold
;       - 16: Pause
;       - [17..31]: Play percussion instrument 1..15
;
; The tracker must ensure that a pause only follows a melodic
; instrument or a hold/slide.
; ---------------------------------------------------------------------
TT_FREQ_MASK    = %00011111
TT_INS_HOLD     = 8
TT_INS_PAUSE    = 16
TT_FIRST_PERC   = 17

; Intro0a
Tu_Ricanes_loop_tt_pattern0:
        dc.b $11, $08, $08, $08, $11, $08, $08, $08
        dc.b $11, $08, $08, $08, $11, $08, $08, $08
        dc.b $11, $08, $11, $08, $11, $08, $11, $08
        dc.b $11, $08, $11, $08, $11, $08, $11, $08
        dc.b $00

; intro0b
Tu_Ricanes_loop_tt_pattern1:
        dc.b $12, $08, $08, $08, $08, $08, $08, $08
        dc.b $00

; intro0b2
Tu_Ricanes_loop_tt_pattern2:
        dc.b $12, $08, $08, $08, $08, $08, $38, $08
        dc.b $12, $08, $50, $08, $50, $08, $3b, $08
        dc.b $12, $08, $50, $08, $3b, $08, $38, $08
        dc.b $00

; intro0e
Tu_Ricanes_loop_tt_pattern3:
        dc.b $12, $08, $50, $08, $50, $08, $3b, $08
        dc.b $12, $08, $50, $08, $3b, $08, $38, $08
        dc.b $12, $08, $50, $08, $50, $08, $3b, $08
        dc.b $12, $08, $50, $08, $3b, $08, $38, $08
        dc.b $00

; intro0h
Tu_Ricanes_loop_tt_pattern4:
        dc.b $12, $08, $6c, $08, $50, $08, $6c, $08
        dc.b $12, $08, $6c, $08, $3b, $08, $6c, $08
        dc.b $12, $08, $6c, $08, $50, $08, $6c, $08
        dc.b $12, $08, $6c, $08, $50, $08, $6c, $08
        dc.b $00

; mel0a
Tu_Ricanes_loop_tt_pattern5:
        dc.b $08, $08, $08, $08, $50, $08, $4a, $08
        dc.b $38, $08, $08, $08, $50, $08, $4a, $08
        dc.b $38, $08, $08, $08, $38, $08, $08, $08
        dc.b $38, $08, $3b, $08, $08, $08, $08, $08
        dc.b $00

; mel0b
Tu_Ricanes_loop_tt_pattern6:
        dc.b $3b, $08, $08, $08, $3b, $08, $3b, $08
        dc.b $08, $08, $3b, $08, $08, $08, $3b, $08
        dc.b $3d, $08, $08, $08, $3b, $08, $08, $08
        dc.b $4a, $08, $08, $08, $08, $08, $08, $08
        dc.b $00

; mel0c
Tu_Ricanes_loop_tt_pattern7:
        dc.b $34, $08, $08, $08, $34, $08, $34, $08
        dc.b $08, $08, $34, $08, $08, $08, $34, $08
        dc.b $00

; blank
Tu_Ricanes_loop_tt_pattern8:
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $00

; mel1a
Tu_Ricanes_loop_tt_pattern9:
        dc.b $aa, $08, $08, $08, $f0, $08, $08, $08
        dc.b $d8, $08, $08, $08, $f0, $08, $db, $08
        dc.b $08, $08, $f0, $08, $ea, $08, $f0, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $aa, $08, $08, $08, $f0, $08, $08, $08
        dc.b $d8, $08, $08, $08, $f0, $08, $db, $08
        dc.b $08, $08, $f0, $08, $ea, $08, $08, $08
        dc.b $f0, $08, $08, $08, $ea, $08, $08, $08
        dc.b $00

; mel1b
Tu_Ricanes_loop_tt_pattern10:
        dc.b $f2, $08, $08, $08, $08, $08, $f0, $08
        dc.b $08, $08, $08, $08, $f5, $08, $08, $08
        dc.b $08, $08, $f2, $08, $08, $08, $08, $08
        dc.b $f0, $08, $08, $08, $f5, $08, $08, $08
        dc.b $ed, $08, $08, $08, $08, $08, $ee, $08
        dc.b $08, $08, $08, $08, $f2, $08, $08, $08
        dc.b $08, $08, $f0, $08, $08, $08, $08, $08
        dc.b $f5, $08, $08, $08, $f2, $08, $08, $08
        dc.b $00

; mel01c
Tu_Ricanes_loop_tt_pattern11:
        dc.b $9b, $08, $08, $08, $08, $08, $d8, $08
        dc.b $08, $08, $08, $08, $ea, $08, $08, $08
        dc.b $08, $08, $ec, $08, $08, $08, $08, $08
        dc.b $ed, $08, $08, $08, $ec, $08, $08, $08
        dc.b $ad, $08, $08, $08, $08, $08, $ee, $08
        dc.b $08, $08, $08, $08, $f0, $08, $08, $08
        dc.b $08, $08, $ed, $08, $08, $08, $08, $08
        dc.b $ee, $08, $08, $08, $f2, $08, $08, $08
        dc.b $00

; mel01d
Tu_Ricanes_loop_tt_pattern12:
        dc.b $b0, $08, $08, $08, $08, $08, $08, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $f0, $08, $08, $08, $08, $08, $08, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $f5, $08, $08, $08, $08, $08, $f2, $08
        dc.b $08, $08, $08, $08, $ed, $08, $08, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $50, $08, $4a, $08, $38, $08, $08, $08
        dc.b $00

; intro0c
Tu_Ricanes_loop_tt_pattern13:
        dc.b $b0, $08, $08, $08, $08, $08, $08, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $aa, $08, $08, $08, $08, $08, $08, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $00

; intro0d
Tu_Ricanes_loop_tt_pattern14:
        dc.b $98, $08, $08, $08, $08, $08, $08, $08
        dc.b $00

; intro0f
Tu_Ricanes_loop_tt_pattern15:
        dc.b $9b, $08, $08, $08, $08, $08, $08, $08
        dc.b $00

; intro0g
Tu_Ricanes_loop_tt_pattern16:
        dc.b $9d, $08, $08, $08, $08, $08, $08, $08
        dc.b $00

; intro0i
Tu_Ricanes_loop_tt_pattern17:
        dc.b $08, $08, $11, $08, $11, $11, $11, $08
        dc.b $00

; b+d0a
Tu_Ricanes_loop_tt_pattern18:
        dc.b $12, $08, $6c, $08, $11, $08, $6c, $08
        dc.b $12, $08, $6c, $08, $11, $08, $6c, $08
        dc.b $12, $08, $6c, $08, $11, $08, $6c, $08
        dc.b $12, $08, $6c, $08, $11, $08, $6c, $08
        dc.b $00

; b+d0b
Tu_Ricanes_loop_tt_pattern19:
        dc.b $12, $08, $6a, $08, $11, $08, $6a, $08
        dc.b $12, $08, $6a, $08, $11, $08, $6a, $08
        dc.b $12, $08, $69, $08, $11, $08, $69, $08
        dc.b $12, $08, $6c, $08, $11, $08, $11, $08
        dc.b $00

; b+d0c
Tu_Ricanes_loop_tt_pattern20:
        dc.b $12, $08, $6a, $08, $11, $08, $6a, $08
        dc.b $12, $08, $6a, $08, $11, $08, $6a, $08
        dc.b $11, $11, $11, $08, $11, $08, $08, $08
        dc.b $11, $11, $11, $11, $11, $08, $11, $08
        dc.b $00




; Individual pattern speeds (needs TT_GLOBAL_SPEED = 0).
; Each byte encodes the speed of one pattern in the order
; of the tt_PatternPtr tables below.
; If TT_USE_FUNKTEMPO is 1, then the low nibble encodes
; the even speed and the high nibble the odd speed.
    IF TT_GLOBAL_SPEED = 0
Tu_Ricanes_loop_tt_PatternSpeeds:
%%PATTERNSPEEDS%%
    ENDIF


; ---------------------------------------------------------------------
; Pattern pointers look-up table.
; ---------------------------------------------------------------------
Tu_Ricanes_loop_tt_PatternPtrLo:
        dc.b <Tu_Ricanes_loop_tt_pattern0, <Tu_Ricanes_loop_tt_pattern1, <Tu_Ricanes_loop_tt_pattern2, <Tu_Ricanes_loop_tt_pattern3
        dc.b <Tu_Ricanes_loop_tt_pattern4, <Tu_Ricanes_loop_tt_pattern5, <Tu_Ricanes_loop_tt_pattern6, <Tu_Ricanes_loop_tt_pattern7
        dc.b <Tu_Ricanes_loop_tt_pattern8, <Tu_Ricanes_loop_tt_pattern9, <Tu_Ricanes_loop_tt_pattern10, <Tu_Ricanes_loop_tt_pattern11
        dc.b <Tu_Ricanes_loop_tt_pattern12, <Tu_Ricanes_loop_tt_pattern13, <Tu_Ricanes_loop_tt_pattern14, <Tu_Ricanes_loop_tt_pattern15
        dc.b <Tu_Ricanes_loop_tt_pattern16, <Tu_Ricanes_loop_tt_pattern17, <Tu_Ricanes_loop_tt_pattern18, <Tu_Ricanes_loop_tt_pattern19
        dc.b <Tu_Ricanes_loop_tt_pattern20
Tu_Ricanes_loop_tt_PatternPtrHi:
        dc.b >Tu_Ricanes_loop_tt_pattern0, >Tu_Ricanes_loop_tt_pattern1, >Tu_Ricanes_loop_tt_pattern2, >Tu_Ricanes_loop_tt_pattern3
        dc.b >Tu_Ricanes_loop_tt_pattern4, >Tu_Ricanes_loop_tt_pattern5, >Tu_Ricanes_loop_tt_pattern6, >Tu_Ricanes_loop_tt_pattern7
        dc.b >Tu_Ricanes_loop_tt_pattern8, >Tu_Ricanes_loop_tt_pattern9, >Tu_Ricanes_loop_tt_pattern10, >Tu_Ricanes_loop_tt_pattern11
        dc.b >Tu_Ricanes_loop_tt_pattern12, >Tu_Ricanes_loop_tt_pattern13, >Tu_Ricanes_loop_tt_pattern14, >Tu_Ricanes_loop_tt_pattern15
        dc.b >Tu_Ricanes_loop_tt_pattern16, >Tu_Ricanes_loop_tt_pattern17, >Tu_Ricanes_loop_tt_pattern18, >Tu_Ricanes_loop_tt_pattern19
        dc.b >Tu_Ricanes_loop_tt_pattern20        


; ---------------------------------------------------------------------
; Pattern sequence table. Each byte is an index into the
; Tu_Ricanes_loop_tt_PatternPtrLo/Hi tables where the pointers to the pattern
; definitions can be found. When a pattern has been played completely,
; the next byte from this table is used to get the address of the next
; pattern to play. tt_cur_pat_index_c0/1 hold the current index values
; into this table for channels 0 and 1.
; If TT_USE_GOTO is used, a value >=128 denotes a goto to the pattern
; number encoded in bits 6..0 (i.e. value AND %01111111).
; ---------------------------------------------------------------------
Tu_Ricanes_loop_tt_SequenceTable:
        ; ---------- Channel 0 ----------
        dc.b $00, $01, $01, $01, $01, $01, $02, $03
        dc.b $03, $04, $05, $06, $05, $07, $08, $08
        dc.b $09, $0a, $09, $0b, $0c, $8a

        
        ; ---------- Channel 1 ----------
        dc.b $08, $08, $08, $08, $0d, $0e, $08, $08
        dc.b $08, $0f, $08, $08, $08, $10, $08, $08
        dc.b $08, $0e, $08, $08, $11, $12, $13, $12
        dc.b $14, $12, $12, $12, $12, $12, $12, $12
        dc.b $12, $12, $14, $ab


        echo "Track size: ", *-Tu_Ricanes_loop_tt_TrackDataStart
