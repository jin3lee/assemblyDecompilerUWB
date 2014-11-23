*-----------------------------------------------------------
* Title      :  Hello World
* Written by :  Joseph Lee
* Date       :  11/23/2014
* Description:  Prints Hello World
*-----------------------------------------------------------
START   ORG     $1000

*------------CODE FOR OUTPUT---------------
        LEA     MESSAGE, A1             *LOADS EFFECTIVE ADDRESS "MESSAGE" INTO ADDRESS REGISTER A1
        MOVE.B  #14,D0                  *MOVES 14 INTO DATA REGISTER D0
        TRAP    #15                     *ACTIVATES TRAP OF UP TO 15 TRAP CODE

        MOVE.B  #9, D0
        TRAP    #15                     *HALT SIMULATOR
        
CR      EQU     $0D
LF      EQU     $0A
MESSAGE DC.B    'HELLO WORLD',CR,LF                *PLACES ASCII STRING IN MEMORY AT MESSAGE
        DC.B    'ALL YOUR BASE ARE BELONG TO US',0
        END     START
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
