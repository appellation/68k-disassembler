
*-----------------------------------------------------------
* Title      : CSS422 - Disassembler
* Written by : Derek Bui & Will Nelson
* Date       : February 26, 2020
* Description: Disassembles 68K binary code into ASM
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

********************************************
*                UI START                  *
********************************************
* Put program code here
    MOVE.B #13, D0
    LEA    welcome_message, A1
    TRAP   #15

ui_start:
    CLR     D3                          ; clear D3, which is used for counting output lines
    MOVE.B  #14, D0                     ; prepare for TRAP #15 data output
    LEA     prompt_start_message, A1    ; load start message into A1 for output
    TRAP    #15                         ; send A1 to output
    MOVE.B  #2, D0                      ; prepare for TRAP #15 data input
    LEA     ascii_start, A1             ; set ascii_start as destination register
    TRAP    #15                         ; wait for input
    CMPI.B  #$0, (A1)                   ; check if input is 0 (no data)
    BEQ     invalid_address_start       ; handle invalid address data
    JSR     ascii_to_int                ; parse the input ASCII to integer
    MOVE    A3, D7                      ; move the parsed data into D7 for validation
    ROR.B   #1, D7                      ; check if the address is not an even number
    BCS     invalid_address_start       ; handle invalid address data
ui_start_end_prompt:
    CLR     D7                          ; reset D7
    MOVEA   A3, A0                      ; copy A3 into A0 (A0 is used for the program counter)
    MOVE.B  #14, D0                     ; prepare for TRAP #15 data output
    LEA     prompt_end_message, A1      ; load end message into A1 for output
    TRAP    #15                         ; send A1 to output
    MOVE.B  #2, D0                      ; prepare for TRAP #15 data input
    LEA     ascii_start, A1             ; set ascii_start as destination register
    TRAP    #15                         ; wait for input
    CMPI    #$0, (A1)                   ; check if input is 0 (no data)
    BEQ     invalid_address_end         ; handle invalid address data
    JSR     ascii_to_int                ; parse input ASCII to integer
    MOVE    A3, D7                      ; move the parsed data to D7 for validation
    ROR.B   #1, D7                      ; check if the address is not an even number
    BCS     invalid_address_end         ; handle invalid address data
    CLR     D7                          ; reset D7
    CMPA    A0, A3                      ; compare A0 to A3
    BLT     invalid_address_end         ; handle invalid address if A3 < A0

op_start:
    MOVEM   D0-D7, -(A7)    ; move UI data registers into memory
    MOVE.L  A0, D3          ; copy A0 to D3 for ITOA (output current program counter)
    JSR     int_to_ascii    ; send D3 to output
    MOVE.B  #' ', (A2)+     ; output a space
    MOVE.L  (A0), D2        ; move the current instruction into D2 for parsing
    LSR.L   #8, D2          ; get the most significant 4 bits
    LSR.L   #8, D2
    LSR.L   #8, D2
    LSR.L   #4, D2
    CMPI.B  #0, D2
    BEQ     code0000        ; 0000 - ORI, ANDI, SUBI, ADDI, EORI, CMPI
    CMPI.B  #1, D2
    BEQ     code0001        ; 0001 - MOVEA, MOVE
    CMPI.B  #2, D2
    BEQ     code0010        ; ???
    CMPI.B  #3, D2
    BEQ     code0011        ; 0011 - MOVEA, MOVE
    CMPI.B  #4, D2
    BEQ     code0100        ; 0010 - CLR, NOT, EXT, TRAP, NOP, STOP, RTE, RTS, JSR, JMP, MOVEM, LEA
    CMPI.B  #5, D2
    BEQ     code0101        ; 0101 - ADDQ, SUBQ
    CMPI.B  #6, D2
    BEQ     code0110        ; 0110 - BRA, BSR, Bcc
    CMPI.B  #7, D2
    BEQ     code0111        ; 0111 - MOVEQ
    CMPI.B  #8, D2
    BEQ     code1000        ; 1000 - DIVU, DIVS, OR
    CMPI.B  #9, D2
    BEQ     code1001        ; 1001 - SUB
    CMPI.B  #$B, D2
    BEQ     code1011        ; 1011 - EOR, CMP
    CMPI.B  #$C, D2
    BEQ     code1100        ; 1100 - MULU, MULS, AND
    CMPI.B  #$D, D2
    BEQ     code1101        ; 1101 - ADD, ADDA
    CMPI.B  #$E, D2
    BEQ     code1110        ; 1110 - ASL, ASR, LSL, LSR, ROL, ROR
    BRA     op_unsupported  ; handle unsupported OP code

********************************************
*                 EA START                 *
********************************************

ea_start:
    MOVE.W  D1, D4                      ; copy original EA instruction to D4
    LSR     #3, D4                      ; shift right 3 to get mode
    ANDI    #7, D4                      ; clear MSB
    CMPI.B  #0, D4
    BEQ     ea_data_register            ; 0 - EA data register
    CMPI.B  #1, D4
    BEQ     ea_address_register         ; 1 - EA address register
    CMPI.B  #2, D4
    BEQ     ea_address                  ; 2 - EA address
    CMPI.B  #3, D4
    BEQ     ea_address_post_increment   ; 3 - EA address (post increment)
    CMPI.B  #4, D4
    BEQ     ea_address_pre_decrement    ; 4 - EA address (pre decrement)
    CMPI.B  #7, D4
    BEQ     ea_mode_seven               ; 7 - EA mode 7
    BRA     ea_not_supported            ; handle invalid EA

ea_immediate_start:
    MOVE.B  #'.', (A2)+                 ; output "." separator
    MOVE.B  D1, D3                      ; copy EA instruction to D3
    LSR     #7, D3                      ; check first size bit
    BCS     ea_immediate_size_w         ; if 1, size Word
    LSR     #1, D3                      ; check second size bit
    BCS     ea_immediate_size_l         ; if 1, size Long
    BRA     ea_immediate_size_b         ; else size Byte

ea_immediate_size_b:
    MOVE.B  #'B', (A2)+         ; output B
    MOVE.B  #' ', (A2)+
    BRA     ea_byte_immediate   ; branch to Byte immediate data handler

ea_immediate_size_w:
    MOVE.B  #'W', (A2)+         ; output W
    MOVE.B  #' ', (A2)+
    BRA     ea_word_immediate   ; branch to Word immediate data handler

ea_immediate_size_l:
    MOVE.B  #'L', (A2)+         ; output L
    MOVE.B  #' ', (A2)+
    BRA     ea_long_immediate   ; branch to Long immediate data handler

ea_long_immediate:
    ADDA    #2, A0              ; increment program counter to the immediate data
    MOVE.L  (A0), D3            ; move the data to D3 for ITOA output
    MOVE.B  #'#', (A2)+         ; output immediate data prefix
    MOVE.B  #'$', (A2)+
    JSR     int_to_ascii        ; output D3 as ASCII
    MOVE.B  #',', (A2)+         ; output data separator
    MOVE.B  #' ', (A2)+
    JSR     ea_start            ; handle the rest of EA
    ADDA    #2, A0              ; increment program counter to next instruction
    RTS

ea_byte_immediate:
ea_word_immediate:
    ADDA    #2, A0              ; increment program counter to the byte/word data
    MOVE.W  (A0), D3            ; move the data to D3 for ITOA output
    MOVE.B  #'#', (A2)+         ; output immediate data prefix
    MOVE.B  #'$', (A2)+
    JSR     int_to_ascii        ; output D3 as ASCII
    MOVE.B  #',', (A2)+         ; output data separator
    MOVE.B  #' ', (A2)+
    JSR     ea_start            ; handle the rest of EA
    RTS

********************************************
*              EA POST INCR                *
********************************************
ea_address_post_increment:
    MOVE.B  #'(',   (A2)+       ; output open paren
    MOVE.B  D1,     D4          ; copy D1 to D4 for parsing
    ANDI    #$7,    D4          ; clear MSB
    CMPI.B  #0, D4
    BNE     ea_api_not_a0
    JSR     ea_a0               ; ouput "A0"
ea_api_not_a0:
    CMPI.B  #1, D4
    BNE     ea_api_not_a1
    JSR     ea_a1               ; output "A1"
    BRA     ea_api_continue
ea_api_not_a1:
    CMPI.B  #2, D4
    BNE     ea_api_not_a2
    JSR     ea_a2               ; output "A2"
    BRA     ea_api_continue
ea_api_not_a2:
    CMPI.B  #3, D4
    BNE     ea_api_not_a3
    JSR     ea_a3               ; output "A3"
    BRA     ea_api_continue
ea_api_not_a3:
    CMPI.B  #4, D4
    BNE     ea_api_not_a4
    JSR     ea_a4               ; output "A4"
    BRA     ea_api_continue
ea_api_not_a4:
    CMPI.B  #5, D4
    BNE     ea_api_not_a5
    JSR     ea_a5               ; output "A5"
    BRA     ea_api_continue
ea_api_not_a5:
    CMPI.B  #6, D4
    BNE     ea_api_not_a6
    JSR     ea_a6               ; output "A6"
    BRA     ea_api_continue
ea_api_not_a6:
    CMPI.B  #7, D4
    BNE     ea_api_continue
    JSR     ea_a7               ; output "A7"
ea_api_continue:
    MOVE.B #')',    (A2)+       ; output post increment suffix
    MOVE.B #'+',    (A2)+
    RTS


********************************************
*               EA PRE DECR                *
********************************************
ea_address_pre_decrement:
    MOVE.B  #'-',   (A2)+       ; output pre decrement prefix
    MOVE.B  #'(',   (A2)+
    MOVE.B  D1,     D4          ; copy D1 to D4 for parsing
    ANDI    #$7,    D4          ; clear MSB
    CMPI.B  #0, D4
    BNE     ea_apd_not_a0
    JSR     ea_a0               ; output "A0"
ea_apd_not_a0:
    CMPI.B  #1, D4
    BNE     ea_apd_not_a1
    JSR     ea_a1               ; output "A1"
    BRA     ea_apd_continue
ea_apd_not_a1:
    CMPI.B  #2, D4
    BNE     ea_apd_not_a2
    JSR     ea_a2               ; output "A2"
    BRA     ea_apd_continue
ea_apd_not_a2:
    CMPI.B  #3, D4
    BNE     ea_apd_not_a3
    JSR     ea_a3               ; output "A3"
    BRA     ea_apd_continue
ea_apd_not_a3:
    CMPI.B  #4, D4
    BNE     ea_apd_not_a4
    JSR     ea_a4               ; output "A4"
    BRA     ea_apd_continue
ea_apd_not_a4:
    CMPI.B  #5, D4
    BNE     ea_apd_not_a5
    JSR     ea_a5               ; output "A5"
    BRA     ea_apd_continue
ea_apd_not_a5:
    CMPI.B  #6, D4
    BNE     ea_apd_not_a6
    JSR     ea_a6               ; output "A6"
    BRA     ea_apd_continue
ea_apd_not_a6:
    CMPI.B  #7, D4
    BNE     ea_apd_continue
    JSR     ea_a7               ; output "A7"
ea_apd_continue:
    MOVE.B  #')', (A2)+
    RTS

********************************************
*              EA DISPLACEMENT             *
********************************************
ea_displacement_start:
    CMPI.B  #0,     D1              ; check for 16 bit displacement values
    BNE     ea_displacement_not_16
    JMP     ea_displacement_16
ea_displacement_not_16:
    CMPI.B  #$FF,    D1             ; check for 32 bit displacement values
    BNE     ea_displacement_not_32
    JMP     ea_displacement_32
ea_displacement_not_32:
    LSL.W   #8, D1                  ; ensure the Byte data is prefixed properly as a Long
    ASR.W   #8, D1
    MOVE.L  A0, D4                  ; copy program counter into D4
    ADDI.B  #2, D4                  ; increment program counter by 2
    ADD.B   D1, D4                  ; add the Byte data to the PC+2 -> displacement
    MOVE.W  D4, D3                  ; move displacement value for ITOA output
    MOVE.B  #'$', (A2)+
    JSR     int_to_ascii
    RTS

ea_displacement_16:
    ADDA    #2, A0          ; increment PC for next Word data
    MOVE.L  A0, D4          ; copy program counter into D4
    ADD.W   (A0), D4        ; add next instruction Word to PC -> displacement
    MOVE.W  D4, D3          ; copy displacement for ITOA output
    MOVE.B  #'$', (A2)+
    JSR     int_to_ascii
    RTS
ea_displacement_32:
    ADDA    #2, A0          ; increment PC for next Long data
    MOVE.L  A0, D4          ; copy program counter to D4
    ADD.L   (A0), D4        ; add next instruction Long to PC -> displacement
    MOVE.L  D4, D3          ; copy displacement for ITOA output
    MOVE.B  #'$', (A2)+
    JSR     int_to_ascii
    ADDA    #2, A0          ; increment PC past next Word of Long data
    RTS

ea_mode_seven:
    MOVE.B  D1, D5              ; copy EA instruction to D5 for parsing
    ANDI    #$F, D5             ; clear out first nibble bits of data
    CMPI.B  #$8, D5             ; absolute short address
    BEQ     ea_mode_seven_abs_short
    CMPI.B  #$9, D5             ; absolute long address
    BEQ     ea_mode_seven_abs_long
    CMPI.B  #$C,   D5           ; immediate data
    BEQ     ea_mode_seven_immediate
    BRA     ea_not_supported    ; handle unsupported data

ea_mode_seven_abs_short:
    MOVE.B  #'(', (A2)+     ; output absolute short prefix
    ADDA    #2,    A0       ; increment PC to next Word data
    MOVE.W  (A0), D3        ; move Word data to D3 for output
    MOVE.B  #'$', (A2)+
    JSR     int_to_ascii
    MOVE.B  #')', (A2)+     ; output absolute short suffix
    MOVE.B  #'.', (A2)+
    MOVE.B  #'W', (A2)+
    RTS

ea_mode_seven_abs_long:
    MOVE.B  #'(', (A2)+     ; ouput absolute long prefix
    ADDA    #2,    A0       ; increment PC to next Long data
    MOVE.L  (A0), D3        ; move Long data to D3 for output
    MOVE.B  #'$', (A2)+
    JSR     int_to_ascii
    MOVE.B  #')', (A2)+     ; output absolute long suffix
    MOVE.B  #'.', (A2)+
    MOVE.B  #'L', (A2)+
    ADDA    #2,     A0
    RTS

ea_mode_seven_immediate:
    ADDA    #2, A0          ; increment PC to next Long immediate data
    MOVE.L  (A0), D3        ; move Long immediate data to D3 for ITOA output
    MOVE.B  #'#', (A2)+
    MOVE.B  #'$', (A2)+
    JSR     int_to_ascii
    ADDA    #2, A0
    RTS

ea_not_supported:
    JMP op_finish

********************************************
*           EA REGISTER LIST MASK          *
*               PRE-DECREMENT              *
********************************************
ea_rlm_predecr_start:
    ADDA    #2, A0      ; increment PC to next Word data
    CLR     D3          ; clear data registers
    CLR     D6
    CLR     D7
    MOVE.W  (A0), D7    ; move Word data to D7 for parsing
ea_rlm_pd_data_loop_start:
    LSL.W   #1, D7      ; start parsing RLM backwards
    BCC     ea_rlm_pd_data_loop_end     ; skip 0 bits in RLM
    CMPI.B  #0, D6      ; fence-post check: skip slash separator for first iteration
    BEQ     ea_rlm_pd_data_loop_noslash
    MOVE.B  #'/', (A2)+
ea_rlm_pd_data_loop_noslash:
    MOVE.B  #1, D6      ; set fence-post flag: slash separator

    CMPI.B  #0, D3
    BNE     ea_rlm_pd_not_d0
    JSR     ea_d0       ; output "D0"
ea_rlm_pd_not_d0:
    CMPI.B  #1, D3
    BNE     ea_rlm_pd_not_d1
    JSR     ea_d1       ; output "D1"
    BRA     ea_rlm_pd_data_continue
ea_rlm_pd_not_d1:
    CMPI.B  #2, D3
    BNE     ea_rlm_pd_not_d2
    JSR     ea_d2       ; output "D2"
    BRA     ea_rlm_pd_data_continue
ea_rlm_pd_not_d2:
    CMPI.B  #3, D3
    BNE     ea_rlm_pd_not_d3
    JSR     ea_d3       ; output "D3"
    BRA     ea_rlm_pd_data_continue
ea_rlm_pd_not_d3:
    CMPI.B  #4, D3
    BNE     ea_rlm_pd_not_d4
    JSR     ea_d4       ; output "D4"
    BRA     ea_rlm_pd_data_continue
ea_rlm_pd_not_d4:
    CMPI.B  #5, D3
    BNE     ea_rlm_pd_not_d5
    JSR     ea_d5       ; output "D5"
    BRA     ea_rlm_pd_data_continue
ea_rlm_pd_not_d5:
    CMPI.B  #6, D3
    BNE     ea_rlm_pd_not_d6
    JSR     ea_d6       ; output "D6"
    BRA     ea_rlm_pd_data_continue
ea_rlm_pd_not_d6:
    CMPI.B  #7, D3
    BNE     ea_rlm_pd_data_continue
    JSR     ea_d7       ; output "D7"

ea_rlm_pd_data_continue:
ea_rlm_pd_data_loop_end:
    ADDQ.B  #1,     D3  ; loop 8 times for each bit represending a data register
    CMPI.B  #8,     D3
    BLT     ea_rlm_pd_data_loop_start

    MOVE.B  #0,     D3


ea_rlm_pd_addr_loop_start:
    LSL.W   #1, D7      ; keep parsing RLM for address registers
    BCC     ea_rlm_pd_addr_loop_end     ; skip 0 bits in RLM
    CMPI.B  #1, D6      ; fence-post check: skip slash separator for first iteration
    BNE     ea_rlm_pd_addr_loop_noslash
    MOVE.B  #'/', (A2)+
ea_rlm_pd_addr_loop_noslash:
    MOVE.B  #1, D6      ; set fence-post check

    CMPI.B  #0, D3
    BNE     ea_rlm_pd_not_a0
    JSR     ea_a0       ; output "A0"
ea_rlm_pd_not_a0:
    CMPI.B  #1, D3
    BNE     ea_rlm_pd_not_a1
    JSR     ea_a1       ; output "A1"
    BRA     ea_rlm_pd_addr_continue
ea_rlm_pd_not_a1:
    CMPI.B  #2, D3
    BNE     ea_rlm_pd_not_a2
    JSR     ea_a2       ; output "A2"
    BRA     ea_rlm_pd_addr_continue
ea_rlm_pd_not_a2:
    CMPI.B  #3, D3
    BNE     ea_rlm_pd_not_a3
    JSR     ea_a3       ; output "A3"
    BRA     ea_rlm_pd_addr_continue
ea_rlm_pd_not_a3:
    CMPI.B  #4, D3
    BNE     ea_rlm_pd_not_a4
    JSR     ea_a4       ; output "A4"
    BRA     ea_rlm_pd_addr_continue
ea_rlm_pd_not_a4:
    CMPI.B  #5, D3
    BNE     ea_rlm_pd_not_a5
    JSR     ea_a5       ; output "A5"
    BRA     ea_rlm_pd_addr_continue
ea_rlm_pd_not_a5:
    CMPI.B  #6, D3
    BNE     ea_rlm_pd_not_a6
    JSR     ea_a6       ; output "A6"
    BRA     ea_rlm_pd_addr_continue
ea_rlm_pd_not_a6:
    CMPI.B  #7, D3
    BNE     ea_rlm_pd_addr_continue
    JSR     ea_a7       ; output "A7"
ea_rlm_pd_addr_continue:
ea_rlm_pd_addr_loop_end:
    ADDQ.B  #1,     D3
    CMPI.B  #8,     D3
    BLT     ea_rlm_pd_addr_loop_start

    RTS

********************************************
*           EA REGISTER LIST MASK          *
*               POST-INCREMENT             *
********************************************
ea_rlm_postincr_start:
    ADDA    #2, A0      ; increment PC to next Word data
    CLR     D3          ; clear data registers
    CLR     D6
    CLR     D7
    MOVE.W  (A0), D7    ; move Word data to D7 for parsing

    MOVE.B  #7, D3      ; set D3 to max iteration count -> 0
ea_rlm_pi_addr_loop_start:
    LSL.W   #1, D7      ; start parsing RLM backwards
    BCC     ea_rlm_pi_addr_loop_end     ; skip 0 bits in RLM
    CMPI.B  #1, D6      ; fence-post check: skip slash separator for first iteration
    BNE     ea_rlm_pi_addr_loop_noslash
    MOVE.B  #'/', (A2)+
ea_rlm_pi_addr_loop_noslash:
    MOVE.B  #1, D6      ; set fence-post check

    CMPI.B  #0, D3
    BNE     ea_rlm_pi_not_a0
    JSR     ea_a0       ; output "A0"
ea_rlm_pi_not_a0:
    CMPI.B  #1, D3
    BNE     ea_rlm_pi_not_a1
    JSR     ea_a1       ; output "A1"
    BRA     ea_rlm_pi_addr_continue
ea_rlm_pi_not_a1:
    CMPI.B  #2, D3
    BNE     ea_rlm_pi_not_a2
    JSR     ea_a2       ; output "A2"
    BRA     ea_rlm_pi_addr_continue
ea_rlm_pi_not_a2:
    CMPI.B  #3, D3
    BNE     ea_rlm_pi_not_a3
    JSR     ea_a3       ; output "A3"
    BRA     ea_rlm_pi_addr_continue
ea_rlm_pi_not_a3:
    CMPI.B  #4, D3
    BNE     ea_rlm_pi_not_a4
    JSR     ea_a4       ; output "A4"
    BRA     ea_rlm_pi_addr_continue
ea_rlm_pi_not_a4:
    CMPI.B  #5, D3
    BNE     ea_rlm_pi_not_a5
    JSR     ea_a5       ; output "A5"
    BRA     ea_rlm_pi_addr_continue
ea_rlm_pi_not_a5:
    CMPI.B  #6, D3
    BNE     ea_rlm_pi_not_a6
    JSR     ea_a6       ; output "A6"
    BRA     ea_rlm_pi_addr_continue
ea_rlm_pi_not_a6:
    CMPI.B  #7, D3
    BNE     ea_rlm_pi_addr_continue
    JSR     ea_a7       ; output "A7"
ea_rlm_pi_addr_continue:
ea_rlm_pi_addr_loop_end:
    SUBQ.B  #1,     D3  ; decrement loop counter
    CMPI.B  #0,     D3
    BGE     ea_rlm_pi_addr_loop_start

    MOVE.B  #7, D3      ; reset loop counter to 7 for data register output
ea_rlm_pi_data_loop_start:
    LSL.W   #1, D7      ; continue parsing RLM backwards
    BCC     ea_rlm_pi_data_loop_end     ; skip 0 bits in RLM
    CMPI.B  #0, D6      ; fence-post check: skip slash separator for first iteration
    BEQ     ea_rlm_pi_data_loop_noslash
    MOVE.B  #'/', (A2)+
ea_rlm_pi_data_loop_noslash:
    MOVE.B  #1, D6      ; set fence-post check

    CMPI.B  #0, D3
    BNE     ea_rlm_pi_not_d0
    JSR     ea_d0       ; output "D0"
ea_rlm_pi_not_d0:
    CMPI.B  #1, D3
    BNE     ea_rlm_pi_not_d1
    JSR     ea_d1       ; output "D1"
    BRA     ea_rlm_pi_data_continue
ea_rlm_pi_not_d1:
    CMPI.B  #2, D3
    BNE     ea_rlm_pi_not_d2
    JSR     ea_d2       ; output "D2"
    BRA     ea_rlm_pi_data_continue
ea_rlm_pi_not_d2:
    CMPI.B  #3, D3
    BNE     ea_rlm_pi_not_d3
    JSR     ea_d3       ; output "D3"
    BRA     ea_rlm_pi_data_continue
ea_rlm_pi_not_d3:
    CMPI.B  #4, D3
    BNE     ea_rlm_pi_not_d4
    JSR     ea_d4       ; output "D4"
    BRA     ea_rlm_pi_data_continue
ea_rlm_pi_not_d4:
    CMPI.B  #5, D3
    BNE     ea_rlm_pi_not_d5
    JSR     ea_d5       ; output "D5"
    BRA     ea_rlm_pi_data_continue
ea_rlm_pi_not_d5:
    CMPI.B  #6, D3
    BNE     ea_rlm_pi_not_d6
    JSR     ea_d6       ; output "D6"
    BRA     ea_rlm_pi_data_continue
ea_rlm_pi_not_d6:
    CMPI.B  #7, D3
    BNE     ea_rlm_pi_data_continue
    JSR     ea_d7       ; output "D7"

ea_rlm_pi_data_continue:
ea_rlm_pi_data_loop_end:
    SUBQ.B  #1,     D3  ; decrement loop counter
    CMPI.B  #0,     D3
    BGE     ea_rlm_pi_data_loop_start

    RTS

********************************************
*            EA DATA REGISTER              *
********************************************
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

ea_data_register:
    MOVE.B  D1, D4      ; copy Byte data of EA instruction to D4 for parsing
    ANDI    #7, D4      ; clear first bit
    CMPI.B  #0, D4
    BEQ     ea_d0       ; D0
    CMPI.B  #1, D4
    BEQ     ea_d1       ; D1
    CMPI.B  #2, D4
    BEQ     ea_d2       ; D2
    CMPI.B  #3, D4
    BEQ     ea_d3       ; D3
    CMPI.B  #4, D4
    BEQ     ea_d4       ; D4
    CMPI.B  #5, D4
    BEQ     ea_d5       ; D5
    CMPI.B  #6, D4
    BEQ     ea_d6       ; D6
    CMPI.B  #7, D4
    BEQ     ea_d7       ; D7

********************************************
*            EA ADDRESS REGISTER           *
********************************************
ea_a0:
    MOVE.B #'A', (A2)+
    MOVE.B #'0', (A2)+
    RTS
ea_a1:
    MOVE.B #'A', (A2)+
    MOVE.B #'1', (A2)+
    RTS
ea_a2:
    MOVE.B #'A', (A2)+
    MOVE.B #'2', (A2)+
    RTS
ea_a3:
    MOVE.B #'A', (A2)+
    MOVE.B #'3', (A2)+
    RTS
ea_a4:
    MOVE.B #'A', (A2)+
    MOVE.B #'4', (A2)+
    RTS
ea_a5:
    MOVE.B #'A', (A2)+
    MOVE.B #'5', (A2)+
    RTS
ea_a6:
    MOVE.B #'A', (A2)+
    MOVE.B #'6', (A2)+
    RTS
ea_a7:
    MOVE.B #'A', (A2)+
    MOVE.B #'7', (A2)+
    RTS

ea_address_register:
    MOVE.B  D1, D4      ; copy Byte data of EA instruction to D4 for parsing
    ANDI    #7, D4      ; clear out first bit
    CMPI.B  #0, D4
    BEQ     ea_a0
    CMPI.B  #1, D4
    BEQ     ea_a1
    CMPI.B  #2, D4
    BEQ     ea_a2
    CMPI.B  #3, D4
    BEQ     ea_a3
    CMPI.B  #4, D4
    BEQ     ea_a4
    CMPI.B  #5, D4
    BEQ     ea_a5
    CMPI.B  #6, D4
    BEQ     ea_a6
    CMPI.B  #7, D4
    BEQ     ea_a7


********************************************
*            EA ADDRESS                    *
********************************************
ea_address:
    MOVE.B  #'(',   (A2)+
    MOVE.B  D1,     D4      ; copy EA instruction to D4 for parsing
    ANDI    #$7,    D4      ; clear out first bit
    CMPI.B  #0, D4
    BNE     ea_address_not_a0
    JSR     ea_a0           ; output "A0"
ea_address_not_a0:
    CMPI.B  #1, D4
    BNE     ea_address_not_a1
    JSR     ea_a1           ; output "A1"
    BRA     ea_address_continue
ea_address_not_a1:
    CMPI.B  #2, D4
    BNE     ea_address_not_a2
    JSR     ea_a2           ; output "A2"
    BRA     ea_address_continue
ea_address_not_a2:
    CMPI.B  #3, D4
    BNE     ea_address_not_a3
    JSR     ea_a3           ; output "A3"
    BRA     ea_address_continue
ea_address_not_a3:
    CMPI.B  #4, D4
    BNE     ea_address_not_a4
    JSR     ea_a4           ; output "A4"
    BRA     ea_address_continue
ea_address_not_a4:
    CMPI.B  #5, D4
    BNE     ea_address_not_a5
    JSR     ea_a5           ; output "A5"
    BRA     ea_address_continue
ea_address_not_a5:
    CMPI.B  #6, D4
    BNE     ea_address_not_a6
    JSR     ea_a6           ; output "A6"
    BRA     ea_address_continue
ea_address_not_a6:
    CMPI.B  #7, D4
    BNE     ea_address_continue
    JSR     ea_a7           ; output "A6"
ea_address_continue:
    MOVE.B  #')', (A2)+
    RTS

********************************************
*              SIZE PARSER                 *
********************************************
light_purple_size:
    MOVE.B  #'.', (A2)+
    LSR     #1, D3      ; check LSB of D3
    BCS     size_w      ; if 1, size W
    LSR     #1, D3      ; check second LSB of D3
    BCS     size_l      ; if 1, size L
    BRA     size_b      ; else size B

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
    MOVE.W  (A0), D5        ; Move current instruction into D5
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
    CMPI    #$A, D5         ; EORI
    BEQ     op_eori
    CMPI    #$C, D5         ; CMPI
    BEQ     op_cmpi
    BRA     op_unsupported

code0001:                   ; MOVE(A).B
    BRA     op_move
code0010:                   ; MOVA(A).L
    BRA     op_move
code0011:                   ; MOVE(A).W
    BRA     op_move

code0100:
    MOVE.W  (A0), D5        ; moves instruction to temp register (D5)
    MOVE.W  D5, D1          ; loads into EA register
    LSR     #8, D5          ; gets the first 8 bits
    CMPI.B  #$42, D5        ; 0100 0010
    BEQ     op_clr          ; CLR
    CMPI.B  #$46, D5        ; 0100 0110
    BEQ     op_not          ; NOT
    MOVE.W  D1, D5          ; resets temp register
    LSR.W   #3, D5          ; gets first 13 bits
    ANDI.B  #$7, D5         ; clears size bit
    CMPI.W  #$900, D5       ; 0100 1000
    BEQ     op_ext          ; EXT
    MOVE.W  D1, D5          ; resets d5 to full instruction
    LSR     #4, D5          ; get first 12 bits
    CMPI.B  #$E4, D5        ; 0100 1110
    BEQ     op_trap         ; TRAP
    LSR     #2, D5          ; gets the first 10 bits
    ANDI.B  #$7, D5         ; clear size bit
    CMPI.B  #$7, D5
    BEQ     op_lea          ; LEA
    MOVE.W  D1, D5
    LSR     #6, D5
* Constant OP codes (NOP, STOP, RTE, RTS)
    CMPI.W  #$4E71, (A0)
    BEQ     op_nop
    CMPI.W  #$4E72, (A0)
    BEQ     op_stop
    CMPI.W  #$4E73, (A0)
    BEQ     op_rte
    CMPI.W  #$4E75, (A0)
    BEQ     op_rts
    CMPI.W  #$13A,   D5
    BEQ     op_jsr
    CMPI.W  #$13B,   D5
    BEQ     op_jmp
    LSR     #1, D5
    ANDI.B  #1, D5
    CMPI.B  #$1, D5
    BEQ     op_movem

code0101:
    MOVE.W (A0), D5
    MOVE.W  D5, D1
    LSR.W   #8,  D5
    LSR.W   #1,  D5     ; check 9th LSB for ADDQ/SUBQ
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
    MOVE.W  D5, D1
    LSR.W   #7,  D5
    BCC     op_or
    LSR.W   #1,  D5
    BCC     op_or
    LSR.W   #1,  D5
    BCC     op_divu
    BRA     op_divs

code1001:
    MOVE.W  D5, D1
    BRA     op_sub

code1011:
    MOVE.W  (A0), D5
    MOVE.W  D5, D1
    LSL.W   #8,   D5
    BCS     op_eor
    BRA     op_cmp

code1100:
    MOVE.W (A0), D5
    MOVE.W  D5, D1
    LSR.W  #7,  D5
    BCC     op_and
    LSR.W   #1, D5
    BCC     op_and
    LSR.W   #1, D5
    BCC     op_mulu
    BRA     op_muls

code1101:
    MOVE.W  (A0), D5
    MOVE.W  D5, D1
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
    JSR     ea_immediate_start
    JMP     op_finish

op_andi:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'N', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    JSR     ea_immediate_start
    JMP     op_finish

op_subi:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'B', (A2)+
    MOVE.B  #'I', (A2)+
    JSR     ea_immediate_start
    JMP     op_finish

op_addi:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    JSR     ea_immediate_start
    JMP     op_finish

op_eori:
    MOVE.B  #'E', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #'I', (A2)+
    JSR     ea_immediate_start
    JMP     op_finish

op_cmpi:
    MOVE.B  #'C', (A2)+
    MOVE.B  #'M', (A2)+
    MOVE.B  #'P', (A2)+
    MOVE.B  #'I', (A2)+
    JSR     ea_immediate_start
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
    BNE     dark_purple_sizing1
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
    MOVE.B  #' ', (A2)+
    JSR     ea_start
    LSR.W   #6, D1      ; flip SRC/DESTINATION
    MOVE.B  D1, D7
    LSR.B   #3, D7
    LSL.B   #3, D1
    ANDI    #$7, D7
    ANDI    #$38, D1
    OR      D7, D1
    LSR.B   #2, D7
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    JSR     ea_start
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
    BRA     op_not_clr_continue
op_not:
    MOVE.B  #'N', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'T', (A2)+
op_not_clr_continue:
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    MOVE.B  #' ', (A2)+
    JSR     ea_start
    JMP     op_finish
op_ext:
    MOVE.B  #'E', (A2)+
    MOVE.B  #'X', (A2)+
    MOVE.B  #'T', (A2)+
    MOVE.B  #'.', (A2)+
    MOVE.W  (A0), D5
    LSR.B   #7,   D5
    BCC     opext_size_word
    BRA     opext_size_long

opext_size_word:
    MOVE.B  #'W',   (A2)+
    BRA     opext_continue

opext_size_long:
    MOVE.B  #'L',   (A2)+
    BRA     opext_continue

opext_continue:
    MOVE.B  #' ', (A2)+
    MOVE.B  (A0), D3
    JSR     ea_start
    JMP     op_finish

op_trap:
    MOVE.B  #'T', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #'A', (A2)+
    MOVE.B  #'P', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.B  #'#', (A2)+
    MOVE.W  (A0),   D3
    AND.L   #$0F,   D3
    MOVE.B  #'$', (A2)+
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
    MOVE.B  #' ', (A2)+
    ADDA    #2, A0
    MOVE.W  (A0), D3
    MOVE.B  #'$', (A2)+
    JSR     int_to_ascii
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
    JSR     ea_start
    JMP     op_finish
op_jmp:
    MOVE.B  #'J', (A2)+
    MOVE.B  #'M', (A2)+
    MOVE.B  #'P', (A2)+
    MOVE.B  #' ', (A2)+
    JSR     ea_start
    JMP     op_finish
op_movem:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'O', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'E', (A2)+
    MOVE.B  #'M', (A2)+
    CLR     D3
    MOVE.W  (A0), D3
    LSR     #7, D3
    BCS     op_movem_size_long
    MOVE.B  #%01, D3
    BRA     op_movem_size_continue
op_movem_size_long:
    MOVE.B  #%10, D3
op_movem_size_continue:
    JSR     light_purple_size

    MOVE.B  #' ', (A2)+

    CLR     D3
    MOVE.B  (A0), D3
    LSR.B   #3, D3      ; check direction bit
    BCS     op_movem_reg_to_mem
    JSR     op_movem_register
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    JSR     ea_start
    JMP     op_finish
op_movem_reg_to_mem:
    JSR     ea_start
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    JSR     op_movem_register
    JMP     op_finish

op_movem_register:
    CLR     D3
    MOVE.W  (A0), D3
    LSR.B   #3, D3
    ANDI.B  #7, D3      ; check 3 bits
    CMPI.B  #4, D3
    BEQ     ea_rlm_predecr_start
    BRA     ea_rlm_postincr_start

op_lea:
    MOVE.B  #'L', (A2)+
    MOVE.B  #'E', (A2)+
    MOVE.B  #'A', (A2)+
    JSR     ea_start
    MOVE.B  (A0), D1    ; move DEST into EA register
    LSR     #1, D1
    ANDI    #$F,    D1
    JSR     ea_start
    JMP     op_finish

********************************************
*                 OP 0101                  *
********************************************
op_addq:
    MOVE.B  #'A', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'D', (A2)+
    MOVE.B  #'Q', (A2)+
    CLR.L   D3
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    MOVE.B  #' ', (A2)+
    MOVE.B  #'#', (A2)+
    CLR.L   D3
    MOVE.B  (A0), D3
    LSR     #1, D3
    ANDI    #7, D3
    MOVE.B #'$', (A2)+
    JSR     int_to_ascii
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.W  (A0), D1
    JSR     ea_start
    JMP     op_finish
op_subq:
    MOVE.B  #'S', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'B', (A2)+
    MOVE.B  #'Q', (A2)+
    CLR.L   D3
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    MOVE.B  #' ', (A2)+
    MOVE.B  #'#', (A2)+
    CLR.L   D3
    MOVE.B  (A0), D3
    LSR     #1, D3
    ANDI    #7, D3
    MOVE.B #'$', (A2)+
    JSR     int_to_ascii
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.W  (A0), D1
    JSR     ea_start
    JMP     op_finish

********************************************
*                 OP 0110                  *
********************************************
op_bra:
    MOVE.B  #'B', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #'A', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.W  (A0),   D1
    ANDI    #$FF,   D1
    JSR     ea_displacement_start
    JMP     op_finish

op_bsr:
    MOVE.B  #'B', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.B  #'R', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.W  (A0),   D1
    ANDI    #$F,    D1
    JSR     ea_displacement_start
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
    MOVE.B #' ', (A2)+
    MOVE.W  (A0),   D1
    ANDI    #$F,    D1
    JSR     ea_displacement_start
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
    MOVE.B  #' ', (A2)+
    MOVE.B  #'#', (A2)+
    MOVE.W  (A0),  D3
    ANDI.W  #$FF,   D3
    MOVE.B #'$', (A2)+
    JSR     int_to_ascii
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.B  (A0), D1
    LSR     #1, D1
    ANDI    #$7, D1
    JSR     ea_start
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
    MOVE.B  #' ', (A2)+
    MOVE.W  (A0), D1
    JSR     ea_start
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    CLR.L   D1
    MOVE.B  (A0), D1
    LSR     #1, D1
    ANDI    #7, D1
    JSR     ea_start
    JMP     op_finish
op_divs:
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.W  (A0), D1
    JSR     ea_start
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    CLR.L   D1
    MOVE.B  (A0), D1
    LSR     #1, D1
    ANDI    #7, D1
    JSR     ea_start
    JMP     op_finish

op_divu:
    MOVE.B  #'D', (A2)+
    MOVE.B  #'I', (A2)+
    MOVE.B  #'V', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #' ', (A2)+
    MOVE.W  (A0), D1
    JSR     ea_start
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    CLR.L   D1
    MOVE.B  (A0), D1
    LSR     #1, D1
    ANDI    #7, D1
    JSR     ea_start
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
    MOVE.B  #' ', (A2)+
    MOVE.W  (A0), D1
    JSR     ea_start
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    CLR.L   D1
    MOVE.B  (A0), D1
    LSR     #1, D1
    ANDI    #7, D1
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
    MOVE.B  #' ', (A2)+
    MOVE.B  (A0), D1
    LSR     #1, D1
    ANDI    #7, D1
    JSR     ea_start
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    CLR.L   D1
    MOVE.W  (A0), D1
    JSR     ea_start
    JMP     op_finish
op_cmp:
    MOVE.B #'C', (A2)+
    MOVE.B #'M', (A2)+
    MOVE.B #'P', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    MOVE.B  #' ', (A2)+
    MOVE.W  (A0), D1
    JSR     ea_start
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    CLR.L   D1
    MOVE.B  (A0), D1
    LSR     #1, D1
    ANDI    #7, D1
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
    MOVE.B  #' ', (A2)+
    MOVE.W  (A0), D1
    JSR     ea_start
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    CLR.L   D1
    MOVE.B  (A0), D1
    LSR     #1, D1
    ANDI    #7, D1
    JSR     ea_start
    JMP     op_finish

op_mulu:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'L', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    MOVE.B  #' ', (A2)+
    MOVE.W  (A0), D1
    JSR     ea_start
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    CLR.L   D1
    MOVE.B  (A0), D1
    LSR     #1, D1
    ANDI    #7, D1
    JSR     ea_start
    JMP     op_finish

op_muls:
    MOVE.B  #'M', (A2)+
    MOVE.B  #'U', (A2)+
    MOVE.B  #'L', (A2)+
    MOVE.B  #'S', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    JSR     light_purple_size
    MOVE.B  #' ', (A2)+
    MOVE.W  (A0), D1
    JSR     ea_start
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    CLR.L   D1
    MOVE.B  (A0), D1
    LSR     #1, D1
    ANDI    #7, D1
    JSR     ea_start
    JMP     op_finish
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
    MOVE.B  #' ', (A2)+
    MOVE.W  (A0), D1
    JSR     ea_start
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    CLR.L   D1
    MOVE.B  (A0), D1
    LSR     #1, D1
    ANDI    #7, D1
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
    MOVE.B  #' ', (A2)+
    MOVE.W  (A0), D1
    JSR     ea_start
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    CLR.L   D1
    MOVE.B  (A0), D1
    LSR     #1, D1
    ANDI    #$F, D1
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
    LSL.W   #8, D5
    BCS     op_shift_left_ea
    MOVE.B  #'R', (A2)+
    BRA     op_shift_ea_continue
op_shift_left_ea:
    MOVE.B  #'L', (A2)+
op_shift_ea_continue:
    MOVE.W  (A0), D1
    ANDI    #$FF,    D1
    MOVE.B  #' ', (A2)+
    JSR     ea_start
    JMP     op_finish

op_shift_reg:
    MOVE.W  (A0), D5
    LSL.W   #8, D5
    BCS     op_shiftleft_reg
    MOVE.B  #'R', (A2)+
    BRA     op_shift_reg_continue
op_shiftleft_reg:
    MOVE.B  #'L', (A2)+
op_shift_reg_continue:
    MOVE.W  (A0), D3
    LSR.W   #6, D3
    JSR     light_purple_size
    MOVE.B  #' ', (A2)+
    MOVE.W  (A0), D3
    LSR     #6, D3
    BCS     op_shift_is_register
    CLR     D3
    MOVE.B  (A0), D3
    LSR.B   #1, D3
    ANDI.B  #$7, D3
    MOVE.B #'$', (A2)+
    JSR int_to_ascii
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    CLR     D1
    MOVE.W  (A0), D1
    ANDI.L  #$7, D1
    JSR ea_start
    JMP op_finish

op_shift_is_register:
    MOVE.B  (A0), D1
    LSR.W   #1, D1
    ANDI.B  #$7, D1
    JSR ea_start
    MOVE.B  #',', (A2)+
    MOVE.B  #' ', (A2)+
    CLR     D1
    MOVE.W  (A0), D1
    ANDI.L  #$7, D1
    JSR ea_start
    JMP op_finish



op_finish:
    MOVE.B  #$0D, (A2)+     ; CR
    MOVE.B  #$0A, (A2)+     ; LF
    MOVE.B  #0, (A2)+       ; prepare for output
    MOVEA   #0, A1
    MOVE.B  #14, D0
    TRAP    #15             ; send to console
    MOVE.L  #0, A2          ; reset A2
    ADDA    #2, A0          ; increment PC
    BRA     ui_op_finish    ; handle UI

ui_op_finish:
    MOVEM   (A7)+, D0-D7    ; move OP data registers to stack
    CMPA    A0, A3          ; check if 0 >= A3
    BLT     ui_start        ; if so, restart program
    ADDI.B  #1, D3          ; increment UI line output counter
    CMPI.B  #29, D3         ; if not full, continue
    BLE     op_start
    MOVE.B  #14, D0         ; output "continue" message
    LEA     continue_page, A1
    TRAP    #15
    MOVE.B  #2, D0
    MOVEA.L #$0, A1         ; reset A1 to avoid overwriting "continue" message in future
    TRAP    #15
    CLR     D3              ; reset D3
    BRA     op_start
********************************************
*                 ITOA                     *
********************************************


int_to_ascii:
    CLR.L   D5
itoa_start:
    ROL.L   #4, D3      ; move most significant Byte to front
    MOVE.B  D3, D4      ; copy to D4
    ANDI.B  #$0F, D4    ; clear out most significant nibble
    ADDI.B  #$30, D4    ; add $30
    CMPI.B  #$3A, D4    ; >= $3A -> character
    BGE     itoa_character
itoa_continue:
    MOVE.B  D4, (A2)+   ; output digit
    ADDI.B  #1, D5      ; increment loop counter
    CMPI.B  #8, D5
    BNE     itoa_start
    RTS
itoa_character:
    ADDI.B  #7, D4      ; add 7 to ASCII code
    JMP     itoa_continue

;itoa_negative:
    ;NOT.L    D3
   ; ADDI    #1, D3
   ; JMP itoa_buffer
********************************************
*                 ATOI                     *
********************************************
ascii_to_int:
    MOVEM D0-D7, -(A7)
    CLR D6
    CLR D5
    CLR D4
    CLR D3
    CLR D2
    MOVEA.L #$0, A3
    MOVE.L (A1), D5
    MOVE.B  #$1, D2


atoi_start:
    MOVE.B  D5, D4
    CMPI.B  #$0, D4     ; if 0, continue
    BEQ     atoi_loop_continue
    CMPI.B  #$FF, D4    ; if $FF, continue
    BEQ     atoi_loop_continue
    CMPI.B  #$30, D4    ; < $30, invalid
    BLT     invalid_ascii
    CMPI.B  #$39, D4    ; <= $39, integer
    BLE     atoi_integer
    CMPI.B  #$41, D4    ; < $41, invalid
    BLT     invalid_ascii
    CMPI.B  #$5A, D4    ; <= $5A, uppercase char
    BLE     atoi_uppercase
    CMPI.B  #$61, D4    ; < $61, invalid
    BLT     invalid_ascii
    CMPI.B  #$7A, D4    ; <= $7A, lowercase char
    BLE     atoi_lowercase
    BRA     invalid_ascii   ; invalid


atoi_integer:
    SUBI.B  #$30, D4    ; sub $30 from int char
    MULU.W  D2, D4
    ADDA.L  D4, A3
    LSL.L   #4, D2      ; continue loop
    BRA     atoi_loop_continue
atoi_uppercase:
    SUBI.B  #$41, D4    ; sub $41 from upper char
    MULU.W  D2, D4
    ADDA.L  D4, A3
    LSL.L   #4, D2      ; continue loop
    BRA     atoi_loop_continue
atoi_lowercase:
    SUBI.B  #$61, D4    ; sub $61 from lower char
    MULU.W  D2, D4
    ADDA.L  D4, A3
    LSL.L   #4, D2      ; continue loop
    BRA     atoi_loop_continue
atoi_loop_continue:
    ROR.L   #8, D5      ; move to next ASCII character
    ADDI.B  #1, D6      ; increment loop counter
    CMPI.B  #4, D6
    BNE     atoi_start
atoi_loop_end:
    MOVEM (A7)+, D0-D7
    RTS

********************************************
*                 ERROR HANDLER            *
********************************************

op_unsupported:
    MOVE.L A0, D3
    ADDA   #$2, A0
    JSR     int_to_ascii
    BRA     op_finish

invalid_address_start:
    LEA     invalid_address_start_message, A1
    MOVE.B  #14, D0
    TRAP    #15
    BRA     ui_start

invalid_address_end:
    LEA     invalid_address_end_message, A1
    MOVE.B  #14, D0
    TRAP    #15
    BRA     ui_start_end_prompt

invalid_ascii:
    LEA     invalid_ascii_message, A1
    MOVE.B  #14, D0
    TRAP    #15
    BRA     ui_start
* CONSTANTS

CR                      EQU     $0D
LF                      EQU     $0A
welcome_message         DC.B    'Welcome to the 68k disassembler.',CR,LF,0
prompt_start_message    DC.B    'Enter start address: ',0,0
ascii_start             DS.B    4
continue_page           DC.B    'Press enter to continue', CR, LF, 0
prompt_end_message      DC.B    'Enter end address:',0,0
invalid_address_start_message   DC.B    'Invalid address start', CR, LF, 0
invalid_address_end_message     DC.B    'Invalid address end',  CR, LF, 0
invalid_ascii_message       DC.B    'Invalid ASCII character(s)', CR, LF, 0
end:
    SIMHALT             ; halt simulator
    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
