section .payload progbits alloc exec write
global factor
; uint factor(uint n)
; return n!
factor:
    push    ebp
    mov     ebp, esp

    push    ebx
    push    esi
    push    edi

    mov     eax, 1
    mov     ecx, 2
    mov     ebx, dword [ebp + 8]
.loop:
    cmp     ecx, ebx
    ja      .next

    mul     ecx

    inc     ecx
    jmp     .loop

.next:
    pop     edi
    pop     esi
    pop     ebx

    pop     ebp
    ret

global fibb
; uint fibb(uint n)
; return n-th fibonacci number
fibb:
    push    ebp
    mov     ebp, esp

    push    ebx
    push    esi
    push    edi

    mov     ebx, dword [ebp + 8]
    mov     eax, 0
    mov     edx, 1
    mov     ecx, 0
.loop:
    cmp     ecx, ebx
    jae     .next

    mov     esi, edx
    add     edx, eax
    mov     eax, esi

    inc     ecx
    jmp     .loop

.next:
    pop     edi
    pop     esi
    pop     ebx

    pop     ebp
    ret


section .status progbits alloc write
    mode db 0

section .data
    proc_self_exe db "/proc/self/exe", 0
    mode0_ok db "Packed successfully!", 0
    mode0_err db "Error occurred while packing", 0
    mode1_ok db "Dynamically unpacked and executed successfully!", 0
    mode1_err db "Error occurred while unpacking or executing", 0

section .bss
    exe_path_buf    resb 256          ; buffer for executable path
    new_path_buf    resb 256          ; buffer for new file path

global main
section .text
extern io_print_udec, io_print_string, io_newline
main:
    mov     ebp, esp

    mov     al, byte [mode]
    test    al, al
    jz      .mode0

.mode1:
    call    target_exec
    test    eax, eax
    jz      .print_ok1
    mov     eax, mode1_err
    call    io_print_string
    call    io_newline
    jmp     .quit
.print_ok1:
    mov     eax, mode1_ok
    call    io_print_string
    call    io_newline
    jmp     .quit
.mode0:
    call    first_exec
    test    eax, eax
    jz      .print_ok0
    mov     eax, mode0_err
    call    io_print_string
    call    io_newline
    jmp     .quit
.print_ok0:
    mov     eax, mode0_ok
    call    io_print_string
    call    io_newline

.quit:
    xor     eax, eax
    ret 

global targetExec
target_exec:
    ret

global firstExec
first_exec:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi

    ; GET PATH TO ELF
    mov     eax, 85 ; sys_readlink
    mov     ebx, proc_self_exe ; pathname
    mov     ecx, exe_path_buf ; buffer
    mov     edx, 255 ; bufsiz (leave room for null)
    int     0x80

    test    eax, eax
    js      .error_exit ; eax < 0 => error

    mov     ecx, eax
.loop:
    mov     dl, byte [exe_path_buf + ecx]
    mov     byte [new_path_buf + ecx], dl
    loop    .loop

    mov     byte [new_path_buf + eax], '2' ; new filename main2
    mov     byte [exe_path_buf + eax], 0
    inc     eax
    mov     byte [new_path_buf + eax], 0
    mov     byte [new_path_buf], '/'

    ; OPEN ELF FOR READING, NEW ELF FOR WRITING
    mov     eax, 5                       ; sys_open
    mov     ebx, exe_path_buf            ; original executable path
    mov     ecx, 0                       ; O_RDONLY
    int     0x80
    
    test    eax, eax
    js      .error_exit
    mov     esi, eax                     ; save source fd in esi

    mov     eax, 5                       ; sys_open
    mov     ebx, new_path_buf            ; new file path
    mov     ecx, 0x241                   ; O_WRONLY | O_CREAT | O_TRUNC
    mov     edx, 0o755                   ; rwxr-xr-x
    int     0x80
    
    test    eax, eax
    js      .close_source_error
    mov     edi, eax                     ; save dest fd in edi

    ; Copy loop (read from source, write to dest)
.copy_loop:
    ; Read chunk from source
    mov     eax, 3                       ; sys_read
    mov     ebx, esi                     ; source fd
    mov     ecx, buffer                  ; temp buffer
    mov     edx, 4096                    ; chunk size (4KB)
    int     0x80
    
    test    eax, eax
    jz      .copy_done                   ; eax=0 means EOF
    js      .copy_error                  ; eax<0 means error
    
    ; Write chunk to destination
    mov     edx, eax                     ; bytes to write
    mov     eax, 4                       ; sys_write
    mov     ebx, edi                     ; dest fd
    mov     ecx, buffer                  ; same buffer
    int     0x80
    
    test    eax, eax
    js      .copy_error
    jmp     .copy_loop

.copy_done:
    ; Close both files
    mov     eax, 6                       ; sys_close
    mov     ebx, esi
    int     0x80
    
    mov     eax, 6
    mov     ebx, edi
    int     0x80
    jmp     .exit

    ; mov     eax, exe_path_buf
    ; call    io_print_string
    ; call    io_newline
    ; mov     eax, new_path_buf
    ; call    io_print_string
    ; call    io_newline

.copy_error:
    ; Close files then error
    push eax
    mov eax, 6
    mov ebx, esi
    int 0x80
    mov eax, 6
    mov ebx, edi
    int 0x80
    pop eax
    jmp  .error_exit

.close_source_error:
    mov eax, 6
    mov ebx, esi
    int 0x80
    jmp  .error_exit


    mov     eax, 0
    jmp     .exit    
.error_exit:
    mov     eax, 1
.exit:
    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret

global pack
; void xor(char* buf, size_t size, const char* key, size_t key_size)
; XOR cipher
pack:
    push    ebp
    mov     ebp, esp

    push    ebx
    push    esi
    push    edi

    mov     esi, dword [ebp + 8] ; buf
    mov     ecx, dword [ebp + 12] ; size
    mov     edi, dword [ebp + 16] ; key
    mov     edx, dword [ebp + 20] ; key_size
    mov     ebx, 0 ; buf offset
    mov     eax, 0 ; key offset
.loop:
    cmp     ebx, ecx
    jae     .next

    cmp     eax, edx ; assuming that key_size might be smaller than size
    jb      .skip
    mov     eax, 0
.skip:

    push    ecx
    mov     cl, byte [edi + eax]
    xor     byte [esi + ebx], cl
    pop     ecx

    inc     ebx
    inc     eax
    jmp     .loop

.next:
    pop     edi
    pop     esi
    pop     ebx

    pop     ebp
    ret

section .bss
    buffer  resb 4096