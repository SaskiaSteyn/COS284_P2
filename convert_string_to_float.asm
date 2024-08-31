; ==========================
; Group member 01: Name_Surname_student-nr
; Group member 02: Name_Surname_student-nr
; ==========================
section .bss
    endptr resq 1

section .data
    global convertStringToFloat

section .text
    extern strtof 

convertStringToFloat:
    ; rdi - const char *str
    ; Call strtof to convert the string to a float
    ; rdi = input string
    lea rsi, [endptr]
    call strtof
    
    ret