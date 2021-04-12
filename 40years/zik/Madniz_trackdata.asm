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
Madniz_tt_TrackDataStart:

; =====================================================================
; Melodic instrument definitions (up to 7). tt_envelope_index_c0/1 hold
; the index values into these tables for the current instruments played
; in channel 0 and 1.
; 
; Each instrument is defined by:
; - Madniz_tt_InsCtrlTable: the AUDC value
; - Madniz_tt_InsADIndexes: the index of the start of the ADSR envelope as
;       defined in Madniz_tt_InsFreqVolTable
; - Madniz_tt_InsSustainIndexes: the index of the start of the Sustain phase
;       of the envelope
; - Madniz_tt_InsReleaseIndexes: the index of the start of the Release phase
; - Madniz_tt_InsFreqVolTable: The AUDF frequency and AUDV volume values of
;       the envelope
; =====================================================================

; Instrument master CTRL values
Madniz_tt_InsCtrlTable:
        dc.b $06, $04, $0c


; Instrument Attack/Decay start indexes into ADSR tables.
Madniz_tt_InsADIndexes:
        dc.b $00, $05, $05


; Instrument Sustain start indexes into ADSR tables
Madniz_tt_InsSustainIndexes:
        dc.b $01, $05, $05


; Instrument Release start indexes into ADSR tables
; Caution: Values are stored with an implicit -1 modifier! To get the
; real index, add 1.
Madniz_tt_InsReleaseIndexes:
        dc.b $02, $06, $06


; AUDVx and AUDFx ADSR envelope values.
; Each byte encodes the frequency and volume:
; - Bits 7..4: Freqency modifier for the current note ([-8..7]),
;       8 means no change. Bit 7 is the sign bit.
; - Bits 3..0: Volume
; Between sustain and release is one byte that is not used and
; can be any value.
; The end of the release phase is encoded by a 0.
Madniz_tt_InsFreqVolTable:
; 0: bassline
        dc.b $8d, $8c, $00, $8b, $00
; 1+2: Sine
        dc.b $88, $00, $88, $00



; =====================================================================
; Percussion instrument definitions (up to 15)
;
; Each percussion instrument is defined by:
; - Madniz_tt_PercIndexes: The index of the first percussion frame as defined
;       in Madniz_tt_PercFreqTable and Madniz_tt_PercCtrlVolTable
; - Madniz_tt_PercFreqTable: The AUDF frequency value
; - Madniz_tt_PercCtrlVolTable: The AUDV volume and AUDC values
; =====================================================================

; Indexes into percussion definitions signifying the first frame for
; each percussion in Madniz_tt_PercFreqTable.
; Caution: Values are stored with an implicit +1 modifier! To get the
; real index, subtract 1.
Madniz_tt_PercIndexes:
        dc.b $01, $05


; The AUDF frequency values for the percussion instruments.
; If the second to last value is negative (>=128), it means it's an
; "overlay" percussion, i.e. the player fetches the next instrument note
; immediately and starts it in the sustain phase next frame. (Needs
; TT_USE_OVERLAY)
Madniz_tt_PercFreqTable:
; 0: Hit
        dc.b $00, $02, $01, $00
; 1: Snare
        dc.b $05, $1b, $08, $05, $05, $05, $00


; The AUDCx and AUDVx volume values for the percussion instruments.
; - Bits 7..4: AUDC value
; - Bits 3..0: AUDV value
; 0 means end of percussion data.
Madniz_tt_PercCtrlVolTable:
; 0: Hit
        dc.b $83, $82, $81, $00
; 1: Snare
        dc.b $8f, $cf, $6f, $89, $86, $83, $00


        
; =====================================================================
; Track definition
; The track is defined by:
; - tt_PatternX (X=0, 1, ...): Pattern definitions
; - Madniz_tt_PatternPtrLo/Hi: Pointers to the tt_PatternX tables, serving
;       as index values
; - Madniz_tt_SequenceTable: The order in which the patterns should be played,
;       i.e. indexes into Madniz_tt_PatternPtrLo/Hi. Contains the sequences
;       for all channels and sub-tracks. The variables
;       tt_cur_pat_index_c0/1 hold an index into Madniz_tt_SequenceTable for
;       each channel.
;
; So Madniz_tt_SequenceTable holds indexes into Madniz_tt_PatternPtrLo/Hi, which
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

; blank
Madniz_tt_pattern0:
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $00

; mel0a
Madniz_tt_pattern1:
        dc.b $21, $08, $23, $08, $25, $08, $21, $08
        dc.b $29, $08, $21, $08, $26, $08, $23, $08
        dc.b $00

; mel1a
Madniz_tt_pattern2:
        dc.b $21, $6e, $23, $08, $25, $6b, $21, $08
        dc.b $29, $71, $21, $08, $26, $6f, $23, $08
        dc.b $00

; mel1b
Madniz_tt_pattern3:
        dc.b $21, $55, $23, $08, $25, $51, $21, $08
        dc.b $29, $4e, $21, $08, $26, $51, $23, $08
        dc.b $00

; mel1c
Madniz_tt_pattern4:
        dc.b $21, $51, $23, $08, $25, $53, $21, $08
        dc.b $29, $55, $21, $08, $26, $53, $23, $08
        dc.b $00

; mel1d
Madniz_tt_pattern5:
        dc.b $21, $55, $23, $55, $25, $57, $21, $55
        dc.b $29, $51, $21, $5d, $26, $5a, $23, $08
        dc.b $00

; mel2a
Madniz_tt_pattern6:
        dc.b $08, $6e, $10, $08, $08, $6b, $21, $10
        dc.b $08, $71, $10, $08, $08, $6f, $23, $10
        dc.b $00

; mel2b
Madniz_tt_pattern7:
        dc.b $08, $55, $10, $08, $08, $51, $21, $10
        dc.b $08, $4e, $10, $08, $08, $51, $23, $10
        dc.b $00

; d0a
Madniz_tt_pattern8:
        dc.b $11, $08, $11, $08, $12, $08, $11, $08
        dc.b $08, $08, $11, $08, $12, $08, $12, $08
        dc.b $00

; d0b
Madniz_tt_pattern9:
        dc.b $11, $08, $11, $08, $12, $08, $11, $08
        dc.b $08, $08, $12, $08, $12, $08, $12, $08
        dc.b $00

; b+d0a
Madniz_tt_pattern10:
        dc.b $2b, $08, $11, $08, $12, $2b, $11, $08
        dc.b $2d, $08, $11, $08, $12, $2d, $12, $08
        dc.b $00

; b+d0b
Madniz_tt_pattern11:
        dc.b $2b, $08, $11, $08, $12, $2b, $11, $08
        dc.b $29, $08, $11, $08, $12, $29, $12, $08
        dc.b $00

; b+d0c
Madniz_tt_pattern12:
        dc.b $28, $08, $11, $08, $12, $28, $11, $08
        dc.b $29, $08, $11, $08, $12, $29, $12, $08
        dc.b $00




; Individual pattern speeds (needs TT_GLOBAL_SPEED = 0).
; Each byte encodes the speed of one pattern in the order
; of the tt_PatternPtr tables below.
; If TT_USE_FUNKTEMPO is 1, then the low nibble encodes
; the even speed and the high nibble the odd speed.
    IF TT_GLOBAL_SPEED = 0
Madniz_tt_PatternSpeeds:
%%PATTERNSPEEDS%%
    ENDIF


; ---------------------------------------------------------------------
; Pattern pointers look-up table.
; ---------------------------------------------------------------------
Madniz_tt_PatternPtrLo:
        dc.b <Madniz_tt_pattern0, <Madniz_tt_pattern1, <Madniz_tt_pattern2, <Madniz_tt_pattern3
        dc.b <Madniz_tt_pattern4, <Madniz_tt_pattern5, <Madniz_tt_pattern6, <Madniz_tt_pattern7
        dc.b <Madniz_tt_pattern8, <Madniz_tt_pattern9, <Madniz_tt_pattern10, <Madniz_tt_pattern11
        dc.b <Madniz_tt_pattern12
Madniz_tt_PatternPtrHi:
        dc.b >Madniz_tt_pattern0, >Madniz_tt_pattern1, >Madniz_tt_pattern2, >Madniz_tt_pattern3
        dc.b >Madniz_tt_pattern4, >Madniz_tt_pattern5, >Madniz_tt_pattern6, >Madniz_tt_pattern7
        dc.b >Madniz_tt_pattern8, >Madniz_tt_pattern9, >Madniz_tt_pattern10, >Madniz_tt_pattern11
        dc.b >Madniz_tt_pattern12        


; ---------------------------------------------------------------------
; Pattern sequence table. Each byte is an index into the
; Madniz_tt_PatternPtrLo/Hi tables where the pointers to the pattern
; definitions can be found. When a pattern has been played completely,
; the next byte from this table is used to get the address of the next
; pattern to play. tt_cur_pat_index_c0/1 hold the current index values
; into this table for channels 0 and 1.
; If TT_USE_GOTO is used, a value >=128 denotes a goto to the pattern
; number encoded in bits 6..0 (i.e. value AND %01111111).
; ---------------------------------------------------------------------
Madniz_tt_SequenceTable:
        ; ---------- Channel 0 ----------
        dc.b $00, $00, $00, $00, $00, $00, $00, $00
        dc.b $01, $01, $01, $01, $01, $01, $01, $01
        dc.b $01, $01, $01, $01, $01, $01, $01, $01
        dc.b $01, $01, $01, $01, $02, $03, $02, $04
        dc.b $02, $03, $02, $05, $02, $03, $02, $04
        dc.b $02, $03, $02, $05, $06, $06, $06, $07
        dc.b $06, $06, $06, $07, $06, $06, $06, $06
        dc.b $07, $07, $07, $07, $80

        
        ; ---------- Channel 1 ----------
        dc.b $08, $08, $08, $09, $08, $08, $08, $08
        dc.b $0a, $0b, $0a, $0b, $0c, $0b, $0c, $0b
        dc.b $0a, $0b, $0a, $0b, $0c, $0b, $0c, $0b
        dc.b $0a, $0b, $0a, $0b, $0c, $0b, $0c, $0b
        dc.b $0a, $0b, $0a, $0b, $0c, $0b, $0c, $0b
        dc.b $0a, $0b, $0a, $0b, $0c, $0b, $0c, $0b
        dc.b $08, $08, $08, $09, $08, $08, $08, $09
        dc.b $bd


        echo "Track size: ", *-Madniz_tt_TrackDataStart
