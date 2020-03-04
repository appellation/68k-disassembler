*-----------------------------------------------------------
* Title      : CSS422 - Disassembler
* Written by : Derek Bui & Will Nelson
* Date       : February 26, 2020
* Description: Disassembles 68K binary code into ASM
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here
    LEA $400, A0
    MOVE.L (A0), D2
    LSR.L #8, D2
    LSR.L #8, D2
    LSR.L #8, D2
    LSR.L #4, D2
    CMPI.B #0, D2
    BEQ    code0000
    CMPI.B #1, D2
    BEQ    code0001
    CMPI.B #2, D2
    BEQ     code0010
    CMPI.B #3, D2
    BEQ     code0011
    CMPI.B #4, D2
    BEQ     code0100
    CMPI.B #5, D2
    BEQ     code0101
    CMPI.B #6, D2
    BEQ     code0110
    CMPI.B  #7, D2
    BEQ     code0111
    CMPI.B  #8, D2
    BEQ     code1000
    CMPI.B  #9, D2
    BEQ     code1001
    CMPI.B  #$B, D2
    BEQ     code1011
    CMPI.B  #$C, D2
    BEQ     code1100
    CMPI.B  #$D, D2
    BEQ     code1101
    CMPI.B  #$E, D2
    BEQ     code1110
    BRA op_unsupported

********************************************
*                 EA START                 *
********************************************

ea_start:
    * PUT EFFECTIVE ADDRESSING HERE
    RTS
ea_d0:
    MOVE.B #'D', (A2)+
    MOVE.B #'0', (A2)+
    RTS
ea_d1:
    MOVE.B #'D', (A2)+
    MOVE.B #'1', (A2)+
    RTS
ea_d2:
    MOVE.B #'D', (A2)+
    MOVE.B #'2', (A2)+
    RTS
ea_d3:
    MOVE.B #'D', (A2)+
    MOVE.B #'3', (A2)+
    RTS
ea_d4:
    MOVE.B #'D', (A2)+
    MOVE.B #'4', (A2)+
    RTS
ea_d5:
    MOVE.B #'D', (A2)+
    MOVE.B #'5', (A2)+
    RTS
ea_d6:
    MOVE.B #'D', (A2)+
    MOVE.B #'6', (A2)+
    RTS
ea_d7:
    MOVE.B #'D', (A2)+
    MOVE.B #'7', (A2)+
    RTS

********************************************
*             SIZE PARSERS                 *
********************************************
light_purple_size:
    MOVE.B  #'.', (A2)+
    LSR     #1, D3
    BCS     size_w
    LSR     #1, D3
    BCS     size_l
    BRA     size_b

size_b:
    MOVE.B  #'B', (A2)+
    RTS
size_w:
    MOVE.B  #'W', (A2)+
    RTS
size_l:
    MOVE.B  #'L', (A2)+
    RTS

********************************************
*                                          *
*             OP CODE PARSER               *
*                                          *
********************************************

code0000:
    MOVE.W  (A0), D5          ; Move current instruction into D5
    MOVE.B  D5, D1          ; Move last 8 bits into effective addressing register
    LSR     #8, D5          ; Put specific op into LSBs
    CMPI    #0, D5          ; ORI
    BEQ     op_ori
    CMPI    #2, D5          ; ANDI
    BEQ     op_andi
    CMPI    #4, D5          ; SUBI
    BEQ     op_subi
    CMPI    #6, D5          ; ADDI
    BEQ     op_addi
    CMPI    #8, D5          ; EORI
    BEQ     op_eori
    CMPI    #$C, D5          ; CMPI
    BEQ     op_cmpi
    BRA     op_unsupported

code0001:                   ; MOVE(A).B
    BRA     op_move
code0010:                   ; MOVA(A).L
    BRA     op_move
code0011:                   ; MOVE(A).W
    BRA     op_move

code0100:
    MOVE.W  (A0), D5        ;moves instruction to temp register (D5)
    MOVE.W  D5, D1          ;loads into EA register
    LSR     #8, D5          ;gets the first 8 bits
    CMPI.B  #$42, D5        ;0100 0010
    BEQ     op_clr          ;CLR
    CMPI.B  #$46, D5        ; 0100 0110
    BEQ     op_not          ;NOT
    MOVE.W  D1, D5          ;resets temp register
    LSR.W   #3, D5          ;gets first 13 bits
    ANDI.B  #$7, D5         ;clears size bit
    CMPI.W  #$900, D5       ;0100 1000
    BEQ     op_ext          ;EXT
    MOVE.W  D1, D5          ;resets d5 to full instruction
    LSR     #4, D5          ;get first 12 bits
    CMPI.B  #$E4, D5        ; 0100 1110
    BEQ     op_trap         ;TRAP
    LSR     #2, D5          ;gets the first 10 bits
    ANDI.B  #$7, D5         ;clear size bit
    CMPI.B  #$7, D5 
    BEQ     op_lea          ;LEA
* Constant OP codes (NOP, STOP, RTE, RTS)
    CMPI.W  #$4E71, (A0)
    BEQ     op_nop
    CMPI.W  #$4E72, (A0)
    BEQ     op_stop
    CMPI.W  #$4E73, (A0)
    BEQ     op_rte
    CMPI.W  #$4E75, (A0)
    BEQ     op_rts
    CMPI.B  #$7A,   D5
    BEQ     op_jsr
    CMPI.B  #$7B,   D5
    BEQ     op_jmp
    LSR     #1, D5
    ANDI.B  #1, D5
    CMPI.B  #$1, D5
    BEQ     op_movem

code0101:
    MOVE.W (A0), D5
    LSR.W   #8,  D5
    LSR.W   #1,  D5
    BCS     op_subq
    BRA     op_addq
    
code0110:
    MOVE.W  (A0), D5
    LSR.W   #8,   D5
    CMPI.B  #$60,  D5
    BEQ     op_bra
    CMPI.B  #$61,  D5
    BEQ     op_bsr
    BRA     op_bcc

code0111:
    BRA     op_moveq

code1000:
    MOVE.W (A0), D5
    LSR.W   #7,  D5
    BCC     op_or
    LSR.W   #1,  D5
    BCC     op_or
    LSR.W   #1,  D5
    BCC     op_divu
    BRA     op_divs

code1001:
    BRA     op_sub

code1011:
    MOVE.W  (A0), D5
    LSL.W   #8,   D5
    BCS     op_eor
    BRA     op_cmp

code1100:
    MOVE.W (A0), D5
    LSR.W  #7,  D5
    BCC     op_and
    LSR.W   #1, D5
    BCC     op_and
    LSR.W   #1, D5
    BCC     op_mulu
    BRA     op_muls
    
code1101:
    MOVE.W  (A0), D5
    LSR.W   #7, D5
    BCC     op_add
    LSR.W   #1, D5
    BCC     op_add
    BRA     op_adda

code1110:
    MOVE.W  (A0), D5
    LSR.W   #7, D5
    BCC     code_shift_reg
    LSR.W   #1, D5
    BCC     code_shift_reg
    BRA     code_shift_ea
    
    
code_shift_reg:
    MOVE.W  (A0), D5
    LSR.W   #4, D5
    BCC     op_asx_reg
    LSR.W   #1, D5
    BCC     op_lsx_reg
    BRA     op_rox_reg
    
code_shift_ea:
    MOVE.W  (A0), D5
    LSL.W   #6, D5
    BCS     op_rox_ea
    LSL.W   #1, D5
    BCS     op_lsx_ea
    BRA     op_asx_ea

********************************************
*                 OP 0000                  *
********************************************

op_ori:
    MOVE.B  #'O', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    JSR     ea_start
    JMP     op_finish

op_andi:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'N', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    JSR     ea_start
    JMP     op_finish
    
op_subi:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'B', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    JSR     ea_start
    JMP     op_finish
    
op_addi:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    JSR     ea_start
    JMP     op_finish

op_eori:
    MOVE.B  #'E', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    JSR     ea_start
    JMP     op_finish

op_cmpi:
    MOVE.B  #'C', (A2)+
    MOVE.B  #'M', (A2)+
    MOVE.B  #'P', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
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
    MOVE.W  (A0), D1              ; Move address into EA register
    MOVE.W  (A0), D6              ; Move address into separate register for size parsing - ??yyyyyy
    LSR     #6, D6              ; Shift size into position for movement into D1
    MOVE.B  D6, D7
    ANDI.B  #7, D7
    CMPI.B  #1, D7
    BNE     continue_move_a
    JSR     op_movea
continue_move_a:
    MOVE.B  #'.', (A2)+
    MOVE.W  (A0), D3
    LSR     #8, D3
    LSR     #4, D3
    CMPI.B  #1, D3
    BNE    dark_purple_sizing1
    JSR     size_b
dark_purple_sizing1:
    CMPI.B  #3, D3
    BNE     dark_purple_sizing2
    JSR     size_w
dark_purple_sizing2:
    CMPI.B  #2, D3
    BNE     dark_purple_sizing3
    JSR     size_l
dark_purple_sizing3:
    ; EA on SRC

                                ;MOVEA 

    ANDI.B   #$C0, D6            ; Zero out last 6 bits, preserving first 2 (size) - xx000000
    OR.B    D6, D1              ; Move size into EA register with address - xx yyyyyy
    BRA     op_finish
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
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    
    BRA     op_not_clr_continue
op_not:
    MOVE.B  #'N', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'T', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    
op_not_clr_continue:
    MOVE.B  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    
    MOVE.B  (A0), D1            ; Move EA of instruction into EA register
    JSR     ea_start
    JMP     op_finish
op_ext:
    MOVE.B  #'E', (A2)+
    MOVE.B  #'X', (A2)+
    MOVE.B  #'T', (A2)+
    MOVE.B  #'.', (A2)+
    MOVE.W  (A0), D5
    LSR.B   #6,   D5
    CMPI.B  #2,   D5
    BEQ     opext_size_word
    CMPI.B  #3,   D5
    BEQ     opext_size_long
     
opext_size_word:
    MOVE.B  #'W',   (A2)+
    BRA     opext_continue

opext_size_long:
    MOVE.B  #'L',   (A2)+
    BRA     opext_continue

opext_continue:
    MOVE.B  #'D',   (A2)+
    JMP op_finish

    
op_trap:
    MOVE.B  #'T', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #'A', (A2)+
    MOVE.B  #'P', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.B  #'#', (A2)+
    MOVE.W  (A0),   D3
    AND.L   #$0F,   D3
    JSR     int_to_ascii
    JMP     op_finish
    
op_nop:
    MOVE.B  #'N', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'P', (A2)+
    JMP     op_finish
op_stop:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'T', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'P', (A2)+
    JMP     op_finish
op_rte:
    MOVE.B  #'R', (A2)+
    MOVE.B  #'T', (A2)+
    MOVE.B  #'E', (A2)+
    JMP     op_finish
op_rts:
    MOVE.B  #'R', (A2)+
    MOVE.B  #'T', (A2)+
    MOVE.B  #'S', (A2)+
    JMP     op_finish
op_jsr:
    MOVE.B  #'J', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.W  (A0), D1
    JMP     ea_start
    JMP     op_finish
op_jmp:
    MOVE.B  #'J', (A2)+
    MOVE.B  #'M', (A2)+
    MOVE.B  #'P', (A2)+
    MOVE.W  (A0), D1
    JMP     ea_start
    JMP     op_finish
op_movem:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'E', (A2)+
    MOVE.B  #'M', (A2)+
    JMP     ea_start
    JMP     op_finish
op_lea:
    MOVE.B  #'L', (A2)+
    MOVE.B  #'E', (A2)+
    MOVE.B  #'A', (A2)+
    JMP     ea_start
    JMP     op_finish
    
********************************************
*                 OP 0101                  *
********************************************
op_addq:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'Q', (A2)+
    MOVE.W  (A0), D1
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR light_purple_size
    JSR     ea_start
    JMP     op_finish
op_subq:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'B', (A2)+
    MOVE.B  #'Q', (A2)+
    MOVE.W  (A0), D1
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR light_purple_size
    JSR     ea_start
    JMP     op_finish
    
********************************************
*                 OP 0110                  *
********************************************
op_bra:
    MOVE.B  #'B', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #'A', (A2)+
    MOVE.W  (A0), D3
    ANDI.L  #$FF, D3
    JSR     int_to_ascii
    JSR     ea_start
    JMP     op_finish

op_bsr:
    MOVE.B  #'B', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.W  (A0), D3
    ANDI.L  #$FF, D3
    JSR     int_to_ascii
    JSR     ea_start
    JMP     op_finish
op_bcc:
    MOVE.B  #'B', (A2)+
    MOVE.W  (A0), D5
    LSR     #8, D5
    CMPI.B  #$62, D5
    BEQ     op_bhi
    CMPI.B  #$63, D5
    BEQ     op_bls
    CMPI.B  #$64, D5
    BEQ     op_bcc_cc
    CMPI.B  #$65, D5
    BEQ     op_bcs
    CMPI.B  #$66, D5
    BEQ     op_bne
    CMPI.B  #$67, D5
    BEQ     op_beq
    CMPI.B  #$68, D5
    BEQ     op_bvc
    CMPI.B  #$69, D5
    BEQ     op_bvs
    CMPI.B  #$6A, D5
    BEQ     op_bpl
    CMPI.B  #$6B, D5
    BEQ     op_bmi
    CMPI.B  #$6C, D5
    BEQ     op_bge
    CMPI.B  #$6D, D5
    BEQ     op_blt
    CMPI.B  #$6E, D5
    BEQ     op_bgt
    CMPI.B  #$6F, D5
    BEQ     op_ble


op_bcc_cc:
    MOVE.B #'C', (A2)+
    MOVE.B #'C', (A2)+
    JMP     op_bcc_continue
    
op_bcs:
    MOVE.B #'C', (A2)+
    MOVE.B #'S', (A2)+
    JMP     op_bcc_continue
op_beq:
    MOVE.B #'E', (A2)+
    MOVE.B #'Q', (A2)+
    JMP     op_bcc_continue
op_bge:
    MOVE.B #'G', (A2)+
    MOVE.B #'E', (A2)+
    JMP     op_bcc_continue
op_bgt:
    MOVE.B #'G', (A2)+
    MOVE.B #'T', (A2)+
    JMP     op_bcc_continue
op_bhi:
    MOVE.B #'H', (A2)+
    MOVE.B #'I', (A2)+
    JMP     op_bcc_continue
op_ble:
    MOVE.B #'L', (A2)+
    MOVE.B #'E', (A2)+
    JMP     op_bcc_continue
op_bls:
    MOVE.B #'L', (A2)+
    MOVE.B #'S', (A2)+
    JMP     op_bcc_continue
op_blt:
    MOVE.B #'L', (A2)+
    MOVE.B #'T', (A2)+
    JMP     op_bcc_continue
op_bmi:
    MOVE.B #'M', (A2)+
    MOVE.B #'I', (A2)+
    JMP     op_bcc_continue
op_bne:
    MOVE.B #'N', (A2)+
    MOVE.B #'E', (A2)+
    JMP     op_bcc_continue
op_bpl:
    MOVE.B #'P', (A2)+
    MOVE.B #'L', (A2)+
    JMP     op_bcc_continue
op_bvc:
    MOVE.B #'V', (A2)+
    MOVE.B #'C', (A2)+
    JMP     op_bcc_continue
op_bvs:
    MOVE.B #'V', (A2)+
    MOVE.B #'S', (A2)+
    
op_bcc_continue:
    MOVE.W  (A0), D5
    ANDI.L  #$F, D5
    CMPI.L  #$0, D5
    BEQ     op_bcc_size_word
    BRA     op_bcc_size_byte
op_bcc_size_word:
    MOVE.B #'.', (A2)+
    MOVE.B #'W', (A2)+
    JMP     op_bcc_size_continue   
op_bcc_size_byte:
    MOVE.B #'.', (A2)+
    MOVE.B #'B', (A2)+
op_bcc_size_continue:

;TODO PROGRAM COUNTER
    JMP     op_finish

********************************************
*                 OP 0111                  *
********************************************
op_moveq:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'E', (A2)+
    MOVE.B  #'Q', (A2)+
    MOVE.W  (A0),  D3
    ANDI.W  #$F,   D3
    JSR     int_to_ascii
    MOVE.W  (A0),  D5
    ANDI.W  #$0F,   D5
    CMPI.B  #0,    D5
    BNE     op_moveq_not_0
    JSR     ea_d0
op_moveq_not_0:
    CMPI.B  #$0,   D5
    BNE     op_moveq_not_1
    JSR     ea_d0
op_moveq_not_1:
    CMPI.B  #$1,   D5
    BNE     op_moveq_not_2
    JSR     ea_d1
op_moveq_not_2:
    CMPI.B  #$2,   D5
    BNE     op_moveq_not_3
    JSR     ea_d2
op_moveq_not_3:
    CMPI.B  #$3,   D5
    BNE     op_moveq_not_4
    JSR     ea_d3
op_moveq_not_4:
    CMPI.B  #$4,   D5
    BNE     op_moveq_not_5
    JSR     ea_d4
op_moveq_not_5:
    CMPI.B  #$5,   D5
    BNE     op_moveq_not_6
    JSR     ea_d5
op_moveq_not_6:
    CMPI.B  #$6,   D5
    BNE     op_moveq_not_7
    JSR     ea_d6
op_moveq_not_7:
    CMPI.B  #$7,   D5
    BNE     op_moveq_continue
    JSR     ea_d7
op_moveq_continue:
    JMP     op_finish

********************************************
*                 OP 1000                  *
********************************************
op_or:
    MOVE.B #'O', (A2)+
    MOVE.B #'R', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    JSR     ea_start
    JMP     op_finish
op_divs:
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'S', (A2)+
    JMP     op_finish

op_divu:
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'U', (A2)+
    JMP     op_finish
    
********************************************
*                 OP 1001                  *
********************************************

op_sub:
    MOVE.B #'S', (A2)+
    MOVE.B #'U', (A2)+
    MOVE.B #'B', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    JSR     ea_start
    JMP     op_finish
********************************************
*                 OP 1011                  *
********************************************
op_eor:
    MOVE.B #'E', (A2)+
    MOVE.B #'O', (A2)+
    MOVE.B #'R', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    JSR     ea_start
    JMP     op_finish
op_cmp:
    MOVE.B #'C', (A2)+
    MOVE.B #'M', (A2)+
    MOVE.B #'P', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    JSR     ea_start
    JMP     op_finish
    
********************************************
*                 OP 1100                  *
********************************************
op_and:
    MOVE.B #'A', (A2)+
    MOVE.B #'N', (A2)+
    MOVE.B #'D', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    JSR     ea_start
    JMP     op_finish

op_mulu:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'L', (A2)+
    MOVE.B  #'U', (A2)+

op_muls:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'L', (A2)+
    MOVE.B  #'S', (A2)+
********************************************
*                 OP 1101                  *
********************************************
op_add:
    MOVE.B #'A', (A2)+
    MOVE.B #'D', (A2)+
    MOVE.B #'D', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    JSR     ea_start
    JMP     op_finish

op_adda:
    MOVE.B #'A', (A2)+
    MOVE.B #'D', (A2)+
    MOVE.B #'D', (A2)+
    MOVE.B #'A', (A2)+
    MOVE.B #'.', (A2)+
    MOVE.W  (A0), D5
    LSL.B   #8,   D5
    BCC     op_adda_size_word
    BRA     op_adda_size_long
op_adda_continue:
    JSR     ea_start
    JMP     op_finish
     
op_adda_size_word:
    MOVE.B  #'W',   (A2)+
    BRA     op_adda_continue

op_adda_size_long:
    MOVE.B  #'L',   (A2)+
    BRA     op_adda_continue
    
********************************************
*                 OP 1110                  *
********************************************
op_asx_ea:
    MOVE.B #'A', (A2)+
    MOVE.B #'S', (A2)+
    BRA     op_shift_ea

op_asx_reg:
    MOVE.B #'A', (A2)+
    MOVE.B #'S', (A2)+
    BRA     op_shift_reg
    
op_lsx_reg:
    MOVE.B #'L', (A2)+
    MOVE.B #'S', (A2)+
    BRA     op_shift_reg

op_lsx_ea:
    MOVE.B #'L', (A2)+
    MOVE.B #'S', (A2)+
    BRA     op_shift_ea

op_rox_reg:
    MOVE.B #'R', (A2)+
    MOVE.B #'O', (A2)+
    BRA     op_shift_reg

op_rox_ea:
    MOVE.B #'R', (A2)+
    MOVE.B #'O', (A2)+
    BRA     op_shift_ea

op_shift_ea:
    MOVE.W  (A0), D5
    LSR.W   #8, D5
    BCS     op_shift_left_ea
    MOVE.B  #'R', (A2)+
    BRA     op_shift_ea_continue
op_shift_left_ea:
    MOVE.B  #'L', (A2)+
op_shift_ea_continue:
    MOVE.B  (A0), D1
    JSR     ea_start
    JMP     op_finish

op_shift_reg:
    MOVE.W  (A0), D5
    LSR.W   #8, D5
    BCS     op_shift_reg
    MOVE.B  #'R', (A2)+
    BRA     op_shift_reg_continue
op_shift_reg:
    MOVE.B  #'L', (A2)+
op_shift_reg_continue:
    MOVE.W  (A0), D3
    LSR.W   #6, D3
    MOVE.B  #' ', (A2)+
    JSR     light_purple_sizing
    BCS     op_shift_mode_reg
    MOVE.B  '#'
    BRA     op_shift_mode_continue
op_shift_mode_reg:
    MOVE.B  #'D', (A2)+
op_shift_mode_continue:
    CLR.L   D3
    MOVE.B  (A0), D3
    JSR     int_to_ascii
    JMP     op_finish

op_finish:
    MOVE.B #0, (A2)+
    MOVEA #0, A1
    MOVE.B #14, D0
    TRAP #15
    BRA end
    
op_unsupported:

int_to_ascii:
    CLR.L   D5
    MOVE.B #'$', (A2)+
    ;ROL.L   #1, D3
   ; BCS     itoa_negative
;itoa_buffer:
   ; ROR.L   #1, D3

itoa_start:
    ROL.L #4, D3
    MOVE.B D3, D4
    ANDI.B #$0F, D4
    ADDI.B #$30, D4
    CMPI.B #$3A, D4
    BGT itoa_character
itoa_continue:
    MOVE.B D4, (A2)+
    ADDI.B #1, D5
    CMPI.B #8, D5
    BNE itoa_start
    RTS
itoa_character:
    ADDI.B #7, D4
    JMP itoa_continue
    
;itoa_negative:
    ;NOT.L    D3
   ; ADDI    #1, D3
   ; JMP itoa_buffer


end:

* CONSTANTS

* Put variables and constants here

    SIMHALT             ; halt simulator
    END    START        ; last line of source







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
