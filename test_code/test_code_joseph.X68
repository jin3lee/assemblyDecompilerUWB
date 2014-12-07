*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
  ORG    $6000
START   

    MOVE.B  #14,D1
    MOVE.B  A0,D1
    MOVE.B  (A0),D1
    MOVE.B  (A0)+,D1
    MOVE.B  -(A0),D1
    MOVE.B  $7000,D1
    MOVE.B  $00007000,D1
    

    MOVEA.L D0,A1

    ADD.L   A1,D0

    ADDA.L  D0,A1

    ADDQ.L  #6,D0

    SUB.L   A1,D0 

    SUBA.L  D0,A1

    DIVS    $1000, D2

    LEA     START, A0

    JSR     START

    RTS

    MOVEM.L $1000, D7

    MULS.W  $1000, D2

    AND     D0, D0

    ORI.B   #5, $1000

    EORI.B  #$00,D0

    CMPI.W  #14,D0

    *SUBI.L  #4,A1

    EOR     D5, $1000
    
    CMP     $1000, D5

    CMPA    A0,A1

    LSR     D5, D2

    LSL     D5, D2
    
    ASR     D5, D2

    ASL     D5, D2

    ROL     D5, D2

    ROR     D5, D2

    BTST.L  D5, D2

    BEQ     START

    BNE     START

    BLT     START

    BHI     START

    END    START        



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
