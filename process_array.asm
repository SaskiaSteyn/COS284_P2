; ==========================
; Group member 01: Amadeus_Fidos_u22526162
; Group member 02: Saskia_Steyn_u17267162
; ==========================

section .data
    prompt db "Enter values separated by whitespace and enclosed in pipes (|):", 0
    fmt_sum db "The sum of the processed array is: %f", 10, 0

section .bss
    input_buffer resb 256
    num_floats resd 1

section .text
global processArray
global mainFunc
extern printf
extern free
extern malloc
extern convertStringToFloat
extern extractAndConvertFloats

; Function: processArray
; Processes an array of floats: converts to double, multiplies each by the next, and sums the results
processArray:
    ; rdi - pointer to float array
    ; rsi - size of the array
    ; Returns double (sum) in xmm0

    ; Check if the array size is less than 2
    cmp rsi, 2
    jl .no_process

    xor rax, rax               ; Clear RAX (index)
    mov rbx, rdi               ; RBX = pointer to the float array
    mov rcx, rsi               ; RCX = size

    xorps xmm0, xmm0           ; Clear xmm0 (sum)

.process_loop:
    movss xmm1, [rbx + rax*4] ; Load float into xmm1
    movss xmm2, [rbx + (rax + 1)*4] ; Load next float into xmm2

    cvtss2sd xmm1, xmm1        ; Convert single-precision to double-precision
    cvtss2sd xmm2, xmm2

    mulsd xmm1, xmm2           ; Multiply
    addsd xmm0, xmm1           ; Add to sum

    add rax, 1                 ; Increment index
    dec rcx                    ; Decrement size
    cmp rcx, 1                 ; Check if we are done
    jg .process_loop

.no_process:
    ret

; Main function
mainFunc:
    ; Set up stack frame
    push rbp
    mov rbp, rsp
    sub rsp, 256               ; Reserve space for local variables (e.g., buffer)

    ; Print prompt
    mov rdi, prompt
    xor rax, rax
    call printf

    ; Extract and convert floats
    lea rdi, [input_buffer]    ; rdi = address of input buffer
    lea rsi, [num_floats]      ; rsi = address of numFloats (integer)
    call extractAndConvertFloats

    ; Check if conversion was successful
    test rax, rax              ; Check if the pointer is NULL
    jz .done

    ; Print converted numbers
    mov rdi, rax               ; rdi = pointer to float array
    mov rsi, [num_floats]      ; rsi = number of floats
    mov rcx, rsi
    xor rbx, rbx               ; index for loop

.print_loop:
    movss xmm0, [rdi + rbx*4] ; Load float into xmm0
    mov rdi, fmt_sum
    call printf                ; Print float
    add rbx, 1                 ; Increment index
    cmp rbx, rcx               ; Check if done
    jl .print_loop

    ; Process array
    call processArray          ; Process and get sum in xmm0
    mov rdi, fmt_sum
    call printf                ; Print the result

    ; Free allocated memory
    mov rdi, rax               ; rdi = pointer to float array
    call free

.done:
    ; Clean up stack frame and return
    mov rsp, rbp
    pop rbp
    ret
