*-----------------------------------------------------------
* Title      :  Homework 5
* Written by :  Joseph Lee
* Date       :  11/23/2014
* Description:  Compares data pattern in an address range
*-----------------------------------------------------------
START       ORG     $1000               *STARTING LOCATION
CR          EQU     $0D                 *ASCII FOR CARRIAGE RETURN
LF          EQU     $0A                 *ASCII FOR LINE FEED
HSTART      EQU     $A000               *LOCATION TO START SEARCHING FOR PATTERN
HEND        EQU     $B000               *LOCATION TO END SEARCH FOR PATTERN
HPATTERN    EQU     $7A50               *PATTERN TO SEARCH FOR

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
        

MESSAGE DC.B    'Do you want me to start searching location $7A50?',LF,CR               *PLACES ASCII STRING IN MEMORY AT MESSAGE
        DC.B    '(Type "Yes" to Start, or type "No" to quit)',CR,LF,0
ADDR1   DS.L    1   

    END    START                        *LAST LINE OF CODE

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
