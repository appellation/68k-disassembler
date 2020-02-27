*-----------------------------------------------------------
* Title      : CSS422 - Disassembler
* Written by : Derek Bui & Will Nelson
* Date       : February 26, 2020
* Description: Disassembles 68K binary code into ASM
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here

ea_start:
    * PUT EFFECTIVE ADDRESSING HERE
    RTS
    
code0000:
    MOVE.W  A0, D5          ; Move current instruction into D5
    MOVE.B  D5, D1          ; Move last 8 bits into effective addressing register
    LSR     #8, D5          ; Put specific op into LSBs
    CMPI    #0, D5          ; ORI
    JEQ     op_ori
    CMPI    #1, D5          ; ANDI
    JEQ     op_andi
    CMPI    #2, D5          ; SUBI
    JEQ     op_subi
    CMPI    #3, D5          ; ADDI
    JEQ     op_addi
    CMPI    #5, D5          ; EORI
    JEQ     op_eori
    CMPI    #6, D5          ; CMPI
    JEQ     op_cmpi
    JMP     op_unsupported

code0001:                   ; MOVE(A).B
    JMP     op_move
code0010:                   ; MOVA(A).L
    JMP     op_move
code0011:                   ; MOVE(A).W
    JMP     op_move


********************************************
*                 OP 0000                  *
********************************************

op_ori:
    MOVE.B  #'O', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #'I', (A2)+
    JSR     ea_start
    JMP     op_finish

op_andi:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'N', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    JSR     ea_start
    JMP     op_finish
    
op_subi:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'B', (A2)+
    MOVE.B  #'I', (A2)+
    JSR     ea_start
    JMP     op_finish
    
op_addi:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    JSR     ea_start
    JMP     op_finish

op_eori:
    MOVE.B  #'E', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #'I', (A2)+
    JSR     ea_start
    JMP     op_finish

op_cmpi:
    MOVE.B  #'C', (A2)+
    MOVE.B  #'M', (A2)+
    MOVE.B  #'P', (A2)+
    MOVE.B  #'I', (A2)+
    JSR     ea_start
    JMP     op_finish

********************************************
*                 OP 00xx                  *
********************************************

op_move:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'E', (A2)+

    ; EA on SRC
    MOVE.W  D5, D1              ; Move address into EA register
    MOVE.W  D5, D6              ; Move address into separate register for size parsing - ??yyyyyy
    LSR     #6, D6              ; Shift size into position for movement into D1

; TODO: MOVEA   
;    MOVE.B  D6, D7
;    ANDI.B  #1, D7
;    JSR     op_movea

    ANDI.B  #$C0, D6            ; Zero out first 6 bits, preserving first 2 (size) - xx000000
    OR.B    D6, D1              ; Move size into EA register with address - xx yyyyyy

op_movea:
    MOVE.B  #'A', (A2)+
    RTS

* CONSTANTS

* Put variables and constants here

    SIMHALT             ; halt simulator
    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
