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
tt_TrackDataStart:

; =====================================================================
; Melodic instrument definitions (up to 7). tt_envelope_index_c0/1 hold
; the index values into these tables for the current instruments played
; in channel 0 and 1.
; 
; Each instrument is defined by:
; - tt_InsCtrlTable: the AUDC value
; - tt_InsADIndexes: the index of the start of the ADSR envelope as
;       defined in tt_InsFreqVolTable
; - tt_InsSustainIndexes: the index of the start of the Sustain phase
;       of the envelope
; - tt_InsReleaseIndexes: the index of the start of the Release phase
; - tt_InsFreqVolTable: The AUDF frequency and AUDV volume values of
;       the envelope
; =====================================================================

; Instrument master CTRL values
tt_InsCtrlTable:
        dc.b $0c, $06, $04, $0c, $04, $0c


; Instrument Attack/Decay start indexes into ADSR tables.
tt_InsADIndexes:
        dc.b $00, $0a, $18, $18, $2f, $2f


; Instrument Sustain start indexes into ADSR tables
tt_InsSustainIndexes:
        dc.b $06, $14, $2b, $2b, $2f, $2f


; Instrument Release start indexes into ADSR tables
; Caution: Values are stored with an implicit -1 modifier! To get the
; real index, add 1.
tt_InsReleaseIndexes:
        dc.b $07, $15, $2c, $2c, $30, $30


; AUDVx and AUDFx ADSR envelope values.
; Each byte encodes the frequency and volume:
; - Bits 7..4: Freqency modifier for the current note ([-8..7]),
;       8 means no change. Bit 7 is the sign bit.
; - Bits 3..0: Volume
; Between sustain and release is one byte that is not used and
; can be any value.
; The end of the release phase is encoded by a 0.
tt_InsFreqVolTable:
; 0: ChordsLong
        dc.b $88, $68, $78, $88, $87, $87, $86, $00
        dc.b $86, $00
; 1: bassline
        dc.b $8f, $8f, $8f, $8e, $8e, $8e, $8d, $8c
        dc.b $8b, $89, $86, $00, $80, $00
; 2+3: Chords
        dc.b $88, $68, $78, $88, $88, $88, $87, $87
        dc.b $86, $86, $85, $85, $84, $83, $83, $82
        dc.b $82, $81, $81, $80, $00, $80, $00
; 4+5: Vide
        dc.b $80, $00, $80, $00



; =====================================================================
; Percussion instrument definitions (up to 15)
;
; Each percussion instrument is defined by:
; - tt_PercIndexes: The index of the first percussion frame as defined
;       in tt_PercFreqTable and tt_PercCtrlVolTable
; - tt_PercFreqTable: The AUDF frequency value
; - tt_PercCtrlVolTable: The AUDV volume and AUDC values
; =====================================================================

; Indexes into percussion definitions signifying the first frame for
; each percussion in tt_PercFreqTable.
; Caution: Values are stored with an implicit +1 modifier! To get the
; real index, subtract 1.
tt_PercIndexes:
        dc.b $01, $05


; The AUDF frequency values for the percussion instruments.
; If the second to last value is negative (>=128), it means it's an
; "overlay" percussion, i.e. the player fetches the next instrument note
; immediately and starts it in the sustain phase next frame. (Needs
; TT_USE_OVERLAY)
tt_PercFreqTable:
; 0: HiHat
        dc.b $00, $01, $00, $00
; 1: Break SD
        dc.b $0a, $0a, $0b, $0b, $0c, $0c, $0d, $0d
        dc.b $0e, $0e, $0f, $0f, $10, $10, $11, $11
        dc.b $12, $12, $13, $13, $14, $14, $15, $15
        dc.b $16, $16, $17, $17, $18, $18, $19, $19
        dc.b $00


; The AUDCx and AUDVx volume values for the percussion instruments.
; - Bits 7..4: AUDC value
; - Bits 3..0: AUDV value
; 0 means end of percussion data.
tt_PercCtrlVolTable:
; 0: HiHat
        dc.b $83, $83, $03, $00
; 1: Break SD
        dc.b $8a, $8a, $89, $89, $88, $88, $88, $87
        dc.b $87, $87, $86, $86, $86, $85, $85, $85
        dc.b $84, $84, $84, $83, $83, $83, $82, $82
        dc.b $82, $81, $81, $81, $81, $81, $81, $80
        dc.b $00


        
; =====================================================================
; Track definition
; The track is defined by:
; - tt_PatternX (X=0, 1, ...): Pattern definitions
; - tt_PatternPtrLo/Hi: Pointers to the tt_PatternX tables, serving
;       as index values
; - tt_SequenceTable: The order in which the patterns should be played,
;       i.e. indexes into tt_PatternPtrLo/Hi. Contains the sequences
;       for all channels and sub-tracks. The variables
;       tt_cur_pat_index_c0/1 hold an index into tt_SequenceTable for
;       each channel.
;
; So tt_SequenceTable holds indexes into tt_PatternPtrLo/Hi, which
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

; mel6a
tt_pattern0:
        dc.b $29, $29, $10, $29, $11, $29, $10, $29
        dc.b $11, $28, $10, $28, $11, $08, $11, $11
        dc.b $00

; b+d0a
tt_pattern1:
        dc.b $4d, $08, $11, $11, $12, $4d, $08, $56
        dc.b $08, $11, $56, $08, $12, $08, $11, $55
        dc.b $54, $08, $11, $11, $12, $54, $08, $4f
        dc.b $08, $11, $4f, $08, $12, $12, $4e, $08
        dc.b $00

; b0a
tt_pattern2:
        dc.b $4d, $08, $11, $11, $4d, $08, $11, $56
        dc.b $08, $08, $56, $08, $08, $08, $55, $08
        dc.b $54, $08, $11, $08, $54, $08, $11, $4f
        dc.b $08, $08, $4f, $08, $11, $11, $4e, $08
        dc.b $00

; b0b
tt_pattern3:
        dc.b $4d, $08, $11, $11, $4d, $08, $11, $56
        dc.b $08, $08, $56, $08, $08, $08, $55, $08
        dc.b $54, $08, $11, $08, $54, $08, $11, $4f
        dc.b $08, $08, $4f, $08, $12, $12, $4e, $12
        dc.b $00

; mel7a1
tt_pattern4:
        dc.b $37, $08, $08, $08, $08, $08, $08, $08
        dc.b $00

; blank
tt_pattern5:
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $00

; mel7a2
tt_pattern6:
        dc.b $08, $08, $08, $08, $3a, $08, $37, $08
        dc.b $00

; mel7a3
tt_pattern7:
        dc.b $08, $08, $08, $08, $08, $08, $33, $08
        dc.b $37, $08, $08, $08, $3a, $08, $37, $08
        dc.b $00

; mel7a4
tt_pattern8:
        dc.b $08, $08, $08, $08, $08, $08, $33, $08
        dc.b $37, $08, $9a, $9d, $9f, $08, $37, $08
        dc.b $00

; mel0a
tt_pattern9:
        dc.b $93, $91, $08, $91, $08, $08, $08, $08
        dc.b $91, $93, $08, $93, $08, $08, $08, $08
        dc.b $93, $91, $08, $91, $08, $91, $08, $97
        dc.b $93, $08, $91, $08, $91, $08, $08, $08
        dc.b $00

; mel0b
tt_pattern10:
        dc.b $8f, $8e, $08, $8e, $08, $08, $08, $08
        dc.b $8e, $8f, $08, $8f, $08, $08, $08, $08
        dc.b $8f, $8e, $08, $8e, $08, $8e, $08, $91
        dc.b $8f, $08, $8e, $08, $8e, $08, $08, $08
        dc.b $00

; mel0c
tt_pattern11:
        dc.b $7d, $7a, $08, $7a, $08, $08, $08, $08
        dc.b $7a, $7d, $08, $7d, $08, $08, $08, $08
        dc.b $7d, $7a, $08, $7a, $08, $7a, $08, $8b
        dc.b $7d, $08, $7a, $08, $7a, $08, $08, $08
        dc.b $00

; mel1a
tt_pattern12:
        dc.b $df, $08, $08, $08, $7a, $8b, $08, $7d
        dc.b $08, $08, $8c, $8b, $8e, $31, $08, $08
        dc.b $08, $08, $8c, $8b, $8e, $91, $08, $8c
        dc.b $08, $2e, $08, $08, $08, $08, $08, $08
        dc.b $00

; mel1b
tt_pattern13:
        dc.b $df, $08, $8c, $8b, $8e, $31, $08, $08
        dc.b $8c, $8b, $8e, $31, $08, $08, $91, $91
        dc.b $08, $8e, $08, $8e, $08, $8c, $08, $8c
        dc.b $08, $8b, $08, $2b, $08, $7d, $08, $08
        dc.b $00

; mel2a
tt_pattern14:
        dc.b $31, $08, $08, $08, $08, $08, $08, $08
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $93, $08, $91, $08, $91, $08, $91, $08
        dc.b $2e, $08, $08, $08, $31, $08, $08, $91
        dc.b $00

; mel2b
tt_pattern15:
        dc.b $8b, $8e, $08, $8e, $8f, $08, $08, $8f
        dc.b $08, $8e, $08, $8e, $08, $08, $08, $93
        dc.b $93, $08, $93, $08, $93, $93, $08, $31
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $00

; mel2c
tt_pattern16:
        dc.b $8b, $8c, $08, $8c, $08, $8b, $08, $8b
        dc.b $08, $7d, $08, $7d, $08, $08, $93, $08
        dc.b $93, $93, $08, $93, $08, $93, $08, $31
        dc.b $08, $08, $33, $31, $2e, $33, $31, $08
        dc.b $00

; mel2d
tt_pattern17:
        dc.b $8b, $08, $8b, $08, $8b, $08, $08, $08
        dc.b $8b, $08, $8b, $08, $8b, $08, $08, $08
        dc.b $8b, $08, $8c, $08, $8e, $8c, $08, $8e
        dc.b $08, $08, $33, $08, $08, $08, $08, $08
        dc.b $00

; mel2d
tt_pattern18:
        dc.b $93, $91, $08, $91, $08, $91, $08, $91
        dc.b $08, $91, $08, $91, $08, $08, $91, $08
        dc.b $8b, $08, $8c, $8e, $08, $91, $08, $8c
        dc.b $08, $2e, $08, $08, $33, $31, $2e, $33
        dc.b $00

; mel3a
tt_pattern19:
        dc.b $28, $08, $08, $7d, $08, $8b, $7d, $08
        dc.b $08, $08, $08, $08, $8b, $08, $8c, $08
        dc.b $8b, $8c, $08, $8e, $08, $91, $08, $2e
        dc.b $08, $08, $08, $08, $93, $08, $93, $08
        dc.b $00

; mel3b
tt_pattern20:
        dc.b $93, $91, $08, $08, $08, $08, $93, $91
        dc.b $08, $08, $8e, $08, $93, $08, $08, $08
        dc.b $93, $91, $08, $08, $08, $08, $93, $91
        dc.b $08, $08, $08, $08, $8b, $7d, $08, $08
        dc.b $00

; mel5a
tt_pattern21:
        dc.b $91, $08, $08, $93, $91, $08, $08, $93
        dc.b $91, $08, $08, $93, $97, $08, $08, $9a
        dc.b $97, $08, $08, $08, $08, $08, $08, $08
        dc.b $93, $93, $08, $93, $08, $93, $08, $91
        dc.b $00

; mel5b
tt_pattern22:
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $8f, $8e, $08, $2f, $08, $08, $31, $08
        dc.b $08, $08, $08, $08, $08, $08, $9a, $97
        dc.b $93, $9a, $97, $93, $08, $93, $91, $08
        dc.b $00

; mel4a
tt_pattern23:
        dc.b $cf, $08, $08, $08, $8e, $8e, $08, $8e
        dc.b $08, $8e, $8e, $08, $8e, $08, $2e, $08
        dc.b $08, $08, $08, $08, $8e, $8e, $08, $8e
        dc.b $08, $8e, $8f, $08, $93, $08, $8f, $91
        dc.b $00




; Individual pattern speeds (needs TT_GLOBAL_SPEED = 0).
; Each byte encodes the speed of one pattern in the order
; of the tt_PatternPtr tables below.
; If TT_USE_FUNKTEMPO is 1, then the low nibble encodes
; the even speed and the high nibble the odd speed.
    IF TT_GLOBAL_SPEED = 0
tt_PatternSpeeds:
%%PATTERNSPEEDS%%
    ENDIF


; ---------------------------------------------------------------------
; Pattern pointers look-up table.
; ---------------------------------------------------------------------
tt_PatternPtrLo:
        dc.b <tt_pattern0, <tt_pattern1, <tt_pattern2, <tt_pattern3
        dc.b <tt_pattern4, <tt_pattern5, <tt_pattern6, <tt_pattern7
        dc.b <tt_pattern8, <tt_pattern9, <tt_pattern10, <tt_pattern11
        dc.b <tt_pattern12, <tt_pattern13, <tt_pattern14, <tt_pattern15
        dc.b <tt_pattern16, <tt_pattern17, <tt_pattern18, <tt_pattern19
        dc.b <tt_pattern20, <tt_pattern21, <tt_pattern22, <tt_pattern23

tt_PatternPtrHi:
        dc.b >tt_pattern0, >tt_pattern1, >tt_pattern2, >tt_pattern3
        dc.b >tt_pattern4, >tt_pattern5, >tt_pattern6, >tt_pattern7
        dc.b >tt_pattern8, >tt_pattern9, >tt_pattern10, >tt_pattern11
        dc.b >tt_pattern12, >tt_pattern13, >tt_pattern14, >tt_pattern15
        dc.b >tt_pattern16, >tt_pattern17, >tt_pattern18, >tt_pattern19
        dc.b >tt_pattern20, >tt_pattern21, >tt_pattern22, >tt_pattern23
        


; ---------------------------------------------------------------------
; Pattern sequence table. Each byte is an index into the
; tt_PatternPtrLo/Hi tables where the pointers to the pattern
; definitions can be found. When a pattern has been played completely,
; the next byte from this table is used to get the address of the next
; pattern to play. tt_cur_pat_index_c0/1 hold the current index values
; into this table for channels 0 and 1.
; If TT_USE_GOTO is used, a value >=128 denotes a goto to the pattern
; number encoded in bits 6..0 (i.e. value AND %01111111).
; ---------------------------------------------------------------------
tt_SequenceTable:
        ; ---------- Channel 0 ----------
        dc.b $00, $00, $00, $00, $00, $00, $00, $00
        dc.b $00, $00, $00, $00, $01, $01, $01, $01
        dc.b $01, $01, $01, $01, $01, $01, $01, $01
        dc.b $01, $01, $01, $01, $01, $01, $01, $01
        dc.b $01, $01, $02, $03, $01, $01, $01, $01
        dc.b $01, $01, $01, $03, $01, $01, $01, $01
        dc.b $8c

        
        ; ---------- Channel 1 ----------
        dc.b $04, $05, $05, $06, $04, $05, $07, $04
        dc.b $05, $05, $06, $04, $05, $08, $02, $03
        dc.b $09, $09, $0a, $0b, $0c, $0d, $0c, $0d
        dc.b $0e, $0f, $0e, $10, $0e, $11, $0e, $12
        dc.b $0c, $0d, $0c, $0d, $13, $14, $13, $14
        dc.b $15, $16, $15, $16, $17, $17, $17, $17
        dc.b $04, $05, $05, $06, $04, $05, $07, $04
        dc.b $05, $05, $06, $04, $05, $08, $c1


        echo "Track size: ", *-tt_TrackDataStart
