*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
  ORG    $6000
START   

            MOVE.B  D1,D1
            MOVE.B  D2,(A2)
            MOVE.B  D3,(A3)+
            MOVE.B  D4,-(A4)
            MOVE.B  D5,$3333
            MOVE.B  D6,$44444444
            
            *MOVE.B  A1,D1           *NOT ALLOWED FOR BYTE SIZE OPERATION (CAN'T RUN THIS)
            *MOVE.B  A2,(A2)
            *MOVE.B  A3,(A3)+
            *MOVE.B  A4,-(A4)
            *MOVE.B  A5,$3333
            *MOVE.B  A6,$44444444
            
            MOVE.B  (A1),D1
            MOVE.B  (A2),(A2)
            MOVE.B  (A3),(A3)+
            MOVE.B  (A4),-(A4)
            MOVE.B  (A5),$3333
            MOVE.B  (A6),$44444444
             
            MOVE.B  (A1)+,D1
            MOVE.B  (A2)+,(A2)
            MOVE.B  (A3)+,(A3)+
            MOVE.B  (A4)+,-(A4)
            MOVE.B  (A5)+,$3333
            MOVE.B  (A6)+,$44444444

            MOVE.B  -(A1),D1
            MOVE.B  -(A2),(A2)
            MOVE.B  -(A3),(A3)+
            MOVE.B  -(A4),-(A4)
            MOVE.B  -(A5),$3333
            MOVE.B  -(A6),$44444444
            
            MOVE.B  $3331,D1
            MOVE.B  $3332,(A2)
            MOVE.B  $3333,(A3)+
            MOVE.B  $3334,-(A4)
            MOVE.B  $3335,$3333
            MOVE.B  $3336,$44444444
            
            MOVE.B  $44444441 ,D1
            MOVE.B  $44444442 ,(A2)
            MOVE.B  $44444443 ,(A3)+
            MOVE.B  $44444444 ,-(A4)
            MOVE.B  $44444445 ,$3333
            MOVE.B  $44444446 ,$44444444 


    MOVE.B  #9,D0
    TRAP    #15
    END    START        




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
