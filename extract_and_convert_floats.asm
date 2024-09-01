section .data
    prompt db "Enter values separated by whitespace and enclosed in pipes (|):", 0
    prompt_len equ $-prompt
    input_prompt db "Enter input: ", 0

    global skip_space
    global extract_floats

section .bss
    input_buffer resb 256    ; Buffer for input string (256 bytes)
    float_array resd 100     ; Temporary buffer for up to 100 floats
    endptr resq 1

section .text
global extractAndConvertFloats
extern convertStringToFloat ; External function from Task 1
extern malloc               ; To allocate memory
extern free                 ; To free memory
extern stdin                ; Standard input
extern stdout               ; Standard output
extern strtof 

; Function: extractAndConvertFloats
; Extract floats from a string formatted with pipes and spaces
extractAndConvertFloats:
    push rbp
    mov rbp, rsp

    ; Print prompt
    mov rax, 1              ; SYS_write
    mov rdi, 1              ; file descriptor (stdout)
    lea rsi, [prompt]       ; address of prompt
    mov rdx, prompt_len     ; length of prompt
    syscall

    ; Read input into input_buffer
    mov rdi, 0              ; file descriptor (stdin)
    lea rsi, [input_buffer] ; address of input_buffer
    mov rdx, 256            ; buffer size
    mov rax, 0              ; SYS_read
    syscall

    ; Ensure the input buffer is null-terminated
    ; mov byte [input_buffer + rax - 1], 0

    ; Initialize pointers and counters
    lea r12, [input_buffer] ; RSI points to input_buffer
    lea r13, [float_array]  ; RDI points to float_array
    mov r14, 0
    xor r14, r14            ; RCX = float counter

    ; Find the first pipe '|'
.find_pipe:
    mov al, [r12]
    cmp al, '|'
    je .found_pipe
    test al, al             ; Check for end of string (null terminator)
    jz .end_extract        ; If null terminator found, end extraction
    inc r12
    jmp .find_pipe

.found_pipe:
    inc r12                 ; Move past the first pipe

    ; Start extracting floats
.extract_floats:
    mov al, [r12]
    cmp al, '|'
    je .end_extract         ; If the second pipe is found, end extraction

    cmp al, ' '
    je .skip_space          ; Skip spaces

    ; Process a float substring
    lea rdi, [r12]          ; RDI points to the start of the number substring
    ; mov [input_buffer], rsi
    lea rsi, [endptr]
    call strtof ; Convert string to float (result in rax)

    ; Store result in float_array
    movss [float_array + r14*4], xmm0 ; Store the result in the array
    inc r14                 ; Increment the float counter
    jmp .loop_to_next_space

.skip_space:
    inc r12                 ; Move to the next character
    cmp byte [r12], 0x00      ; Check if end of string (null terminator) (segfault happens)
    jz .end_extract
    jmp .extract_floats

.loop_to_next_space:
    mov al, [r12]
    cmp al, ' '
    je .skip_space 
    inc r12
    jmp .loop_to_next_space

.end_extract:
    ; Allocate memory for the number of floats found
    mov rdi, r14            ; RDI = number of floats
    imul rdi, 4              ; RDI = number of floats * sizeof(float)
    call malloc             ; Allocate memory for floats
    test rax, rax           ; Check if malloc succeeded
    jz .malloc_failed       ; Jump to failure handler if NULL

    ; Copy floats into dynamically allocated array
    mov rsi, float_array    ; RSI points to the temporary float array
    mov rdi, rax            ; RDI points to the dynamically allocated array
    mov rcx, r14

.copy_floats:
    test rcx, rcx
    jz .copy_done

    movd xmm0, [rsi]        ; Load float from the temporary array into xmm0
    movd [rdi], xmm0        ; Store float in dynamically allocated array
    add rsi, 4              ; Move to the next float in temp array
    add rdi, 4              ; Move to the next float in allocated array
    dec rcx
    jmp .copy_floats

.copy_done:
    ; Set the number of floats
    lea rdi, [rbp+16]       ; RDI = address of num_floats (first argument)
    mov [rdi], r14          ; Set num_floats to the number of floats found

    ; Return pointer to dynamically allocated array
    mov rax, rax            ; Return the pointer in RAX

    ; Clean up stack frame and return
    leave
    ret

.malloc_failed:
    ; Handle malloc failure (set num_floats to 0 and return NULL)
    mov rdi, [rbp+16]       ; RDI = address of num_floats (first argument)
    mov dword [rdi], 0      ; Set num_floats to 0
    mov rax, 0              ; Return NULL in RAX
    mov rsp, rbp
    pop rbp
    ret
