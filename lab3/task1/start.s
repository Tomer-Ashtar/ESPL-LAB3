section .data
    ; ASCII newline character
    newline: db 0xA
    fail_msg: db "something has failed", 0xA
    
    
section .rodata

section .bss
    buffer: resb 256
    bufsiz: resb 256
    in_file_descriptor: resd 1
    out_file_descriptor: resd 1
    in_file_name: resb 256
    out_file_name: resb 256

    
section .text
global _start, exit_program, encode

_start:
    mov dword [in_file_descriptor], 0
    mov dword [out_file_descriptor], 1
    mov eax, 1
    mov ebx, 1
    mov esi, 2
    
print_args_loop:
    cmp esi, [esp]
    jg encode
    mov ecx, DWORD [esi*4 + esp]
    mov ebp, ecx  
     
file_name_check:
     mov al, [ecx]
     cmp al, '-'
     jne print_string_loop
     mov al, [ecx+1]
     cmp al, 'i'
     jne check3
     jmp input_file_update
     check3:
     mov al, [ecx+1]
     cmp al, 'o'
     jne print_string_loop
     jmp output_file_update
;==============input file update=====================    
input_file_update:
     mov edi, in_file_name
     
     in_file_string_loop:
        mov al, [ecx+2]
        cmp al, 0
        je in_end_loop
        ; Save the character in the output buffer
        mov [edi], al
        add ecx, 1          ; Move to the next character
        add edi, 1
        jmp in_file_string_loop

    in_end_loop: 
    push ecx   
    ; Open the file    
    xor eax, eax
    mov eax, 5                ; sys_open
    lea ebx, [in_file_name]   ; Pointer to the file name
    mov ecx, 0                ; File access mode (0 for read-only)
    mov edx, 777
    int 0x80                  ; Call kernel
    pop ecx
    
    ; Check if the file was opened successfully
    cmp eax, -1
    je  exit_program
    mov dword [in_file_descriptor], eax
    mov ebp, 0
    add esi, 1
    mov dword [esi*4 + esp -4], ecx
    jmp print_args_loop
;================output file output============================== 
output_file_update:  
        mov edi, out_file_name
        
        out_file_string_loop:
            mov al, [ecx+2]
            cmp al, 0
            je out_end_loop
            ; Save the character in the output buffer
            mov byte [edi], al
            add ecx, 1          ; Move to the next character
            add edi, 1           
            jmp out_file_string_loop
            
        
    out_end_loop:
    push ecx
    mov byte [edi], 0  
        ;mov eax, 4          ; sys_write
        ;mov ebx, 1         ; stdout
        ;lea ecx, [out_file_name]  ; buffer
        ;mov edx,       ; buffer size (number of bytes read) 
        ;int 0x80            ; Call kernel 
    ; Open the file

    xor eax, eax
    mov eax, 5                ; sys_open
    lea ebx, [out_file_name]  ; Pointer to the file name
    mov ecx, 0x42                ; File access mode 
    mov edx, 777
    int 0x80                  ; Call kernel


    ; Check if the file was opened successfully
    cmp eax, -1
    je  exit_program
    mov dword [out_file_descriptor], eax
    
    mov ebp, 0
    add esi, 1
    pop ecx
    mov dword [esi*4 + esp -4], ecx
    jmp print_args_loop

;=================printing arguments====================
print_string_loop:    
    ; Load current character
    mov al, [ecx]
    cmp al, 0
    je print_newline
    push eax            ; Save eax
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov edx, 1          ; buffer size
    int 0x80            ; Call kernel
    pop eax             ; Restore eax
    add ecx, 1          ; Move to the next character
    jmp print_string_loop

print_newline:
    ; Print a newline character
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    lea ecx, [newline]  ; buffer
    mov edx, 1          ; buffer size
    int 0x80            ; Call kernel

    ; Move to the next argument
    mov ebp, 0
    add esi, 1
    mov dword [esi*4 + esp -4], ecx
    jmp print_args_loop
;=================encode===========================    
encode:
;==================read============================
    read:
        nullify_buffer:
            lea esi, [buffer] ; Load the buffer address into esi
            mov edi, 256      ; Set the counter to the buffer size (256 bytes)

        nullify_loop:
            dec edi           ; Decrement the counter
            cmp edi, 0        ; Check if the counter is zero
            jl done           ; If counter < 0, jump to done
            mov byte [esi], 0 ; Set the current byte to zero
            add esi, 1        ; Move to the next byte
            jmp nullify_loop  ; Repeat the loop    
        
         done: 
            xor edi, edi
            xor esi, esi  
         
        mov eax, 3              ; sys read
        mov ebx, [in_file_descriptor]             ; stdin file 
        mov ecx, buffer         ; buffer
        mov edx, 256            ; how many to read
        int 0x80
;================increce=================================
    increment_chars:        
        mov edi, eax        ; Save the number of bytes read into edi
        lea esi, [buffer]   ; Load the address of the buffer into esi
        mov edx, edi
    increment_loop:
        dec edi             ; Decrement the byte counter
        cmp edi, 0
        jl print_output     ; If counter < 0, jump to print_output
        mov al, [esi]       ; Load the current character into al

        ; Check if the character is in the range 'A' to 'z'
        cmp al, 'A'
        jl next_char
        cmp al, 'z'
        jg next_char

        ; Increment the character
        add al, 1

        
    update_char:
        mov [esi], al       ; Store the updated character back in the buffer

    next_char:
        add esi, 1          ; Move to the next character
        jmp increment_loop

;===================print=============================
    print_output:
        ; Prepare for sys_write system call
        mov eax, 4          ; sys_write
        mov ebx, [out_file_descriptor]          ; stdout
        lea ecx, [buffer]  ; buffer
        ;mov edx, edi       ; buffer size (number of bytes read) 
        int 0x80            ; Call kernel
        jmp read

exit_program:
    mov ebx, 0
    mov eax, 1
    int 0x80
