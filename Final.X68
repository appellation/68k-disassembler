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


********************************************
*             SIZE PARSERS                 *
********************************************
light_purple_size:
    MOVE.B  #'.', A2
    CMPI.B  #0, D3
    BEQ     size_b
    CMPI.B  #1, D3
    BEQ     size_w
    CMPI.B  #2, D3
    BEQ     size_l

size_b:
    MOVE.B  #'B', A2
    RTS
size_w:
    MOVE.B  #'W', A2
    RTS
size_l:
    MOVE.B  #'L', A2
    RTS

********************************************
*                                          *
*             OP CODE PARSER               *
*                                          *
********************************************

code0000:
    MOVE.W  A0, D5          ; Move current instruction into D5
    MOVE.B  D5, D1          ; Move last 8 bits into effective addressing register
    LSR     #8, D5          ; Put specific op into LSBs
    CMPI    #0, D5          ; ORI
    BEQ     op_ori
    CMPI    #1, D5          ; ANDI
    BEQ     op_andi
    CMPI    #2, D5          ; SUBI
    BEQ     op_subi
    CMPI    #3, D5          ; ADDI
    BEQ     op_addi
    CMPI    #5, D5          ; EORI
    BEQ     op_eori
    CMPI    #6, D5          ; CMPI
    BEQ     op_cmpi
    BRA     op_unsupported

code0001:                   ; MOVE(A).B
    BRA     op_move
code0010:                   ; MOVA(A).L
    BRA     op_move
code0011:                   ; MOVE(A).W
    BRA     op_move

code0100:
    MOVE.W  A0, D5
    MOVE.B  D5, D1
    LSR     #8, D5
    CMPI.B  #$42, D5        ; 0100 0010
    BEQ     op_clr
    CMPI.B  #$46, D5        ; 0100 0110
    BEQ     op_not
    CMPI.B  #$48, D5        ; 0100 1000
    BEQ     op_ext
    CMPI.B  #$4E, D5        ; 0100 1110
    BEQ     op_trap
* Constant OP codes (NOP, STOP, RTE, RTS)
    CMPI.W  #$4E71, (A0)
    BEQ     op_nop
    CMPI.W  #$4E72, (A0)
    BEQ     op_stop
    CMPI.W  #$4E73, (A0)
    BEQ     op_rte
    CMPI.W  #$4E75, (A0)
    BEQ     op_rts

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

    ANDI.B  #$C0, D6            ; Zero out last 6 bits, preserving first 2 (size) - xx000000
    OR.B    D6, D1              ; Move size into EA register with address - xx yyyyyy

op_movea:
    MOVE.B  #'A', (A2)+
    RTS

********************************************
*                 OP 0100                  *
********************************************

op_clr:
    MOVE.B  #'C', (A2)+
    MOVE.B  #'L', (A2)+
    MOVE.B  #'R', (A2)+
    BRA     op_not_clr_continue
op_not:
    MOVE.B  #'N', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'T', (A2)+
op_not_clr_continue:
    MOVE.B  (A1), D3
    LSR     #6, D3
    JSR     light_purple_size
    
    MOVE.B  (A1), D1            ; Move EA of instruction into EA register
    JSR     ea_start
    JMP     op_finish
op_ext:
op_trap:
op_nop:
op_stop:
op_rte:
op_rts:
op_jsr:
op_jmp:
op_movem:
op_lea:

* CONSTANTS

* Put variables and constants here

    SIMHALT             ; halt simulator
    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
