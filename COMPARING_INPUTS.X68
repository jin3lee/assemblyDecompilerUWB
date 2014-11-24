*-----------------------------------------------------------
* Title      :  Hello World
* Written by :  Joseph Lee
* Date       :  11/23/2014
* Description:  Prints Hello World
*-----------------------------------------------------------
START   ORG     $1000
CR      EQU     $0D
LF      EQU     $0A

*------------CODE FOR OUTPUT---------------
LOOP    LEA     MESSAGE, A1             *LOADS EFFECTIVE ADDRESS "MESSAGE" INTO ADDRESS REGISTER A1
        MOVE.B  #14,D0                  *MOVES 14 INTO DATA REGISTER D0
        TRAP    #15                     *ACTIVATES TRAP OF UP TO 15 TRAP CODE

*------------CODE FOR INPUT---------------
        MOVE.B  #4,D0                   *TRAP TASK 4 
        TRAP    #15
        
*------------COMPARING INPUT---------------
        CMP.L   #0,D1
        BEQ     DONE
        
        BRA     LOOP
*------------CODE ENDING SIMULATOR---------
DONE    MOVE.B  #9, D0
        TRAP    #15                     *HALT SIMULATOR
        

MESSAGE DC.B    'ENTER A NUMBER: ',0               *PLACES ASCII STRING IN MEMORY AT MESSAGE
        
        END     START
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
