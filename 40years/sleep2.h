    ;More ROM efficient version of SLEEP than Thomas Jentzsch's version that ships with macro.h
    ;May affect flags and accumulator
    ;Inspired by ATARI 2600 ADVANCED PROGRAMMING GUIDE version 1.1
    MAC SLEEP2
.C  SET {1}
    IF .C < 2
        echo "Must SLEEP2 at least two cycles"
        ERR
    ENDIF

    ;Naive approach. Makes sure .C >= 2 though.
    REPEAT .C / 14 - (.C % 14 == 1)
        jsr Delay14
.C  SET .C - 14
    REPEND

    REPEAT .C / 12 - (.C % 12 == 1)
        jsr Delay12
.C  SET .C - 12
    REPEND

    REPEAT .C / 7 - (.C % 7 == 1)
        pla
        pha
.C  SET .C - 7
    REPEND

    REPEAT .C / 6 - (.C % 6 == 1)
        lda ($80,X)
.C  SET .C - 6
    REPEND

    REPEAT .C / 5 - (.C % 5 == 1)
        dec $2D
.C  SET .C - 5
    REPEND

    IF .C & 1
        nop 0
.C  SET .C - 3
    ENDIF

    REPEAT .C / 2
        nop
    REPEND
    ENDM
