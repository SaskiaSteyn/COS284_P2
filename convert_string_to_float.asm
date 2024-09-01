; ==========================
; Group member 01: Amadeus_Fidos_u22526162
; Group member 02: Saskia_Steyn_u17267162
; ==========================
section .bss
    endptr resq 1

section .data
    global convertStringToFloat

section .text
    extern strtof 

convertStringToFloat:
    lea rsi, [endptr]
    call strtof
    
    ret