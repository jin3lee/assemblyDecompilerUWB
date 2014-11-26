*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
FAILEDADD   EQU     $A0000          *FAILED ADDRESS WHEN SEARCH COULDN'T FIND CMPADD
STARTADD    EQU     $A000           *STARTING ADDRESS TO SEARCH THROUGH MEMORY
ENDADD      EQU     $B000           *ENDING ADDRESS TO END SEARCH THROUGH MEMORY
CMPADD      EQU     $7A50           *MEMORY PATTERN WE ARE SEARCHING FOR
ADDR1       DS.L    1               *SAVES ADDRESS LENGTH OF LONG WORD AT END OF PROGRAM
ADDSUM      DS.W    1
CARRYBIT    DS.B    1
COUNTER     DS.W    1

START       ORG     $400            *Your program should start at the memory location $400
            
            LEA     STARTADD,A0     *PUT [STARTADD = A0]
            LEA     ENDADD, A4      *PUT [ENDADD = A4]
            LEA     CMPADD, A2      *PUT [CMPADD = A2]
            
            MOVE.L  #$12345678,$7A50    *PLACED DATA INTO 7A50
            
            MOVE.W  (A2),D0         *PUT [CMPADD = D0]
            MOVE.W  #ENDADD,D1      *PUT [ENDADD = D1]
            MOVE.W  (A0),D2         *PUT [STARTADD = D2]
            MOVE.W  #0,ADDSUM  *clear out addsum
            MOVE.W  #1,D7      *CLEAR COUNTER AND INITIALIZE TO 0

            
            
*here compare address of STARDADD to ENDADD. If equal, we haven't found it
LOOP        
           *DETERMINES WHETHER ADDRESS HIT THE ENDADD*
            CMP.W   A0,D1    *Compare STARTADD's address to ENDADD address in D1
            BEQ     ENDLOOP  *If equal we haven't found it, branch out and set Addr1 = $A0000
            
           *COMPARES DATA WITH COMPADD*
            MOVE.W  (A0),D2

            CMP.B   D2,D0               *(COMPARES) DATA
           
            BEQ     BRANCHEQU               *BRANCHES IF BYTES IN ADDRESSES ARE EQUAL
            
            MOVE.W  (A0)+,D2 *increment A0 and place it into D2
            
            BRA     LOOP                    *LOOPS
            
*BRANCHING IF FOUND CMPADD
BRANCHEQU  
            MOVE.W  A0,ADDR1         *PREDECREMENTS AND PLACES DATA INTO ADDR1
           
*BRANCH IF LOOP DIDN'T FIND CMPADD
ENDLOOP
        MOVE.L  #$A0000,ADDR1           *Set address of ADDR1 to A0000
        LEA ADDR1,A3    *LOAD ADDR1 into A3 so we can increment A3
        
LOOP2
        *Now add series of bytes stored in 512 consecutive mem locations from ADDR1
        ADD.B   (A3)+,D5      *add contents of A3 into D5, then increment A3 after
        BCS     STEP4
        ADD.W   #1,D7         *counter increment by 1
        CMP.W   #512,D7
        BEQ     STEP4
        BRA     LOOP2
        

ENDOFLOOP2

*In this step, we generate carry bit, sum, and addr1 and print them
STEP4
        
        MOVE.B   #9,D0
        TRAP    #15

        MOVE.W  D5,ADDSUM        

CR          EQU     $0D
LF          EQU     $0A
MESSAGE1    DC.B    'INCREMENTING',CR, LF, 0
MESSAGE2    DC.B    'COMPARING',CR, LF, 0
            END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
