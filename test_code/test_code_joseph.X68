*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------

START     ORG    $1000

MOVE.B  A0,D1
MOVEA.L D0,A1
ADD.L   A1,D0
ADDA.L  D0,A1
ADDQ.L  #6,D0
SUB.L   A1,D0 
SUBA.L  D0,A1


END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
